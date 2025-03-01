#!/bin/bash

set -eE 
trap 'echo Error: in $0 on line $LINENO; exit 1' ERR

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

cd "$(dirname -- "$(readlink -f -- "$0")")" && cd ..
mkdir -p build && cd build

if [[ -z ${UBOOT_PACKAGE} ]]; then
    echo "Error: UBOOT_PACKAGE is not set"
    exit 1
fi

if [ ! -d "${UBOOT_PACKAGE}" ]; then
    if [[ ! -f "../packages/${UBOOT_PACKAGE}/debian/upstream" ]]; then
        echo "Error: Upstream configuration file ../packages/${UBOOT_PACKAGE}/debian/upstream not found"
        exit 1
    fi

    # shellcheck source=/dev/null
    source "../packages/${UBOOT_PACKAGE}/debian/upstream"

    if [[ -z ${BRANCH} || -z ${GIT} || -z ${COMMIT} ]]; then
        echo "Error: BRANCH, GIT, or COMMIT is not set in upstream configuration"
        exit 1
    fi

    if ! git clone --single-branch --progress -b "${BRANCH}" "${GIT}" "${UBOOT_PACKAGE}"; then
        echo "Error: Failed to clone U-Boot repository"
        exit 1
    fi

    if ! git -C "${UBOOT_PACKAGE}" checkout "${COMMIT}"; then
        echo "Error: Failed to checkout U-Boot commit ${COMMIT}"
        exit 1
    fi

    cp -r "../packages/${UBOOT_PACKAGE}/debian" "${UBOOT_PACKAGE}"
fi

cd "${UBOOT_PACKAGE}"

if [[ -z ${UBOOT_RULES_TARGET} ]]; then
    echo "Error: UBOOT_RULES_TARGET is not set"
    exit 1
fi

# Target package to build
rules=${UBOOT_RULES_TARGET},package-${UBOOT_RULES_TARGET}
if [[ -n ${UBOOT_RULES_TARGET_EXTRA} ]]; then
    rules=${UBOOT_RULES_TARGET_EXTRA},${rules}
fi

# Compile u-boot into a deb package
if ! dpkg-source --before-build .; then
    echo "Error: Failed to prepare U-Boot source package"
    exit 1
fi

if ! dpkg-buildpackage -a "$(cat debian/arch)" -d -b -nc -uc --rules-target="${rules}"; then
    echo "Error: Failed to build U-Boot package"
    exit 1
fi

if ! dpkg-source --after-build .; then
    echo "Error: Failed to clean up U-Boot source package"
    exit 1
fi

rm -f ../*.buildinfo ../*.changes

echo "U-Boot package successfully built"