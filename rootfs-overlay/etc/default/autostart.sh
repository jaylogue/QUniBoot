#!/usr/bin/env bash
#
# QUniBoot Auto-start Script
#
# Copy this script to "autostart.sh" in root's home directory to enable
# automatic startup of emulation at boot time based on the position of the
# UniBone/QBone switches.
#
# Customize the case statement below to change the emulation commands invoked
# for each of the possible switch settings.
#
# At boot time, this script is run in a background screen(1) session by the
# init process (see /etc/init.d/S??autostart.sh for details). You can use the
# following command to attach to the session from a root login:
#
#     screen -r QUniBone
#

# Set the default QBUS address width to 22, if not already set.
# NOTE: QBUS_ADDRESS_WIDTH should be set in /root/.profile
QBUS_ADDRESS_WIDTH="${QBUS_ADDRESS_WIDTH:-22}"

# Read the current position of the switches as a bitfield
SWITCH_VAL=$(/usr/local/sbin/read-qunibone-input.sh allsw)
[ -n "${SWITCH_VAL}" ] || {
    echo >&2 "Error reading QUniBone switches"
    exit 1
}

# Have the qunibone app light the LEDs according to the selected switch value
DEFAULT_ARGS="--leds ${SWITCH_VAL}"

# Select the appropriate command based on the switches
case ${SWITCH_VAL} in

    #
    # *** AUTO-START COMMAND TABLE ***
    #
    # Adjust these commands as desired. Up to 15 commands can be configured
    # corresponding to switch settings 1 thru 15 (0 is reserved).
    #

    0)
        AUTOSTART_DESC="disabled"
        AUTOSTART_CMD=
        ;;
    1)
        AUTOSTART_DESC="Memory emulation"
        AUTOSTART_CMD="${HOME}/memory.sh ${DEFAULT_ARGS}"
        ;;
    2)
        AUTOSTART_DESC="XXDP on RL1"
        AUTOSTART_CMD="${HOME}/xxdp2.5_dl1.sh ${DEFAULT_ARGS}"
        ;;
    3)
        AUTOSTART_DESC="RT11 5.5 single on RL1"
        AUTOSTART_CMD="${HOME}/rt11v5.5sj_dl1_34.sh ${DEFAULT_ARGS}"
        ;;
    4)
        AUTOSTART_DESC="11/34: RT11 5.5 FB on DU0:"
        AUTOSTART_CMD="${HOME}/rt11v5.5fb_du0_34.sh ${DEFAULT_ARGS}"
        ;;
    5)
        AUTOSTART_DESC="11/34: RSX11M4.8 on DU0:"
        AUTOSTART_CMD="${HOME}/rsx11m4.8_du0+rl_34.sh ${DEFAULT_ARGS}"
        ;;
    6)
        AUTOSTART_DESC="11/34: Unix V6 on RK05"
        AUTOSTART_CMD="${HOME}/unixv6_dk0_34.sh ${DEFAULT_ARGS}"
        ;;
    *)
        AUTOSTART_DESC="(no command assigned)"
        AUTOSTART_CMD=
    ;;
esac

echo "Auto-start selection: ${SWITCH_VAL} - ${AUTOSTART_DESC}"

# If a command was selected...
if [ -n $"${AUTOSTART_CMD}" ]; then

    # Launch the command and report when it completes
    echo "Running: ${AUTOSTART_CMD}"
    trap ':' INT
    ${AUTOSTART_CMD}; RES=$?
    trap - INT
    echo "Auto-start command exited (exit code ${RES})"

    # If running in a screen(1) session, pause when the command completes so that the
    # user has a chance to attach and see what happened. Offer them the choice to start
    # a shell or simply exit.
    if [ -n "${STY}" ]; then
        read -p "Press RETURN to exit, or enter 's' to start a shell: " INPUT
        if [ "${INPUT}" = "s" ]; then
            exec ${SHELL} -l
        fi
    fi 

fi
