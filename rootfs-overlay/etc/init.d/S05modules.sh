#!/bin/sh
#
# Load kernel modules.
#

case "$1" in
  start)
    # Fall through to code below
    ;;

  stop|restart|reload)
    # Nothing to do
    exit 0
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

[ -f /etc/modules ] || exit 0

while read module args; do
    case "$module" in
        ""|"#"*) continue ;;
    esac
    modprobe $module $args
done < /etc/modules
