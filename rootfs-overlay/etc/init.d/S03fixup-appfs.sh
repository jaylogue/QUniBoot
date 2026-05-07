#!/bin/sh
#
# Automatically recover and resize the app filesystem on first boot.
#

case "$1" in
  start)

    # Immediately disable this script so that it only runs once on the first
    # boot of a newly installed system.
    SCRIPT_NAME=${BASH_SOURCE[0]}
    mv ${SCRIPT_NAME} $(dirname ${SCRIPT_NAME})/DISABLED.$(basename ${SCRIPT_NAME})

    # Recover the appfs partition if it has been removed.
    /usr/local/sbin/recover-appfs.sh 2>&1 | logger -t recover-appfs

    # Resize the appfs partition and filesystem to fill the available space.
    /usr/local/sbin/resize-appfs.sh 2>&1 | logger -t resize-appfs

    ;;
 
  stop|restart|reload)
    # Nothing to do
    ;;
 
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit $?
