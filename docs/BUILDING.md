# Building QUniBoot

This document describes how to build QUniBoot system images from the QUniBoot
source tree.

## BuildRoot

QUniBoot images are built using the [BuildRoot](https://buildroot.org) tool.
BuildRoot is an embedded Linux system generation tool that works via cross-compilation.
It automates all aspects of Linux system generation, including downloading, patching
and cross-compiling the Linux kernel, building system tools and utilities, assembling
filesystems, and building bootable system images. BuildRoot also takes care of sourcing
all the tools needed to support cross-compilation on the host platform.

BuildRoot itself requires Linux. However it can be run on other OSes via containerization.

BuildRoot has an extensive [User Manual](https://buildroot.org/downloads/manual/manual.html)
focused largely on adapting it to new hardware platforms or adding new software packages.
While understanding the features of BuildRoot can be useful, it is not required in order
to build QUniBoot.

## Host System

QUniBoot must be built on a Linux system. This can be accomplished in one of two ways:

- Install the necessary prerequisites and build directly on a native Linux machine or VM.

- Use the [Podman](https://podman.io/) tool to run the build within a Linux container.

Podman is the recommended approach to building QUniBoot on macOS hosts.

On Windows, QUniBoot can be built directly inside a WSLv2 VM, or by using Podman (which in
turn uses WSLv2 VMs itself).

QUniBoot should build cleanly on any main-stream Linux distribution. However, testing has
been confined to Ubuntu-based systems only. As an alternative, using Podman on Linux
is a convenient way to avoid dependencies on the host system.

Instructions for building QUniBoot using Podman are given below.

## Prerequisites

The QUniBoot build depends on a handful of Linux packages. These can be installed directly
on a host Linux system or VM using the following commands:

```
$ apt-get update
$ apt-get install -y \
    build-essential \
    make \
    cmake \
    git \
    file \
    cpio \
    unzip \
    rsync \
    wget \
    bc \
    xxd \
    fakeroot \
    dosfstools \
    mtools \
    pkg-config \
    libc6-i386 \
    lib32stdc++6 \
    lib32z1
```

When building using Podman, QUniBoot provides scripts that take care of incorporating these packages
into the Podman container image. In this case, the only requirement on the host system is to install
Podman itself.

## Disk Space

Building QUniBoot requires a lot of disk space. Prior to starting a build, ensure you have
at least 36GB of space available on the build volume.

## Building QUniBoot Images

To build QUniBoot system images directly on a host Linux system, start by downloading the QUniBoot
source tree.

You can either download a source archive for one of the published releases:

[https://github.com/jaylogue/QUniBoot/releases](https://github.com/jaylogue/QUniBoot/releases)

Or clone the source tree locally using git:

```
$ git clone https://github.com/jaylogue/QUniBoot.git
```

Once the source tree is in place, run `make all` in the top-level directory, specifying the target
hardware device (`unibone` or `qbone`) via the `QUNIBOOT_TARGET` make variable:

 ```
 $ cd QUniBoot
 $ make QUNIBOOT_TARGET=unibone all
 ```

The build takes a fair bit of time to complete—on the order of 20 minutes on a modern x86 system. As
the build progresses, the build scripts automatically download and build the source code for each
of the constituent components.

Once the build completes, the generated image files can be found in the `output/images` directory,
named according to the target hardware and image variant. E.g.:

- `quniboot-qbone-full.img`
- `quniboot-qbone-os-only.img`

## Rebuilding

To rebuild QUniBoot for a different target hardware device, it is necessary to completely reset the
source tree to an unconfigured state using the `make distclean` command. E.g.:

```
$ make QUNIBOOT_TARGET=unibone all
$ make distclean
$ make QUNIBOOT_TARGET=qbone all
```

As it runs, the build process automatically caches all tools and source archives needed to complete
the build. Thus, after an initial build is complete, a rebuild can be performed entirely locally,
without the need for network access. To force these files to be re-downloaded, simply delete the 'dl'
directory at the top-level.

By default, the build process is configured to use the ccache tool. The ccache tool caches the output
of individual compile steps, greatly speeding up the process of rebuilding. To clear the ccache cache
run the `make clean-ccache` command.


## Building QUniBoot Using Podman

QUniBoot includes scripts for initialing and using Podman to orchestrate image builds. Podman
creates a containerized Linux system within which the QUniBoot build processes run. Using Podman
provides means for building and developing QUniBoot on non-Linux systems. It can also be used
on a native Linux system to avoid polluting the system with the build prerequisites.

Instructions for installing Podman can be found in the [Podman documentation](https://podman.io/docs).

To build QUniBoot using Podman, start by downloading the QUniBoot source tree as described in
[Building QUniBoot Images](#building-quniboot-images).

### Creating the quniboot-build Podman Image

In order to build QUniBoot with Podman, a Podman container image must be prepared on the host system.
The image is based on a stock Ubuntu 24.04 image with the necessary build prerequisites installed.
The Podman recipe for creating the image can be found in `scripts/Containerfile.quniboot-build`.

Use the supplied `scripts/init-container.sh` script to create the container image:

```
$ cd QUniBoot
$ ./scripts/init-container.sh
```

When this completes, the container image should be visible in the image inventory:

```
$ Podman image list
REPOSITORY                TAG         IMAGE ID      CREATED       SIZE
localhost/quniboot-build  latest      db81095689eb  24 hours ago  1.05 GB
docker.io/library/ubuntu  24.04       a6f81fb630d5  2 weeks ago   80.7 MB
```

### Invoking Build Commands within a Podman Container

Once the quniboot-build image has been created, the `scripts/run-container.sh` script can be
used to execute build commands within a container created from that image. The script creates
and starts an ephemeral instance of the container, runs the specified command within it, and
then destroys the container once the command completes.

While the container is running, the root directory of the QUniBoot source tree is mapped
into the filesystem of the container. Thus, as build scripts run within the container, their
output is placed into the source tree, as would happen if the build was run directly on a
native Linux host.

Any command can be run within a build container by prefacing it with `./scripts/run-container.sh`. E.g.:

```
$ ./scripts/run-container.sh echo HELLO
HELLO
```

To build the QUniBoot images using Podman, invoke 'make all' within a build container,
specifying the desired target hardware:

```
$ cd QUniBoot
$ ./scripts/run-container.sh make QUNIBOOT_TARGET=unibone all
```

## Useful Make Targets

The Makefile at the top level of the source tree provides a number of targets that can be useful
for development. The top-level Makefile also acts as a wrapper for the standard BuildRoot Makefile,
forwarding targets it doesn't understand to the subordinate Makefile. Thus, all targets offered
by the BuildRoot Makefile are also available from the top level.

Here are some useful make targets the system provides.

- `make download-buildroot` -- Download the BuildRoot package file from buildroot.org.

- `make stage-buildroot` -- Unpack the BuildRoot tool and apply QUniBoot-specific patches.

- `make configure-buildroot` -- Configure BuildRoot for building QUniBoot images for the target device.

- `make all` -- Download, unpack and configure BuildRoot, and then build QUniBoot
images for the target device.

- `make menuconfig` -- Run the BuildRoot configuration tool to inspect or change build settings
or add and remove packages.

- `make clean` -- Delete all build products including build, host, staging and target
directories, along with images and the toolchain. Note that this does NOT remove BuildRoot
itself or the BuildRoot configuration.

- `make distclean` -- Remove all build products along with BuildRoot and its configuration.

- `make clean-target` -- Remove just the BuildRoot 'output/target' directory (the template for
the root filesystem), forcing it to be rebuilt on the next invocation.

- `make clean-ccache` -- Remove the cache directory used by the ccache tool.

- `make <package>-rebuild` -- Force a rebuild of the specified package.

- `make <package>-dirclean` -- Remove build products for the specified package.

When running these commands, remember to pass the appropriate `QUNIBOOT_TARGET` value
for your target hardware (although in practice this is not required for any of the "clean"
commands).
