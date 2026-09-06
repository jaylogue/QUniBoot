:
#
# .profile for root user
#

# Set the default QBUS address width (16, 18 or 22)
# Adjust this as needed for your hardware
# (This value has no effect on UniBone)
export QBUS_ADDRESS_WIDTH=22

# Let the user know if there's a QUniBone emulation session running in the background,
# unless already running in a screen(1) session.
if [ -z "${STY}" ]; then
    QUNIBONE_SESSION_NAME=QUniBone
    if screen -ls | grep -q -E "^\s*[0-9]+\.${QUNIBONE_SESSION_NAME}\s+"; then
        echo "QUniBone emulation is running in the background. Attach with:"
        echo ""
        echo "    screen -r ${QUNIBONE_SESSION_NAME}"
        echo ""
    fi
fi
