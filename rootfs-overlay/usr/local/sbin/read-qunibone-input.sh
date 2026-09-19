#!/usr/bin/env bash
#
# Reads the state of QUniBone inputs (switches and button)
#

# AM335X GPIO bank addresses, ordered by bank number (0..3)
AM335X_GPIO_BANK_ADDRS=(
    44e07000
    4804c000
    481ac000
    481ae000
)

# The GPIO bank to which the QUniBone's switches are connected
QUNIBONE_SW_GPIO_BANK=1

# Switch names to GPIO numbers map
declare -A QUNIBONE_SW_MAP=(
    [sw0]="4"
    [sw1]="5"
    [sw2]="6"
    [sw3]="7"
)

log_error() {
    echo >&2 "${ERROR_PREFIX:-}$*"
}

# Find the Linux gpiochip device tree node for specified the
# AM335x GPIO bank.
#
# Argument is AM335x GPIO bank number (0-3)
#
# Outputs the full path to the corresponding gpiochip device tree node, e.g.:
#     /sys/bus/platform/devices/<gpio-bank-addr>/gpiochipN
# where N is an arbitrary number assigned by the kernel
#
am335x_get_gpiochip() {
    local bank_num=$1
    local bank_addr=${AM335X_GPIO_BANK_ADDRS[${bank_num}]}
    local gpiochip_node

    gpiochip_node=( $(shopt -s nullglob; echo /sys/bus/platform/devices/"${bank_addr}".gpio/gpiochip*) )

    [[ "${#gpiochip_node[@]}" -eq 1 && -d "${gpiochip_node[0]}" ]] || return 1

    echo "${gpiochip_node[0]}"
    return 0
}

# Find the Linux /dev/gpiochip device for the specified AM335x GPIO bank.
#
# Argument is AM335x GPIO bank number (0-3)
#
# Outputs path to gpiochip device, e.g.:
#     /dev/gpiochipN
# where N is an arbitrary number assigned by the kernel
#
am335x_get_gpiochip_dev() {
    local bank_num=$1
    local gpiochip_node gpiochip_dev
    
    gpiochip_node=$(am335x_get_gpiochip ${bank_num}) || return 1

    # Extract the "gpiochipN" part of the node path and use that to
    # form the device name.
    gpiochip_dev="/dev/${gpiochip_node##*/}"

    # Make sure the device exists
    [[ -c "${gpiochip_dev}" ]] || return 1

    echo "${gpiochip_dev}"
    return 0
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

# Read and print the current state of a QUniBone input
#
# Argument is an input name
#
# Output is the state of the specified input:
#    1   - on/active
#    0   - off/inactive
#
qunibone_read_input() {
    local input_name=$1
    local gpio_num ev_dev cmd_res=0
    declare -g QUNIBONE_SW_DEV

    if [[ "${input_name}" = "button" ]]; then

        # Find the "qunibone-buttons" input event device
        ev_dev=$(find_evdev_by_name "qunibone-buttons") || {
            log_error "Unable to locate event device for UniBone/QBone input button"
            return 1
        }

        # query and print the current state of the QUniBone input button
        evtest --query ${ev_dev} EV_KEY KEY_PROG1 || cmd_res=$?
        case ${cmd_res} in
            0)  echo 0; return 0 ;;
            10) echo 1; return 0 ;;
            *)  log_error "Unable to read input button device (exit code ${cmd_res})"; return 1 ;;
        esac

    else

        # Lookup the gpio number corresponding to the switch name
        [[ -v QUNIBONE_SW_MAP[${input_name}] ]] || {
            log_error "Invalid input name: ${input_name}"
            return 1
        }
        gpio_num=${QUNIBONE_SW_MAP[${input_name}]}

        # Get the device associated with the QUniBone's switch GPIO bank (gpio1)
        if [[ -z "${QUNIBONE_SW_DEV:-}" ]]; then
            QUNIBONE_SW_DEV=$(am335x_get_gpiochip_dev ${QUNIBONE_SW_GPIO_BANK}) || {
                log_error "Unable to locate gpiochip device for GPIO bank ${QUNIBONE_SW_GPIO_BANK}"
                return 1
            }
        fi

        # Fetch and print the current value of the switch
        gpioget --chip "${QUNIBONE_SW_DEV}" --numeric "${gpio_num}" || cmd_res=$?
        [[ ${cmd_res} -eq 0 ]] || {
            log_error "Unable to read switch gpio device (exit code ${cmd_res})"
            return 1
        }
    fi
}

# Read and print the current states of a set of QUniBone inputs
#
# Arguments are zero or more input names and/or special names:
#    sw0..sw3  - switch state
#    button    - input button state
#    allsw     - all switch states as a bit field
#    all       - all inputs states as a bit field (switches and button)
#
# Output is the states of each specified input:
#    1 = on/pressed
#    0 = off/not-pressed
#
qunibone_read_inputs() {
    local input_name val
    local -a vals=()

    # Pre-cache the device associated with the QUniBone's switch GPIO bank (gpio1)
    # Ignore any failure in case all the user wants to read is the button
    if [[ -z "${QUNIBONE_SW_DEV:-}" ]]; then
        QUNIBONE_SW_DEV=$(am335x_get_gpiochip_dev ${QUNIBONE_SW_GPIO_BANK}) || true
    fi

    # For each input name given...
    for input_name in "$@"; do

        unset val
        case ${input_name@L} in
            sw0|sw1|sw2|sw3|button)
                val=$(qunibone_read_input ${input_name@L})
                ;;
            allsw)
                val=$(__as_bits $(qunibone_read_inputs sw0 sw1 sw2 sw3))
                ;;
            all)
                val=$(__as_bits $(qunibone_read_inputs sw0 sw1 sw2 sw3 button))
                ;;
            *)
                log_error "Invalid input name: ${input_name}"
                return 1
                ;;
        esac
        [[ -n "${val:-}" ]] || return 1

        # Append the value to the list
        vals+=( "${val}" )

    done

    # Output the final list of values
    echo "${vals[@]}"

    return 0
}

__as_bits() {
    local -i val m=1 sum=0

    [[ $# -gt 0 ]] || return 1

    for val in "$@"; do
        sum=$(( sum + (val * m) ))
        m=$(( m * 2 ))
    done

    echo ${sum}

    return 0
}

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [<options>...] <input>...

Inputs:
  sw0..sw3    Individual switch state
  button      Button state
  allsw       All switch states as bit field (sw0=bit0, sw1=bit1, ...)
  all         All input states as bit field (sw0=bit0, sw1=bit1, ..., button=bit4)

Options:
  -h,--help   Print this message

Outputs:
  1           Input is on/active
  0           Input is off/inactive

EOF
}

parse_args() {
    local input_name

    INPUTS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)  usage; exit 0 ;;
            --)         shift; break ;;
            -*)         log_error "Unrecognized argument: $1"; exit 1 ;;
            *)          INPUTS+=( "$1" ); shift ;;
        esac
    done

    INPUTS+=( "$@" )

    [[ ${#INPUTS[@]} -gt 0 ]] || {
        log_error "Please specify one or more input names"
        exit 1
    }

    for input_name in "${INPUTS[@]}"; do
        case "${input_name@L}" in
            sw0|sw1|sw2|sw3|button|all|allsw)
                ;;
            *)
                log_error "Invalid input name: ${input_name}"
                exit 1
                ;;
        esac
    done
}


# ========== Main Code ==================================================

# Only take action if this script is being run directly, rather than
# being sourced by another script.
#
# This allows other scripts to source this script to get access to its
# functions.
#
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    set -eu
    shopt -s inherit_errexit

    SCRIPT_NAME="${BASH_SOURCE##*/}"

    ERROR_PREFIX="${SCRIPT_NAME}: "
    parse_args "$@"

    ERROR_PREFIX="${SCRIPT_NAME}: ERROR: "

    # Read and print the current state of each input listed on the command line
    qunibone_read_inputs "${INPUTS[@]}"
fi
