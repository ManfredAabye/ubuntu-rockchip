#!/bin/bash

set -eE 
trap 'echo Error: in $0 on line $LINENO; exit 1' ERR

if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

cd "$(dirname -- "$(readlink -f -- "$0")")" && cd ..
mkdir -p build && cd build

if [[ -z ${SUITE} ]]; then
    echo "Error: SUITE is not set"
    exit 1
fi

# Load suite configuration
if [[ ! -f "../config/suites/${SUITE}.sh" ]]; then
    echo "Error: Suite configuration file ../config/suites/${SUITE}.sh not found"
    exit 1
fi

# shellcheck source=/dev/null
source "../config/suites/${SUITE}.sh"

# Verify kernel configuration
if [[ -z ${KERNEL_BRANCH} || -z ${KERNEL_REPO} ]]; then
    echo "Error: KERNEL_BRANCH or KERNEL_REPO is not set in suite configuration"
    exit 1
fi

# Clone or update the kernel repo
if [[ -d linux-rockchip ]]; then
    if ! git -C linux-rockchip pull; then
        echo "Error: Failed to update kernel repository"
        exit 1
    fi
else
    if ! git clone --progress -b "${KERNEL_BRANCH}" "${KERNEL_REPO}" linux-rockchip --depth=2; then
        echo "Error: Failed to clone kernel repository"
        exit 1
    fi
fi

cd linux-rockchip
git checkout "${KERNEL_BRANCH}"

# Set up environment for cross-compilation
# shellcheck disable=SC2046
export $(dpkg-architecture -aarm64)
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=aarch64-linux-gnu-gcc
export LANG=C

# Compile the kernel into a deb package
if ! fakeroot debian/rules clean binary-headers binary-rockchip do_mainline_build=true; then
    echo "Error: Kernel compilation failed"
    exit 1
fi

echo "Kernel compilation completed successfully"