#!/bin/bash
#
# Shutdown button monitor for UniBone/QBone
#

set -u
shopt -s nullglob

log() {
    echo >&2 "$*"
}

log_error() {
    echo >&2 "ERROR: $*"
}

error_exit() {
    log_error "$@"
    exit 1
}

declare -r LEDS=(
  "/sys/class/leds/qunibone:led0"
  "/sys/class/leds/qunibone:led1"
  "/sys/class/leds/qunibone:led2"
  "/sys/class/leds/qunibone:led3"
)

set_leds() {
    for LED in ${LEDS[@]}; do
        echo "$1" >> ${LED}/brightness
    done
}

flash_leds() {
    local count=$1 i=0
    while true; do
        set_leds 1
        sleep 0.25
        set_leds 0
        (( i++ ))
        if [[ ${i} -ge ${count} ]]; then
            break
        fi
        sleep 0.25
    done
}

# Find an input event device by name
find_evdev_by_name() {
    local name=$1
    local ev

    for ev in $(shopt -s nullglob; echo /sys/class/input/event*); do
        if [[ "$(<${ev}/device/name)" = "${name}" ]]; then
            echo "/dev/input/${ev##/sys/class/input/}"
            return 0
        fi
    done
    return 1
}

# Process button events received from evtest on stdin
process_button_events() {
    local key_name=$1 event_line up_time timeout_arg
    local -i hold_time=$2 button_state cur_time hold_end_time read_timeout read_res

    button_state=0
    timeout_arg=

    # Process output from evtest...
    while true; do

        # Wait for a line of output from evtest
        # Exit with an error if read returns something other than success or a timeout
        read_res=0
        IFS= read ${timeout_arg} event_line || read_res=$?
        [[ ${read_res} -eq 0 || ${read_res} -ge 128 ]] || error_exit "Failed reading events from evtest"

        # Get monotonic time in 1/100ths of a second
        read -r up_time _ </proc/uptime || error_exit "Unable to read /proc/uptime"
        cur_time=${up_time/./}

        # If line was received from evtest...
        if [[ ${read_res} -eq 0 ]]; then

            # log "event_line is ${event_line}"

            # Parse the line; if it is a state change event for the target button ...
            if [[ "${event_line}" =~ ^"Event: time "[0-9.]+", type 1 (EV_KEY), code "[0-9]+" (${key_name}), value "([01])$ ]]; then

                # log "event_line match: ${BASH_REMATCH[0]}"

                # Extract the new button state
                button_state=${BASH_REMATCH[1]}

                # If the event is a button down (value = 1), compute the time at which
                # the hold duration will expire.
                if [[ ${button_state} -eq 1 ]]; then
                    hold_end_time=$(( cur_time + hold_time ))
                fi
            fi
        fi

        # If the button is currently being held down...
        if [[ ${button_state} -gt 0 ]]; then

            # If the hold end time has been reached, exit with 0. This will signal the
            # main process that a shutdown has been requested.
            if [[ ${cur_time} -ge ${hold_end_time} ]]; then
                log "Shutdown requested (${key_name})"
                exit 0
            fi

            # Compute the remaining time until the hold end time and arrange to pass that
            # as a timeout to read.
            read_timeout=$(( hold_end_time - cur_time ))
            printf -v timeout_arg -- '-t %d.%02d' $(( read_timeout / 100 )) $(( read_timeout % 100 ))

        # Otherwise, the button is NOT currently held down, so arrange for the next read
        # to wait indefinitely
        else
            timeout_arg=
        fi

    done
}

# Start a background process to monitor for presses on a shutdown button
start_monitor() {
    local event_dev=$1 key_name=$2 hold_time=$3

    # Start evtest in a subprocess and consume its output in a second subprocess...
    (echo ${BASHPID}; exec /usr/bin/evtest ${event_dev}) | (

        # Capture the evtest pid
        IFS= read evtest_pid || error_exit "Unable to read evtest pid"

        # Arrange to kill the evtest process when this process exits
        trap "kill ${evtest_pid} 2>/dev/null" EXIT

        log "Button monitor starting (evtest pid ${evtest_pid}, dev ${event_dev}, key ${key_name}, hold dur ${hold_time})"

        # Read and process button events from evtest
        process_button_events "${key_name}" ${hold_time}

    ) &
    MONITOR_PIDS+=( $! )
}

# Kill all active button monitor processes
kill_monitors() {
    if [[ ${#MONITOR_PIDS[@]} -gt 0 ]]; then
        log "Terminating monitor processes: ${MONITOR_PIDS[@]}"
        kill -- "${MONITOR_PIDS[@]}" 2>/dev/null
        MONITOR_PIDS=()
    fi
}

usage() {
    cat >&2 <<EOF
Usage: ${0##*/} [<options>...]

Options:
  --hold-time N   How long the UniBone/QBone input button must be held to
                  initiate a shutdown, in milliseconds (default: 3000)
  --syslog        Send log output to the system log instead of standard error
  --help          Print this message
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --hold-time)
                [[ $# -ge 2 ]] || error_exit "--hold-time requires a value"
                # Accept a positive decimal integer of up to 9 digits. Force base 10 so that a
                # leading zero is not interpreted as octal.
                [[ "$2" =~ ^[0-9]{1,9}$ && $(( 10#$2 )) -gt 0 ]] || error_exit "Invalid --hold-time value: $2"
                # Convert ms to 1/100th of a second, rounding up
                INPUT_BUTTON_HOLD_TIME=$(( ((10#$2) + 9) / 10 ))
                shift 2
                ;;
            --syslog)
                USE_SYSLOG=1
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                error_exit "Unrecognized argument: $1"
                ;;
        esac
    done
}

# ---------- Main Code --------------------------------------------------

USE_SYSLOG=0
INPUT_BUTTON_HOLD_TIME=300
MONITOR_PIDS=()

# Parse and validate the command line
parse_args "$@"

# Log to syslog if requested
if [[ ${USE_SYSLOG} -ne 0 ]]; then
    log() {
        logger -t "shutdownd[${BASHPID}]" -p daemon.info "$*"
    }

    log_error() {
        logger -t "shutdownd[${BASHPID}]" -p daemon.err "ERROR: $*"
    }

    log "Starting"
fi

# Arrange to kill any remaining monitor processes when this process exits
trap 'kill_monitors; log "Exiting"' EXIT

# Get the event devices for the BBB power button and the UniBone/QBone input button.
# Fail if either are missing.
POWER_BUTTON_DEV=$(find_evdev_by_name "tps65217_pwrbutton") || error_exit "Event device for BBB power button not found"
INPUT_BUTTON_DEV=$(find_evdev_by_name "qunibone-buttons") || error_exit "Event device for UniBone/QBone input button not found"

# Start background processes to monitor each button
start_monitor "${POWER_BUTTON_DEV}" "KEY_POWER" 0
start_monitor "${INPUT_BUTTON_DEV}" "KEY_PROG1" "${INPUT_BUTTON_HOLD_TIME}"

# Wait for a monitor process to exit and capture its exit code.
wait -n "${MONITOR_PIDS[@]}"
MONITOR_RES=$?

# If the monitor process failed, exit with an error
if [[ ${MONITOR_RES} -ne 0 ]]; then
    error_exit "Button monitor failed (exit status ${MONITOR_RES})"
fi

# Flash the leds to acknowleged the button press
flash_leds 1

# Kill the remaining monitors
kill_monitors

# initiate shutdown 
log "Initiating system shutdown"
kill -SIGUSR2 1

exit 0
