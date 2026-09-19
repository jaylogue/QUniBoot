# QUniBoot How-Tos and FAQs

This document contains answers to some frequently asked questions about QUniBoot,
along with instructions for performing various common system management
tasks.

> **PLEASE NOTE**: This document is a work in progress. If you have questions
> or feedback, feel free to open an issue at the project's github site:
> [github.com/jaylogue/QUniBoot](https://github.com/jaylogue/QUniBoot). All
> comments welcome.


- [How-Tos](#how-tos)
  - [Automatically Start QUniBone Emulation at Boot](#automatically-start-qunibone-emulation-at-boot)
  - [Set QBUS Address Width](#set-qbus-address-width)
  - [Disable/Re-enable Login on UART2](#disablere-enable-login-on-uart2)
  - [Reset Root Password](#reset-root-password)
  - [Reset Root SSH Keys](#reset-root-ssh-keys)
  - [Reset Network Configuration](#reset-network-configuration)
  - [Shut Down Gracefully](#shut-down-gracefully)
- [FAQs](#faqs)
  - [Where is network configuration stored?](#where-is-network-configuration-stored)
  - [Why can't I log in with a password using SSH?](#why-cant-i-log-in-with-a-password-using-ssh)
  - [Is there a C/C++ compiler?](#is-there-a-cc-compiler)
  - [Do I really need to shut down gracefully?](#do-i-really-need-to-shut-down-gracefully)

---

## How-Tos

### Automatically Start QUniBone Emulation at Boot

To configure a QUniBoot system to automatically start QUniBone emulation at
boot time, perform the following steps from a root shell:

- In the root home directory, copy the file `autostart-example.sh` to 
`autostart.sh`.  (If `autostart-example.sh` doesn't exist in the root home
directory, a master copy can be found at `/etc/default/autostart.sh`).

  ```
  cd ~
  cp autostart-example.sh autostart.sh
  ```

- Edit `autostart.sh` and search for the `AUTO-START COMMAND TABLE`. Add the
desired emulation commands to the table. (Up to 15 different commands can
be entered).

- Save the file and ensure that it is executable.

  ```
  chmod u+rx ~/autostart.sh
  ```

- Configure the UniBone/QBone switches to the selected command number and reboot
the system.

When the system reboots, the selected emulation command will be started in a
background screen(1) session. To view the output of the command and interact
with it, attach to the background session using the following command:

  ```
  screen -r QUniBone
  ```


### Set QBUS Address Width

For proper operation in a QBUS system, the QUniBone software needs to know the width
of the system's address bus. On QUniBoot, this information is passed to the application
using the `QBUS_ADDRESS_WIDTH` environment variable.

By default, the QBUS address width is set to 22.  To change this, edit the root
user's .profile file (`/root/.profile`) and adjust the setting accordingly.

Valid values for `QBUS_ADDRESS_WIDTH` are 16, 18 and 22.

After changing the setting, log out and log back in as root, or reboot the system.

### Disable/Re-enable Login on UART2

To free up UART2 for other uses, you can disable automatic login by editing the file
`/etc/inittab` and commenting out (#) the line starting with "ttyS2". E.g.:

  ```
  #ttyS2::respawn:/sbin/getty -L -n -l /usr/local/sbin/autologin.sh ttyS2 115200 xterm
  ```

To re-enable logins on UART2, simply uncomment the line.

You must reboot after making any changes.


### Reset Root Password

If you are unable to log in to the system, you can reset the root password as follows:

Follow the steps in the [Auto-Configuration](SETUP_GUIDE.md#auto-configuration)
section of the Setup Guide. When creating the `autoconfig.txt` file, uncomment and set
the `ROOT_PASSWORD=` line to the new root password. Then reboot the system.

> **NOTE**: If you have installed SSH public keys in the root user's authorized_keys file,
> logging in via password may be disabled. To clear the root authorized_keys file, follow
> the steps below.


### Reset Root SSH Keys

If you are unable to log in to the system, you can reset the root authorized_keys file
as follows:

Follow the steps in the [Auto-Configuration](SETUP_GUIDE.md#auto-configuration)
section of the Setup Guide. When creating the `autoconfig.txt` file, uncomment the
`ROOT_AUTHORIZED_KEY=CLEAR` line. If you wish to install a new key, also uncomment
and set the `ROOT_AUTHORIZED_KEY=` line to the new SSH public key. Then reboot the
system.

> **NOTE**: Clearing the root authorized_keys file will re-enable login via password.
> If you need to reset the root password, follow the steps outlined above.


### Reset Network Configuration

If you are unable to log in to the system, you can reset the system network configuration
as follows:

Follow the steps in the [Auto-Configuration](SETUP_GUIDE.md#auto-configuration)
section of the Setup Guide. When creating the `autoconfig.txt` file, uncomment
and set the following lines with appropriate values:

- IP_ADDR=\<XXX.XXX.XXX.XXX\>
- NETMASK=\<XXX.XXX.XXX.XXX\>
- GATEWAY=\<XXX.XXX.XXX.XXX\>
- NAMESERVER=\<XXX.XXX.XXX.XXX\>

If you wish to have the system acquire its network configuration via DHCP, uncomment 
the following line:

- IP_ADDR=DHCP

When done editing `autoconfig.txt`, reboot the system.


### Shut Down Gracefully

There are three ways to shut down a QUniBoot system gracefully:

- Log in to the system on a serial port, or remotely via `ssh`, and run
the `poweroff` command:
  ```
  poweroff
  ```

- Press and hold the UniBone/QBone input button for 3 seconds

- Press the POWER button on the BeagleBone Black (note however that this button is
quite hard to reach when the UniBone/QBone is installed in a host machine).

But, see also [Do I really need to shut down gracefully?](#do-i-really-need-to-shut-down-gracefully)


## FAQs

### Where is network configuration stored?

The system network configuration is stored in `/etc/network/interfaces`.


### Why can't I log in with a password using SSH?

If you use the [Auto-Configuration](SETUP_GUIDE.md#auto-configuration) feature
to install an SSH public key in root's authorized_keys file (`/root/.ssh/authorized_keys`)
the system automatically disables login via password.

To re-enable login using passwords, edit the file `/etc/ssh/sshd_config.d/00-local.conf`
and change the `PasswordAuthentication` line to `yes`:

  ```
  PasswordAuthentication yes
  ```

Reboot the system to have this change take effect.


### Is there a C/C++ compiler?

QUniBoot does not ship with a C/C++ compiler. QUniBoot is built using the
[BuildRoot](https://buildroot.org/) system generation tool. The BuildRoot philosophy is
that all components that run on the target system are generated via cross-compilation.
Following that philosophy, the BuildRoot team does not supply an option to include
a C/C++ compiler.

It's true that the tools to perform cross-compilation are readily available, and much easier to
set up and use than in the past.  If the goal is to rebuild the QUniBone emulation software
(the demo app), consider using the [qunibone-cross-compile](https://github.com/jaylogue/qunibone-cross-compile)
project. It takes care of sourcing and invoking the appropriate cross-compilation tools
and support libraries. The Makefile from this project can also be used as a template for
building other components.


### Do I really need to shut down gracefully?

Not really. It's nice, but you can get away without doing it if you follow some simple rules.

The QUniBoot system itself is fairly resilient to arbitrary power loss.
The main filesystems (/ and /qunibone) use metadata journaling to allow the system to
quickly recover consistency upon restart from an unclean shutdown. The system will perform
an fsck if there is extensive corruption. However, in cases of a hard shutdown, the need
should never arise.

Where consistency remains an issue is in the contents of data files. Data in files can
be lost if not fully flushed to storage before a power loss.

The QUniBoot OS (Linux and the various system daemons) does no writing to disk under
normal operation — temp files and system logs are stored in RAM, and system daemons
require no persistent state. So the primary source of disk writes is the QUniBone
application itself (`demo`), and in particular, writes to the files that back emulated
disk devices.

The QUniBone application ensures that writes from the host OS to an emulated disk are
flushed to the underlying file as soon as they are posted. However, once written,
the data can linger in the Linux buffer cache for a while before actually being committed
to storage.

To limit the loss of data on an unclean shutdown, the QUniBoot Linux kernel has been
tuned to be very aggressive about flushing data to disk: any unwritten data in the
buffer cache is scheduled for write to durable storage **within one second**.

Of course, if the host OS itself caches writes (e.g. research Unix or BSD), or 
if you're in the middle of editing a file, those writes need to get flushed to the
emulated disk, and then on to durable storage, before it is safe to power off.

So...

#### The procedure for shutting off power to the host system without shutting down QUniBoot is:

**1 — Quiesce writes by the host OS (sync disks, close editors, go into single-user
mode, etc.)**

**2 — Wait a few seconds**

**3 — Turn off power**
