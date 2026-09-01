#!/usr/bin/env bash

set -e

TOP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}/")"/.. && pwd)

# If running within a git repo, get the HEAD version
HEAD=$(git -C "${TOP_DIR}" rev-parse --verify --short HEAD 2>/dev/null || true)
if [ -n "${HEAD}" ]; then

    # Ask git to construct a version string based on the most recent version tag (v*)
    # and the current state of the repo
    VERSION=$(git -C "${TOP_DIR}" describe --tags --match "v*" --dirty 2>/dev/null || true)

    # If there is no version tag, manufacture a dummy "v0" version string.
    if [ -z "${VERSION}" ]; then
        VERSION="v0-0-g${HEAD}"
        if [ -n "$(git diff-index --name-only HEAD)" ]; then
            VERSION="${VERSION}-dirty"
        fi
    fi

# Otherwise, the script is NOT running within a git repo, so...
# If a quniboot_version file exists...
elif [ -r "${TOP_DIR}/quniboot_version" ]; then

    # Read the contents of the version file
    VERSION=$(<"${TOP_DIR}/quniboot_version")

    # The quniboot_version file contains a macro expression which gets expanded
    # into a version string by the 'git archive' command. Thus, if the script is
    # running in an archive source tree, that file will contain the version in effect
    # when the archive was created.
    #
    # However, if the macro has NOT been expanded, then there isn't a way to tell
    # the build version, so return "unknown-version".
    if [[ "${VERSION}" =~ ^\$Format: ]]; then
        VERSION="unknown-version"
    fi
fi

echo "${VERSION}"
