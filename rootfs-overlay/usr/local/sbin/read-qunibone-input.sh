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

# The GPIO bank to which the QUniBone's inputs are connected
QUNIBONE_INPUT_GPIO_BANK=1

# Input names to GPIO numbers map
declare -A QUNIBONE_INPUTS_MAP=(
    [sw0]="4"
    [sw1]="5"
    [sw2]="6"
    [sw3]="7"
    [button]="12"
)

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

    local gpiochip_node=( $(shopt -s nullglob; echo /sys/bus/platform/devices/"${bank_addr}".gpio/gpiochip*) )

    if [[ "${#gpiochip_node[@]}" -eq 1 && -d "${gpiochip_node[0]}" ]]; then
        echo "${gpiochip_node}"
        return 0
    else
        echo >&2 "${ERROR_PREFIX}Unable to locate gpiochip node for GPIO bank ${bank_num}"
        return 1
    fi
}

# Find the Linux /dev/gpiochip device for the specified AM335x GPIO bank.
#
# Argument is AM335x GPIO bank number (0-4)
#
# Outputs path to gpiochip device, e.g.:
#     /dev/gpiochipN
# where N is an arbitrary number assigned by the kernel
#
am335x_get_gpiochip_dev() {
    local bank_num=$1
    local gpiochip_node
    
    gpiochip_node=$(am335x_get_gpiochip ${bank_num})
    [[ -n "${gpiochip_node}" ]] || return 1

    # Extract the "gpiochipN" part of the node path and use that to
    # form the device name.
    echo "/dev/${gpiochip_node##*/}"

    return 0
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
    local gpio_num gpio_val
    declare -g QUNIBONE_INPUT_DEV

    # Lookup the gpio number corresponding to the input name
    [[ -v QUNIBONE_INPUTS_MAP[${input_name}] ]] || {
        echo >&2 "${ERROR_PREFIX}Invalid input name: ${input_name}"
        return 1
    }
    gpio_num=${QUNIBONE_INPUTS_MAP[${input_name}]}

    # Get and cache the device associated with the QUniBone's input GPIO bank (gpio1)
    if [[ -z "${QUNIBONE_INPUT_DEV:-}" ]]; then
        QUNIBONE_INPUT_DEV=$(am335x_get_gpiochip_dev ${QUNIBONE_INPUT_GPIO_BANK})
        [[ -n "${QUNIBONE_INPUT_DEV}" ]] || return 1
    fi

    # Fetch and print the current value of the input
    gpioget --chip "${QUNIBONE_INPUT_DEV}" --numeric "${gpio_num}"
}

# Read and print the current states of a set of QUniBone inputs
#
# Arguments are zero or more input names and/or special names:
#    allsw - all switch states as bit field
#    all   - all inputs states as bit field (switches and button)
#
# Output is the states of each specified input:
#    1 = on/active
#    0 = off/inactive
#
qunibone_read_inputs() {
    local input_name val
    local -a vals=()

    # For each input name given...
    for input_name in $*; do

        unset val
        case ${input_name@L} in
            allsw)
                val=$(__as_bits $(qunibone_read_inputs sw0 sw1 sw2 sw3))
                ;;
            all)
                val=$(__as_bits $(qunibone_read_inputs sw0 sw1 sw2 sw3 button))
                ;;
            *)
                # Lookup the gpio number corresponding to the input name
                [[ -v QUNIBONE_INPUTS_MAP[${input_name}] ]] || {
                    echo >&2 "${ERROR_PREFIX}Invalid input name: ${input_name}"
                    return 1
                }
                # read the current value of the input
                val=$(qunibone_read_input ${input_name})
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

    for val in $@; do
        (( sum = sum + (val * m) ))
        (( m = m * 2 ))
    done

    echo ${sum}

    return 0
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

    SCRIPT_NAME="${BASH_SOURCE##*/}"
    ERROR_PREFIX="${SCRIPT_NAME%.sh}: "

    [[ $# -gt 0 ]] || {
        echo >&2 "${ERROR_PREFIX}Please specify one or more input names"
        echo >&2
        echo >&2 "Usage: ${SCRIPT_NAME} <input>..."
        echo >&2
        echo >&2 "where <input> is:"
        echo >&2 "  sw0..sw3 -- Individual switch state"
        echo >&2 "  button   -- Button state"
        echo >&2 "  allsw    -- All switch states as bit field (sw0=bit0, sw1=bit1, ...)"
        echo >&2 "  all      -- All input states as bit field (sw0=bit0, sw1=bit1, ..., button=bit4)"
        echo >&2
        echo >&2 "Output is:"
        echo >&2 "  1        -- Input is on/active"
        echo >&2 "  0        -- Input is off/inactive"
        echo >&2
        exit 1
    }

    # Read and print the current state of each input listed on the command line
    qunibone_read_inputs "$@"

fi
