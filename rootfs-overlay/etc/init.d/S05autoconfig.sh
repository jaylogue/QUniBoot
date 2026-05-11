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
LED_GPIOS=(32 33 34 35)

config_leds() {
  for GPIO_NUM in ${LED_GPIOS[@]}; do
    if [[ ! -d /sys/class/gpio/gpio${GPIO_NUM} ]]; then
      echo ${GPIO_NUM} >> /sys/class/gpio/export
      sleep 0.001
    fi
    echo 1 >> /sys/class/gpio/gpio${GPIO_NUM}/active_low
    echo "out" >> /sys/class/gpio/gpio${GPIO_NUM}/direction
    echo 0 >> /sys/class/gpio/gpio${GPIO_NUM}/value
  done
}

set_leds() {
  for GPIO_NUM in ${LED_GPIOS[@]}; do
    echo "$1" >> /sys/class/gpio/gpio${GPIO_NUM}/value
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

# Configure the gpios for the UniBone/QBone LEDs
config_leds

# If autoconfiguration was successful, flash the LEDs 3 times.
# Otherwise, light the LEDs and leave them on.
if [[ ${AUTOCONFIG_RES} -ge 0 ]]; then
  flash_leds 3
else
  set_leds 1
fi

exit 0
