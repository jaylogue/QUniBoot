#!/bin/sh
#
# Run deferred init scripts
#

case "$1" in
  start)
    # Run deferred start scripts in a background process...
    (
        # Give init a chance to finish any remaining non-deferred 
        # scripts and spawn shells
        sleep 0.01

        # Run all deferred init scripts in /etc/init.d in numerical order.
        for i in /etc/init.d/D[0-9][0-9]* ;do

            # Ignore dangling symlinks (if any).
            [ ! -f "$i" ] && continue

            case "$i" in
            *.sh)
                # Source shell script for speed.
                (
                    trap - INT QUIT TSTP
                    set start
                    . $i
                )
                ;;
            *)
                # No sh extension, so fork subprocess.
                $i start
                ;;
            esac
        done
    )&
    exit 0
    ;;

  stop)

    # Run all deferred stop scripts in /etc/init.d synchronously in reverse
    # numerical order.
    for i in $(ls -r /etc/init.d/D[0-9][0-9]*) ;do

        # Ignore dangling symlinks (if any).
        [ ! -f "$i" ] && continue

        case "$i" in
        *.sh)
            # Source shell script for speed.
            (
            trap - INT QUIT TSTP
            set stop
            . $i
            )
            ;;
        *)
            # No sh extension, so fork subprocess.
            $i stop
            ;;
        esac
    done
    exit 0
    ;;

  restart)
    # Nothing to do
    exit 0
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac
