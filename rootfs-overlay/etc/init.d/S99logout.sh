#!/bin/sh

case "$1" in
    start|restart)
        # nothing to do
        exit 0
        ;;
    stop)
        echo "Logging out users"
        # Logout all users except for the console user
        who | awk '/console/{next};{print $2}' | xargs -I{} pkill -HUP -t {}
        exit 0
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac
