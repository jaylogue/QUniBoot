# QBone button shutdown

Hold the **long tactile switch on the QBone board** for three seconds, then
release it. QUniBoot requests normal Linux poweroff. Short presses are ignored.
Wait for shutdown to finish and the BeagleBone power LED to go out before
removing power. The short tactile switch is reset; the BeagleBone's own power
button is a different control and is not monitored by this service.

This shuts down the BeagleBone host. It does not shut down an operating system
running on the attached PDP-11 or VAX. Shut that system down first if it is using
emulated disks.

## Wiring and integration

The QBone GPIO button is active high on **GPIO1_12, BBB header P8 pin 12**.
The [QUniBone source](https://github.com/QUniBone/QUniBoneClassic/blob/master/10.01_base/2_src/arm/gpios.cpp)
maps BUTTON to bank 1, offset 12. The existing QUniBoot helper
`/usr/local/sbin/read-qunibone-input.sh button` reads this same input and discovers
its GPIO controller by hardware address, avoiding changing Linux GPIO numbers.
The BeagleBone header mapping is in the
[board documentation](https://docs.beagleboard.org/boards/beaglebone/black/ch07.html).

`/etc/init.d/S29shutdownbutton` starts a Python monitor in the background.
Python and the helper's libgpiod tools are already included. The monitor samples
using the helper with a 100 ms pause between reads. Three seconds of consecutive
pressed readings requests shutdown once. Brief changes between samples cannot
be detected. A released sample resets the timer, and a read failure or sample
gap longer than 500 ms requires a fresh release and press. A button already held
at startup must also be released first. This favours missing a hold over shutting
down on uncertain input. Timing uses the monotonic clock, unaffected by NTP.

The helper briefly requests only the button line as an input for each read;
no GPIO output, PMIC register, or pinmux changes are made by the monitor.
Missing/busy inputs are retried without blocking boot. Failures go to syslog.
A lock prevents duplicate monitors, and a shutdown request stays latched until
service restart, including if the poweroff command fails.

The monitor calls `/sbin/poweroff` without `-f`. BusyBox syncs and signals init,
which invokes `/etc/init.d/rcK`. The existing `S30autostart.sh stop` action closes
the QUniBone screen session before filesystems are unmounted. That action already
tolerates an absent session. No startup, SSH profile, DIP-switch or application
launch settings are changed.

Closing screen uses the existing application's terminal-hangup behaviour; this
change does not add application-level storage cleanup or guest OS shutdown.
Hardware validation must include the emulator's termination and the complete
Linux shutdown sequence on the serial console.

The rootfs overlay installs both new files in rebuilt images. Build as described
in [BUILDING.md](BUILDING.md). For an existing image, copy the two files to their
matching paths and set their permissions to 0755.

## Tests on the BeagleBone

Run as root. First test without requesting shutdown:

```sh
/etc/init.d/S29shutdownbutton stop
python3 /usr/local/sbin/shutdown-button.py --dry-run
```

Briefly press and release the long QBone tactile switch. Expect press/release
messages and continued operation. Wait two seconds, then hold for about four
seconds and release. Expect one hold-detected message and the test to exit.

Enable normal operation:

```sh
/etc/init.d/S29shutdownbutton start
cat /run/shutdown-button.pid
ps -ef | grep '[s]hutdown-button.py'
grep shutdown-button /var/log/messages
```

Calling start twice should leave one monitor. Calling stop twice should succeed.
Start it again before testing poweroff. Shut down any attached guest OS first,
then watch the BeagleBone serial console. A short press must leave QUniBone and
SSH running. A four-second press should initiate shutdown once. Confirm the
QUniBone session exits, filesystems unmount, Linux reports poweroff, and the power
LED goes out. An SSH disconnect alone does not prove clean shutdown.

Power back up and confirm the monitor starts automatically. Repeat with the
emulator session absent (only after shutting down any attached guest OS):

```sh
/etc/init.d/S30autostart.sh stop
screen -ls
```

A four-second button hold should still shut down normally. Power back up and
check normal operation. Automated tests on Linux never perform real shutdown:

```sh
python3 -m unittest discover -s tests -v
```

To disable across boots on an existing image:

```sh
/etc/init.d/S29shutdownbutton stop
mv /etc/init.d/S29shutdownbutton /etc/init.d/DISABLED.S29shutdownbutton
```

## Validation recorded

Tested on a QBone with QUniBoot v1.2, Linux 6.6.58 PREEMPT_RT and libgpiod 2.2:

- The long tactile switch read 0 when released and 1 when pressed.
- A dry run ignored a short press and detected a long press after three seconds.
- Duplicate starts left one monitor; repeated stops succeeded.
- The operator reported apparent poweroff after a real long press. SSH became
  unreachable, and after power-up the monitor started automatically.
- The subsequent kernel boot log reported no filesystem recovery or EXT4 errors.
- All ten automated tests passed on the BeagleBone.

The shutdown serial-console sequence was not captured, so application cleanup
and final unmount completion were not directly observed. A physical shutdown
with the emulator already absent and a complete rebuilt-image test remain to be
performed. Installation for these tests used the overlay files on an existing
image.
