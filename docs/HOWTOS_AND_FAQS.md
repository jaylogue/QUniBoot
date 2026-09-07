# QUniBoot How-Tos and FAQs

This document contains answers to some frequently asked questions about QUniBoot,
along with instructions for performing various common system management
tasks.

> **PLEASE NOTE**: This document is a work in progress. If you have questions
> or feedback, feel free to open an issue at the project's github site:
> [github.com/jaylogue/QUniBoot](https://github.com/jaylogue/QUniBoot). All
> comments welcomed.


- [How-Tos](#how-tos)
  - [Automatically Start QUniBone Emulation at Boot](#automatically-start-qunibone-emulation-at-boot)
  - [Set QBUS Address Width](#set-qbus-address-width)
  - [Disable/Re-enable Login on UART2](#disablere-enable-login-on-uart2)
  - [Reset Root Password](#reset-root-password)
  - [Reset Root SSH Keys](#reset-root-ssh-keys)
  - [Reset Network Configuration](#reset-network-configuration)
- [FAQs](#faqs)
  - [Where is network configuration stored?](#where-is-network-configuration-stored)
  - [Why can't I login with a password using SSH?](#why-cant-i-login-with-a-password-using-ssh)
  - [Is there a C/C++ compiler?](#is-there-a-cc-compiler)

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

After changing the setting, log out and re-log in as root, or reboot the system.

### Disable/Re-enable Login on UART2

To free up UART2 for other uses, you can disable automatic login by editing the file
`/etc/inittab` and commenting out (#) the line starting with "ttyS2". E.g.:

  ```
  #ttyS2::respawn:/sbin/getty -L -n -l /usr/local/sbin/autologin.sh ttyS2 115200 xterm
  ```

To re-enable logins on UART2, simply uncomment the line.

You must reboot after making any changes.

### Reset Root Password

If you are unable to login to the system, you can reset the root password as follows:

Follow the steps in the [Auto-Configuration](SETUP_GUIDE.md#auto-configuration)
section of the SETUP GUIDE. When creating the `autoconfig.txt` file, uncomment and set
the `ROOT_PASSWORD=` line to the new root password. Then reboot the system.

> **NOTE**: If you have installed SSH public keys in the root user's authorized_keys file,
> logging in via password may be disabled. To clear the root authorized_keys file, follow
> the steps below.

### Reset Root SSH Keys

If you are unable to login to the system, you can reset the root authorized_keys file
as follows:

Follow the steps in the [Auto-Configuration](SETUP_GUIDE.md#auto-configuration)
section of the SETUP GUIDE. When creating the `autoconfig.txt` file, uncomment the
`ROOT_AUTHORIZED_KEY=CLEAR` line. If you wish to install a new key, also uncomment
and set the `ROOT_AUTHORIZED_KEY=` line to the new SSH public key. Then reboot the
system.

> **NOTE**: Clearing the root authorized_keys file will re-enable login via password.
> If you need to reset the root password, follow the steps outlined above.

### Reset Network Configuration

If you are unable to login to the system, you can reset the system network configuration
as follows:

Follow the steps in the [Auto-Configuration](SETUP_GUIDE.md#auto-configuration)
section of the SETUP GUIDE. When creating the `autoconfig.txt` file, uncomment
and set the following lines with appropriate values:

- IP_ADDR=\<XXX.XXX.XXX.XXX\>
- NETMASK=\<XXX.XXX.XXX.XXX\>
- GATEWAY=\<XXX.XXX.XXX.XXX\>
- NAMESERVER=\<XXX.XXX.XXX.XXX\>

If you wish to have the system acquire its network configuration via DHCP, uncomment 
the following line:

- IP_ADDR=DHCP

When done editing `autoconfig.txt`, reboot the system.

## FAQs

### Where is network configuration stored?

The system network configuration is stored in `/etc/network/interfaces`.

### Why can't I login with a password using SSH?

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
setup and use than in the past.  If the goal is to rebuild the QUniBone emulation software
(the demo app) consider using [qunibone-cross-compile](https://github.com/jaylogue/qunibone-cross-compile)
project. It takes care of sourcing and invoking the appropriate cross-compilation tools
and support libraries. The Makefile from this project can also be used as a template for
building other components.
