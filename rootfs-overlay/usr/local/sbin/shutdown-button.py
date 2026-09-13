#!/usr/bin/python3
"""Request normal shutdown after a three-second hold of the QBone GPIO button."""

import argparse
import fcntl
import signal
import subprocess
import syslog
import time

HOLD_SECONDS = 3.0
POLL_SECONDS = 0.1
MAX_SAMPLE_GAP = 0.5
INPUT_HELPER = '/usr/local/sbin/read-qunibone-input.sh'


def log(message):
    syslog.syslog(syslog.LOG_NOTICE, message)
    print('shutdown-button: ' + message, flush=True)


class Hold:
    """Conservative sampled hold detector; a startup press requires release."""

    def __init__(self):
        self.armed = False
        self.since = None
        self.previous = None
        self.triggered = False

    def sample(self, down, now):
        if self.previous is not None and now - self.previous > MAX_SAMPLE_GAP:
            # A stalled reader cannot establish continuity across the gap.
            self.armed = False
            self.since = None
        self.previous = now
        if not down:
            self.armed = True
            self.since = None
        elif self.armed:
            if self.since is None:
                self.since = now
            if not self.triggered and now - self.since >= HOLD_SECONDS:
                self.triggered = True
                return True
        return False


def read_button():
    result = subprocess.run([INPUT_HELPER, 'button'], check=True,
                            capture_output=True, text=True, timeout=1)
    value = result.stdout.strip()
    if value not in ('0', '1'):
        raise ValueError('invalid button reading: ' + repr(value))
    return value == '1'


def request_shutdown():
    log('three-second hold detected; requesting normal Linux poweroff')
    # BusyBox syncs and signals init. rcK stops the existing QUniBone service
    # before unmounting filesystems. Never use -f, which bypasses that path.
    try:
        subprocess.run(['/sbin/poweroff'], check=True, timeout=10)
    except (OSError, subprocess.SubprocessError) as error:
        log('poweroff request failed: ' + str(error))
    # Do not repeat the request, even if the command failed or the button is
    # released and pressed again. An operator can restart the service to retry.
    while True:
        signal.pause()


def monitor(dry_run):
    hold = Hold()
    previous_value = None
    previous_error = None
    log('monitoring QBone GPIO button (GPIO1_12)' + (' (dry run)' if dry_run else ''))
    while True:
        try:
            down = read_button()
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            hold = Hold()
            message = str(error)
            if message != previous_error:
                log('unable to read button: ' + message)
                previous_error = message
            time.sleep(2)
            continue
        if previous_error is not None:
            log('button input available again; release before holding')
            previous_error = None
        if dry_run and down != previous_value:
            log('button ' + ('pressed' if down else 'released'))
        previous_value = down
        if hold.sample(down, time.monotonic()):
            if dry_run:
                log('three-second hold detected; dry run, no shutdown requested')
                return
            request_shutdown()
        time.sleep(POLL_SECONDS)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dry-run', action='store_true',
                        help='log one long press and exit without shutting down')
    args = parser.parse_args()
    syslog.openlog('shutdown-button', syslog.LOG_PID, syslog.LOG_DAEMON)
    with open('/run/shutdown-button.lock', 'w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            log('another monitor is already running')
            return 1
        monitor(args.dry_run)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
