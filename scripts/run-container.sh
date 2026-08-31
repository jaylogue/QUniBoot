#!/usr/bin/bash
#
# Run a command in the quniboot-build Podman container
# with the QUniBoot top directory mapped into the container.
#

TOP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}/")"/.. && pwd)

IMAGE_NAME="quniboot-build:latest"

set -x

exec podman run \
    --rm \
    --userns=keep-id \
    -v ${TOP_DIR}:${TOP_DIR}:Z \
    -w ${TOP_DIR} \
    localhost/${IMAGE_NAME} \
    "$@"
