# QUniBoot

## Introduction

QUniBoot is a small Linux distribution targeting the BeagleBone Black single-board
computer running in the [UniBone](https://retrocmp.com/projects/unibone) / [QBone](https://retrocmp.com/projects/qbone)
DEC hardware emulators. It is intended to serve as a smaller and faster alternative to
the original Debian-based OS images created by Jörg Hoppe.

QUniBoot includes the original UniBone/QBone emulation software along with the full
set of PDP-11 operating system disk images and support scripts provided in the original distribution. 
In support of this, QUniBoot incorporates a modern Linux kernel, and the system
software needed to run it.

Compared to the original distribution, QUniBoot has a number of new features, as well
as a few omissions. See [Differences vs Existing UniBone/QBone Distribution](#differences-vs-existing-unibone/qbone-distribution)
for details.

## Features

- **Modern OS**: Updated Linux kernel (6.x), system utilities and user
  applications.
- **Fast boot time**: Under 8 seconds to a shell prompt (not counting the
  time needed to establish network connectivity).
- **Simple auto-configuration**: Set the hostname, IP address, SSH keys and
  root password at boot by placing a text file on the SD card.
- **Separate OS and application partitions**: The application partition
  automatically expands to fill the SD card on first boot.
- **Easy OS-only upgrades**: Replace the contents of the OS partition
  without affecting user files.

## Installed Software

The following software packages are included in the QUniBoot distribution:

- **Standard QUniBone software**: The emulator application (`demo`), PDP-11
  OS images, boot ROMs, and start scripts.
- **PDP-11 tools**:
  - **OpenSIMH**: PDP-11 simulator (with network support)
  - **MACRO11 assembler**: Modern port of traditional PDP-11 assembler
  - **pdp11monloader**: Download PDP-11 code over a serial connection
  - **xxdpdir**: Create, update and inspect XXDP (DOS-11) filesystems
  - **retro-fuse**: Create, mount and update ancient Unix filesystems
- **Networking**: ssh, Samba, curl, wget, rsync, ntp, and virtual network
  support (bridge, tun/tap).
- **Comms**: minicom, picocom.
- **Languages/dev support**: Python, Perl, GDB, gdbserver, git.

## Differences vs Existing UniBone/QBone Distribution

QUniBoot is designed as an embedded OS rather than a desktop OS. As a
result, it does not include:

- X Windows or remote desktop support
- A C/C++ compiler
- A system package manager
- systemd or udev

## Download and Installation

Prebuilt images for QUniBoot are available for download on GitHub: *(URL TBD)*.
Separate images exist for each supported hardware target (`unibone` and `qbone`).
Additionally, images come in two variants:

- **full**: OS, system files, boot files and all QUniBone software, including PDP-11
  disk images and other data files. Use this variant for a fresh install.
- **os-only**: OS, system and boot files only. Use this variant to upgrade an
  existing install (see [Upgrading](#upgrading)).

Installing QUniBoot requires a 2GB or larger micro-SD card. If a larger card is used,
QUniBoot will automatically expand to make use of all available space.

> **Warning**: Writing an image to an SD card will overwrite existing data
> on the card.

### Installing on Linux

1. Insert the SD card and identify its device name:

   ```
   lsblk
   ```

   Look for the disk entry matching the size of your SD card (e.g.
   `/dev/sdb`). Do not use a partition name (e.g. `/dev/sdb1`).

2. Write the image:

   ```
   sudo dd if=output/images/quniboot-<hardware>-<variant>.img of=/dev/sdX bs=4M status=progress oflag=direct
   ```

   Replace `/dev/sdX` with the device name found in step 1.

3. When the write finishes, eject the disk:

   ```
   sudo eject /dev/sdX
   ```

### Installing on macOS

1. Insert the SD card and identify its device name:

   ```
   diskutil list
   ```

   Look for the disk entry matching the size of your SD card (e.g.
   `/dev/disk4`).

2. Unmount the disk (this does not eject it):

   ```
   diskutil unmountDisk /dev/diskN
   ```

3. Write the image, using the raw device (`rdiskN` instead of `diskN`) for
   faster writes:

   ```
   sudo dd if=output/images/quniboot-<hardware>-<variant>.img of=/dev/rdiskN bs=4m
   ```

   Replace `diskN` with the disk identifier found in step 1.

4. When the write finishes, eject the disk:

   ```
   diskutil eject /dev/diskN
   ```

### Installing on Windows

Windows has no built-in tool for writing raw disk images, so a third-party
imaging tool is required, such as
[balenaEtcher](https://etcher.balena.io/).

1. Download and install balenaEtcher, if not already installed. (You can
   also use Rufus for this.)

2. Insert the SD card.

3. Launch Etcher and select the QUniBoot image file
   (`quniboot-<hardware>-<variant>.img`) as the source.

4. Select your SD card as the target drive.

   Etcher only lists removable drives, which helps prevent accidentally
   writing to the wrong disk. Confirm the drive matches the size of your
   SD card before continuing.

5. Click **Flash** to write the image. Etcher verifies the write and
   ejects the SD card automatically when finished.

## Quick Start

1. Follow the steps in [Download and Installation](#download-and-installation)
   to write the **full** OS variant of QUniBoot to a blank SD card. Choose
   the image file for your hardware: `quniboot-unibone-full.img` or
   `quniboot-qbone-full.img`.
2. After the SD card has been written, remove it and re-insert it into your
   computer, then wait for the `BOOT` drive to appear.
3. Open the `BOOT` drive and rename the file `autoconfig-example.txt` to
   `autoconfig.txt`.
4. Edit `autoconfig.txt` with a text editor. Uncomment and fill in the
   settings appropriate to your environment.

   It is not required to provide values for every setting. Any setting left
   unset uses an appropriate default. At a minimum, set `ROOT_PASSWORD` to
   an appropriately strong password.

   If you have an SSH key, it is strongly recommended that you also set
   `ROOT_AUTHORIZED_KEY` to your public key. The value should be the
   base64-encoded public key in standard `authorized_keys` format (e.g.
   `ssh-rsa AAA...`).

   > Setting `ROOT_AUTHORIZED_KEY` disables root login using a password.
   > Once set, you must always use your private key to log in.
5. Close `autoconfig.txt` and safely eject the SD card.
6. Insert the card into the BeagleBone Black and boot the PDP-11 system.

   The system indicates a successful boot by flashing the UniBone/QBone
   LEDs three times. If an error occurs during auto-configuration, the LEDs
   light and stay on.

## Remote Login

Once QUniBoot has booted, you can log in to the system as root using SSH.

You can connect to the system using its hostname, which it advertises on the 
local network using mDNS. By default, the system hostname is either `unibone`
or `qbone`, unless overridden via the `HOSTNAME` auto-config setting.

If you set an SSH public key using `ROOT_AUTHORIZED_KEY`, you must supply
the corresponding private key when connecting. If you did not set an SSH key,
you can log in using the root password.

On Linux and macOS, you can use the system's ssh client to connect to the QUniBoot system:

```
ssh -i ~/.ssh/my_key root@unibone
```

On Windows, you can use PuTTY or any other suitable SSH client:

*(TBD)*

## Upgrading

The QUniBoot system can be upgraded by writing a new **os-only** image over
an existing QUniBoot SD card. The upgrade process replaces the OS and
`BOOT` partitions on the card, but leaves the partition holding the PDP-11 disk images
and script files intact.

By default, upgrading an existing QUniBoot system will reset the core operating
system settings such as the root password and the network configuration.
However, if you used the auto-configuration mechanism (`autoconfig.txt`) to
configure the system originally, you can preserve the original settings
prior to upgrading the card and re-apply them to the new system.

To upgrade a QUniBoot system:

1. If you used auto-configuration to set up the system originally, and you want to
   preserve those settings on the upgraded system, insert the SD card and save a
   copy of the `autoconfig-completed.txt` file from the `BOOT` partition to your
   local disk.
2. Follow the steps in [Download and Installation](#download-and-installation),
   selecting the appropriate **os-only** image for your hardware
   (`quniboot-unibone-os-only.img` or `quniboot-qbone-os-only.img`).
3. Before booting the upgraded SD card, copy the saved `autoconfig-completed.txt` file
   from step 1 into the `BOOT` partition on the upgraded card and rename the file
   to `autoconfig.txt`. (Note that you may need to remove and re-insert the SD card
   to get the `BOOT` partition to appear).
4. Safely eject the SD card.
5. Insert the card into the BeagleBone Black and boot the PDP-11 system.

## Documentation

*Coming soon*

## Acknowledgments

A most hearty thanks goes to Jörg Hoppe for his excellent UniBone and QBone devices.
There are many a PDP-11 (and the occasional VAX) that would be nothing without
them.

## License

All content published as part of the QUniBoot project, including source
code, patches, configuration files and documentation, is licensed under the
Apache 2.0 license.

## Authorship Notice

All source code, patches and configuration files were generated solely by
the author. Project documentation, including this README, was generated by the
author, with some inspiration, feedback and grammatical review from AI tools.
