#!/bin/sh
#
# Start/stop the QUniBoot shutdown button monitor daemon
#

DAEMON_NAME=shutdownd.sh
DAEMON=/usr/local/sbin/${DAEMON_NAME}
PIDFILE=/var/run/shutdownd.pid
ARGS=--syslog

[ -f /etc/default/shutdownd ] && . /etc/default/shutdownd

case "$1" in
    start)
        echo -n "Starting shutdown monitor: "
        start-stop-daemon --start --background \
            --make-pidfile --pidfile "${PIDFILE}" --exec "${DAEMON}" -- ${ARGS}
        status=$?
        if [ $status -eq 0 ]; then
                echo "OK"
        else
                echo "FAIL"
        fi
        exit $status
        ;;
    stop)
        echo -n "Stopping shutdown monitor: "
        start-stop-daemon --stop --quiet --oknodo --pidfile "${PIDFILE}" --name "${DAEMON_NAME}"
        status=$?
        if [ $status -eq 0 ]; then
                echo "OK"
        else
                echo "FAIL"
        fi
        exit $status
        ;;

    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
