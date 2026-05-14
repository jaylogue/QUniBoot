#!/bin/sh

case "$1" in
    start)
        echo -n "Starting ntpd: "
        start-stop-daemon --start --quiet --exec /usr/sbin/ntpd
        status=$?
        if [ $status -eq 0 ]; then
                echo "OK"
        else
                echo "FAIL"
        fi
        exit $status
        ;;
    stop)
        echo -n "Stopping ntpd: "
        start-stop-daemon --stop --quiet -o --exec /usr/sbin/ntpd
        status=$?
        if [ $status -eq 0 ]; then
                echo "OK"
        else
                echo "FAIL"
        fi
        exit $status
        ;;
    restart)
        $0 stop
        $0 start
        exit 0
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac
