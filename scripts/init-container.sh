#!/usr/bin/env bash
#
# Builds a Podman container image for the QUniBoot build container
#

TOP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}/")"/.. && pwd)

IMAGE_NAME="quniboot-build:latest"
CONTAINER_FILE="${TOP_DIR}/scripts/Containerfile.quniboot-build"

EMPTY_DIR=$(mktemp -d)
trap 'rmdir ${EMPTY_DIR}' EXIT

set -x

exec podman build -t ${IMAGE_NAME} -f ${CONTAINER_FILE} ${EMPTY_DIR}
