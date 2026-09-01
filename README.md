# QUniBoot

QUniBoot is a small Linux distribution targeting the BeagleBone Black SBC embedded in the 
[UniBone](https://retrocmp.com/projects/unibone) and [QBone](https://retrocmp.com/projects/qbone) 
DEC hardware emulators.
QUniBoot is intended as a smaller and faster alternative to the original Debian-based OS images
created by Jörg Hoppe.

The QUniBoot system includes the original UniBone/QBone emulation software along with
the full set of PDP-11 operating system disk images and support scripts.
Underneath this is a small Linux OS environment, based on a modern Linux kernel and
associated system software, built using the
[BuildRoot](https://buildroot.org) embedded Linux system generation tool.

Compared to the original UniBone/QBone distribution, QUniBoot has a number of new features,
as well as a few omissions.


- [Features](#features)
- [Differences vs Existing UniBone/QBone Distribution](#differences-vs-existing-unibonequbone-distribution)
- [Installed Software](#installed-software)
- [Quick Start](#quick-start)
  - [Download and Installation](#download-and-installation)
    - [Installing on Linux](#installing-on-linux)
    - [Installing on macOS](#installing-on-macos)
    - [Installing on Windows](#installing-on-windows)
  - [Auto-Configuration](#auto-configuration)
  - [Logging In](#logging-in)
- [Upgrading](#upgrading)
- [Accessing the Serial Console](#accessing-the-serial-console)
- [How-Tos and FAQs](#how-tos-and-faqs)
- [Building QUniBoot](#building-quniboot)
- [Acknowledgments](#acknowledgments)
- [License](#license)
- [Authorship Notice](#authorship-notice)

---

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


## Differences vs Existing UniBone/QBone Distribution

QUniBoot is designed as a purpose-built embedded OS rather than a general-purpose desktop
system. Its most significant departure from typical desktop OSes is the absence
of a package manager. In QUniBoot, software packages are selected and built into the
system image at generation time, rather than installed at runtime.

Other notable omissions include:

- X Windows and remote desktop support
- A C/C++ compiler
- systemd and udev

These differences help to keep QUniBoot small and efficient. Despite this, the system
includes most tools and utilities QUniBone users come to expect. And the BuildRoot system
makes it easy to enhance the system with new packages.


## Installed Software

The following software packages are included in the QUniBoot distribution:

- **QUniBone software**: The emulator application (`demo`), PDP-11
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
- **Shells**: bash, BusyBox shell.


## Quick Start

1. Follow the steps in [Download and Installation](#download-and-installation)
   to write the **full** OS variant of QUniBoot to a blank SD card. Choose
   the appropriate image file for your hardware:

   - `quniboot-unibone-full.img` or
   - `quniboot-qbone-full.img`

2. After the SD card has been written, follow the steps in [Auto-Configuration](#auto-configuration)
   to configure the initial settings for the system.
3. Insert the card into the BeagleBone Black and boot the PDP-11 system.

Once the system is booted, follow the instructions below for [Logging In](#logging-in).


### Download and Installation

Prebuilt images for QUniBoot are available for download on GitHub: [QUniBoot/releases](https://github.com/jaylogue/QUniBoot/releases).

Separate images exist for each supported hardware target (`unibone` and `qbone`).
Additionally, images come in two variants for each target:

- `full`: OS, system files, boot files and all PDP-11 software and 
  disk images. Use this variant for a fresh install.
- `os-only`: OS, system and boot files only. Use this variant to upgrade an
  existing install (see [Upgrading](#upgrading)).

Installing QUniBoot requires a 2GB or larger micro-SD card. If a larger card is used,
QUniBoot will automatically expand to make use of all available space.

> **Warning**: Writing an image to an SD card will overwrite existing data
> on the card. Be sure to have adequate backups before you start.


#### Installing on Linux

1. Insert the SD card and identify its device name:

   ```
   lsblk
   ```

   Look for the disk entry matching the size of your SD card (e.g.
   `/dev/sdb`). Do not use a partition name (e.g. `/dev/sdb1`).

2. Write the image:

   ```
   sudo dd if=quniboot-<hardware>-<variant>.img of=/dev/sdX bs=4M status=progress oflag=direct
   ```

   Replace `/dev/sdX` with the device name found in step 1.

3. When the write finishes, eject the disk:

   ```
   sudo eject /dev/sdX
   ```

#### Installing on macOS

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
   sudo dd if=output/images/quniboot-<hardware>-<variant>.img of=/dev/rdiskN bs=4M
   ```

   Replace `diskN` with the disk identifier found in step 1.

4. When the write finishes, eject the disk:

   ```
   diskutil eject /dev/diskN
   ```

#### Installing on Windows

Windows has no built-in tool for writing raw disk images, so a third-party
imaging tool is required, such as [balenaEtcher](https://etcher.balena.io/).

1. Download and install balenaEtcher, if not already installed. (You can
   also use Rufus for this).

2. Insert the SD card.

3. Launch Etcher and select the QUniBoot image file
   (`quniboot-<hardware>-<variant>.img`) as the source.

4. Select your SD card as the target drive.

   Etcher only lists removable drives, which helps prevent accidentally
   writing to the wrong disk. Confirm the drive matches the size of your
   SD card before continuing.

5. Click **Flash** to write the image. Etcher verifies the write and
   ejects the SD card automatically when finished.


### Auto-Configuration

QUniBoot provides a feature to automatically configure important system 
settings at boot time. This feature can be used to configure a newly 
installed system image, or reconfigure an existing system.

Auto-configuration works by looking for a file called `autoconfig.txt` in
the `BOOT` partition of the SD card. If present, the system will read the file
and update its configuration based on the values therein.

An example auto-configuration file (`autoconfig-example.txt`) is included in 
the `BOOT` partition of the stock QUniBoot image.

To enable auto-configuration:
 
1. Insert the SD card into your computer and wait for the `BOOT` drive
   to appear.

   *NOTE: If you just installed a new QUniBoot image on the card, you may need to
   remove and re-insert it in order to get the `BOOT` drive to appear.*

2. Open the `BOOT` drive and copy the `autoconfig-example.txt` file to a
   new file called `autoconfig.txt`.

3. Open the `autoconfig.txt` file with a text editor. Uncomment (remove the
   #) and fill in the settings with appropriate values for your system. Follow the
   descriptions in the file to understand the purpose and syntax of each setting.

   Note that it is not necessary to provide values for every setting. Any value
   not set will leave the existing/default configuration in place.
      
   Indeed, on a new system, it is not necessary to change *any* of the system 
   settings, as the default values are entirely sufficient to use the system.
   However, for security reasons, it is strongly encouraged to set at least one
   of the following values:
   
   - `ROOT_PASSWORD` -- Set the root user password
   
   - `ROOT_AUTHORIZED_KEY` -- Set an authorized SSH key for the root user

4. When done editing, close the file and safely eject the SD card.

5. Insert the card into the UniBone/QBone and boot the PDP-11 system.

If auto-configuration completes successfully, the system will flash the UniBone/QBone
LEDs 3 times. If an error occurs, the system will light the LEDs and leave them on.
After a failure, the system log file (/var/log/messages) can be inspected to determine
the cause.

Once auto-configuration completes, the system will rename the `autoconfig.txt` file to
`autoconfig-completed.txt` to ensure it doesn't get re-applied at the next
boot.

### Logging In

The easiest way to interact with a QUniBoot system is to connect over the
local-area network using SSH.
Any SSH-capable client will work as long as it is connected to the same network as
the UniBone/QBone.

When connected to a network, QUniBoot advertises itself via mDNS using the name
  `<hostname>.local`.
The hostname defaults to either `unibone` or `qbone`, unless overridden via the
`HOSTNAME` auto-config setting.

If you setup an SSH public key using the `ROOT_AUTHORIZED_KEY` setting, you must
supply the corresponding private key when connecting.
If you did not set an SSH key, you can log in using the root password.

On Linux and macOS, you can use the system's ssh client to connect to QUniBoot:

```
ssh root@unibone.local
```

On Windows, you can use PuTTY or any other suitable SSH client:

*(example TBD)*


## Upgrading

The QUniBoot system can be upgraded by writing a new **os-only** image over an
existing QUniBoot SD card. The upgrade process replaces the OS and `BOOT` partitions
on the card, but leaves the partition holding the PDP-11 disk images and script
files intact.

Upgrading an existing QUniBoot system will reset all core system settings, including
the root password, SSH keys and network configuration.  If the auto-configuration
mechanism was used to configure the system originally, you can preserve the original
settings prior to upgrading the card and re-apply when the upgraded system boots.

To upgrade a QUniBoot system:

1. If you used auto-configuration to set up the system originally, and you want to
   preserve those settings on the upgraded system, insert the SD card into a computer
   and save a copy of the `autoconfig-completed.txt` file (located in `BOOT` partition)
   to a local disk.

2. Follow the steps in [Download and Installation](#download-and-installation),
   selecting and installing the correct **os-only** image for your hardware

   - `quniboot-unibone-os-only.img` or
   - `quniboot-qbone-os-only.img`

3. Before booting the upgraded SD card, copy the saved `autoconfig-completed.txt` file
   from step 1 into the `BOOT` partition on the upgraded card and rename the file
   to `autoconfig.txt`. (Note that you may need to remove and re-insert the SD card
   to get the `BOOT` partition to appear).

4. If needed, follow the steps in [Auto-Configuration](#auto-configuration) to
   adjust the system configuration.

5. Safely eject the SD card.

6. Insert the card into the BeagleBone Black and boot the PDP-11 system.


## Accessing the Serial Console

The QUniBoot system console is connected to the BeagleBone's UART0 serial port.
UART0 is exposed on the card's Serial Debug Header (J1) which is located on the top
of the BBB (but oriented towards the bottom when installed on the UniBone/QBone).
Log messages from the system bootloader and kernel are written to the console
during the boot process.
Once boot completes, the console automatically drops into a root shell.

The serial console can be accessed using an inexpensive USB to TTL 3.3V serial
adapter. Connect the adapter to the J1 header as follows:

| BBB J1 Pin | Serial Connection | Typical Wire Color |
|---|---|---|
| 1 | Ground | Black |
| 4 | Receive | White |
| 5 | Transmit | Green |

> **WARNING**: The BeagleBone Black is quite susceptible to ground currents.
> Before connecting a serial adapter it is strongly encouraged to first check for
> any voltage potential between the ground on the computer's USB connector and a
> ground point on the PDP-11. Any significant voltage between the two points
> should be investigated and eliminated **before** the serial connection is made.


## How-Tos and FAQs

*Coming soon*


## Building QUniBoot

*Coming soon*


## Acknowledgments

A most hearty thanks goes to Jörg Hoppe for his excellent UniBone and QBone hardware
 and software.
There are many a PDP-11 (and the occasional VAX) that would be nothing without
 them.


## License

All content published as part of the QUniBoot project, including source
code, patches, configuration files and documentation, is licensed under the
Apache 2.0 license.


## Authorship Notice

All source code, patches and configuration files were generated solely by
the author.

Project documentation, including this README, was generated by the author
with style and grammar review performed by AI tools.
