#!/bin/sh
#
# Automatically start QUniBone emulation in the background when the system boots
#

SESSION_NAME=QUniBone

case "$1" in
    start)
        # If an autostart.sh file exists in root's home directory, start a background
        # screen(1) session and run the command in the session.
        # NOTE: su is used here to properly initialize root's environment before starting
        # screen(1). Without this, things like HOME are not set correctly.
        if [ -x /root/autostart.sh ]; then
            echo "Auto-starting QUniBone emulation"
            su -l root -c "/usr/bin/screen -S ${SESSION_NAME} -d -m -- /bin/bash -l -c /root/autostart.sh"
        fi
        exit 0
        ;;
    stop)
        # If a emulation session is active, signal it to quit
        if screen -ls | grep -q -E "^\s*[0-9]+\.${SESSION_NAME}\s+"; then
            echo "Exiting QUniBone emulation session"
            screen -S ${SESSION_NAME} -X quit
        fi
        exit 0
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
esac
