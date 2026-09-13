"""Run on Linux: python3 -m unittest discover -s tests -v"""
import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

source = Path(__file__).resolve().parents[1] / 'rootfs-overlay/usr/local/sbin/shutdown-button.py'
spec = importlib.util.spec_from_file_location('shutdown_button', source)
button = importlib.util.module_from_spec(spec)
spec.loader.exec_module(button)


def samples(hold, down, start, count):
    return [hold.sample(down, start + i * 0.1) for i in range(count)]


class HoldTests(unittest.TestCase):
    def test_short_presses_do_not_accumulate(self):
        hold = button.Hold()
        hold.sample(False, 0)
        self.assertFalse(any(samples(hold, True, 0.1, 20)))
        hold.sample(False, 2.1)
        self.assertFalse(any(samples(hold, True, 2.2, 20)))

    def test_continuous_hold_triggers_once(self):
        hold = button.Hold()
        hold.sample(False, 0)
        result = samples(hold, True, 0.1, 100)
        self.assertEqual(sum(result), 1)
        self.assertFalse(any(result[:30]))
        hold.sample(False, 10.1)
        self.assertFalse(any(samples(hold, True, 10.2, 40)))

    def test_startup_held_requires_release(self):
        hold = button.Hold()
        self.assertFalse(any(samples(hold, True, 0, 50)))
        hold.sample(False, 5)
        self.assertEqual(sum(samples(hold, True, 5.1, 40)), 1)

    def test_slow_or_missing_samples_cancel_hold(self):
        hold = button.Hold()
        hold.sample(False, 0)
        samples(hold, True, 0.1, 20)
        self.assertFalse(hold.sample(True, 10))
        self.assertFalse(any(samples(hold, True, 10.1, 40)))
        hold.sample(False, 14.1)
        self.assertEqual(sum(samples(hold, True, 14.2, 40)), 1)

    def test_bounce_restarts_hold(self):
        hold = button.Hold()
        hold.sample(False, 0)
        samples(hold, True, 0.1, 29)
        hold.sample(False, 3)
        self.assertFalse(any(samples(hold, True, 3.1, 29)))


class StopTest(Exception):
    pass


class MonitorTests(unittest.TestCase):
    def test_input_uses_existing_helper(self):
        with patch.object(button.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '1\n')) as run:
            self.assertTrue(button.read_button())
            run.assert_called_once_with([button.INPUT_HELPER, 'button'], check=True,
                                        capture_output=True, text=True, timeout=1)

    def test_invalid_read_is_rejected(self):
        with patch.object(button.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '')):
            with self.assertRaises(ValueError):
                button.read_button()

    def test_dry_run_does_not_poweroff(self):
        with patch.object(button, 'read_button', side_effect=[False] + [True] * 40), \
             patch.object(button.time, 'monotonic', side_effect=[i * 0.1 for i in range(41)]), \
             patch.object(button.time, 'sleep'), patch.object(button, 'log'), \
             patch.object(button, 'request_shutdown') as shutdown:
            button.monitor(True)
            shutdown.assert_not_called()

    def test_read_error_cancels_hold(self):
        with patch.object(button, 'read_button', side_effect=[False] + [True] * 20 + [OSError('lost input')] + [True] * 40 + [StopTest()]), \
             patch.object(button.time, 'monotonic', side_effect=[i * 0.1 for i in range(100)]), \
             patch.object(button.time, 'sleep'), patch.object(button, 'log'), \
             patch.object(button, 'request_shutdown') as shutdown:
            with self.assertRaises(StopTest):
                button.monitor(False)
            shutdown.assert_not_called()

    def test_normal_poweroff_is_not_forced_and_failure_is_latched(self):
        with patch.object(button.subprocess, 'run', side_effect=OSError('failed')) as run, \
             patch.object(button, 'log'), \
             patch.object(button.signal, 'pause', side_effect=StopTest()):
            with self.assertRaises(StopTest):
                button.request_shutdown()
            run.assert_called_once_with(['/sbin/poweroff'], check=True, timeout=10)


if __name__ == '__main__':
    unittest.main()
