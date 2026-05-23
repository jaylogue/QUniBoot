#!/bin/sh
#
# Set hostname.
#

case "$1" in
  start)
    /bin/hostname -F /etc/hostname
    ;;
 
  stop|restart|reload)
    # Nothing to do
    ;;
 
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit $?
