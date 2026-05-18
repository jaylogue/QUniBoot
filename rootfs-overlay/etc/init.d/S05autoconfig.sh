#!/bin/sh
#
# Perform autoconfiguration when the system boots
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

AUTOCONFIG_FILE=/boot/autoconfig.txt

# If no autoconfig.txt is present, exit immediately
if [[ ! -f "${AUTOCONFIG_FILE}" ]]; then
  exit 0
fi

AUTOCONFIG_COMPLETED_FILE=/boot/autoconfig-completed.txt
LEDS=(
  "/sys/class/leds/qunibone:test_led0"
  "/sys/class/leds/qunibone:test_led1"
  "/sys/class/leds/qunibone:test_led2"
  "/sys/class/leds/qunibone:test_led3"
)

set_leds() {
  for LED in ${LEDS[@]}; do
    echo "$1" >> ${LED}/brightness
  done
}

flash_leds() {
  i=0
  while true; do
    set_leds 1
    sleep 0.25
    set_leds 0
    ((i++))
    if [[ $i -ge $1 ]]; then
      break
    fi
    sleep 0.25
  done
}

# Run the autoconfig.sh script to apply the configuration
/usr/local/sbin/autoconfig.sh ${AUTOCONFIG_FILE} | logger -s -t "autoconfig"
AUTOCONFIG_RES=${PIPESTATUS[0]}

# Rename the config file so that it doesn't get applied again
mv "${AUTOCONFIG_FILE}" "${AUTOCONFIG_COMPLETED_FILE}"

# If autoconfiguration was successful, flash the test LEDs in unison
# 3 times. Otherwise, light the LEDs and leave them on.
if [[ ${AUTOCONFIG_RES} -ge 0 ]]; then
  flash_leds 3
else
  set_leds 1
fi

exit 0
