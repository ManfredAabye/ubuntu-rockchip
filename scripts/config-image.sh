#!/bin/bash

set -eE 
trap 'echo Error: in $0 on line $LINENO; teardown_mountpoint "${chroot_dir}"; exit 1' ERR

if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

cd "$(dirname -- "$(readlink -f -- "$0")")" && cd ..
mkdir -p build && cd build

if [[ -z ${BOARD} ]]; then
    echo "Error: BOARD is not set"
    exit 1
fi

# Load board configuration
if [[ ! -f "../config/boards/${BOARD}.sh" ]]; then
    echo "Error: Board configuration file ../config/boards/${BOARD}.sh not found"
    exit 1
fi

# shellcheck source=/dev/null
source "../config/boards/${BOARD}.sh"

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

if [[ -z ${FLAVOR} ]]; then
    echo "Error: FLAVOR is not set"
    exit 1
fi

# Load flavor configuration
if [[ ! -f "../config/flavors/${FLAVOR}.sh" ]]; then
    echo "Error: Flavor configuration file ../config/flavors/${FLAVOR}.sh not found"
    exit 1
fi

# shellcheck source=/dev/null
source "../config/flavors/${FLAVOR}.sh"

if [[ ${LAUNCHPAD} != "Y" ]]; then
    uboot_package="$(basename "$(find u-boot-"${BOARD}"_*.deb | sort | tail -n1)")"
    if [ ! -e "$uboot_package" ]; then
        echo 'Error: could not find the u-boot package'
        exit 1
    fi

    linux_image_package="$(basename "$(find linux-image-*.deb | sort | tail -n1)")"
    if [ ! -e "$linux_image_package" ]; then
        echo "Error: could not find the linux image package"
        exit 1
    fi

    linux_headers_package="$(basename "$(find linux-headers-*.deb | sort | tail -n1)")"
    if [ ! -e "$linux_headers_package" ]; then
        echo "Error: could not find the linux headers package"
        exit 1
    fi

    linux_modules_package="$(basename "$(find linux-modules-*.deb | sort | tail -n1)")"
    if [ ! -e "$linux_modules_package" ]; then
        echo "Error: could not find the linux modules package"
        exit 1
    fi

    linux_buildinfo_package="$(basename "$(find linux-buildinfo-*.deb | sort | tail -n1)")"
    if [ ! -e "$linux_buildinfo_package" ]; then
        echo "Error: could not find the linux buildinfo package"
        exit 1
    fi

    linux_rockchip_headers_package="$(basename "$(find linux-rockchip-headers-*.deb | sort | tail -n1)")"
    if [ ! -e "$linux_rockchip_headers_package" ]; then
        echo "Error: could not find the linux rockchip headers package"
        exit 1
    fi
fi

setup_mountpoint() {
    local mountpoint="$1"

    if [ ! -c /dev/mem ]; then
        mknod -m 660 /dev/mem c 1 1
        chown root:kmem /dev/mem
    fi

    if ! mount dev-live -t devtmpfs "$mountpoint/dev"; then
        echo "Error: Failed to mount devtmpfs"
        exit 1
    fi

    if ! mount devpts-live -t devpts -o nodev,nosuid "$mountpoint/dev/pts"; then
        echo "Error: Failed to mount devpts"
        exit 1
    fi

    if ! mount proc-live -t proc "$mountpoint/proc"; then
        echo "Error: Failed to mount proc"
        exit 1
    fi

    if ! mount sysfs-live -t sysfs "$mountpoint/sys"; then
        echo "Error: Failed to mount sysfs"
        exit 1
    fi

    if ! mount securityfs -t securityfs "$mountpoint/sys/kernel/security"; then
        echo "Error: Failed to mount securityfs"
        exit 1
    fi

    if ! mount -t cgroup2 none "$mountpoint/sys/fs/cgroup"; then
        echo "Error: Failed to mount cgroup2"
        exit 1
    fi

    if ! mount -t tmpfs none "$mountpoint/tmp"; then
        echo "Error: Failed to mount tmpfs for /tmp"
        exit 1
    fi

    if ! mount -t tmpfs none "$mountpoint/var/lib/apt/lists"; then
        echo "Error: Failed to mount tmpfs for /var/lib/apt/lists"
        exit 1
    fi

    if ! mount -t tmpfs none "$mountpoint/var/cache/apt"; then
        echo "Error: Failed to mount tmpfs for /var/cache/apt"
        exit 1
    fi

    mv "$mountpoint/etc/resolv.conf" resolv.conf.tmp
    cp /etc/resolv.conf "$mountpoint/etc/resolv.conf"
    mv "$mountpoint/etc/nsswitch.conf" nsswitch.conf.tmp
    sed 's/systemd//g' nsswitch.conf.tmp > "$mountpoint/etc/nsswitch.conf"
}

teardown_mountpoint() {
    # Reverse the operations from setup_mountpoint
    local mountpoint
    mountpoint=$(realpath "$1")

    # ensure we have exactly one trailing slash, and escape all slashes for awk
    mountpoint_match=$(echo "$mountpoint" | sed -e's,/$,,; s,/,\\/,g;')'\/'
    # sort -r ensures that deeper mountpoints are unmounted first
    awk </proc/self/mounts "\$2 ~ /$mountpoint_match/ { print \$2 }" | LC_ALL=C sort -r | while IFS= read -r submount; do
        mount --make-private "$submount"
        umount "$submount" || true
    done
    mv resolv.conf.tmp "$mountpoint/etc/resolv.conf"
    mv nsswitch.conf.tmp "$mountpoint/etc/nsswitch.conf"
}

# Prevent dpkg interactive dialogues
export DEBIAN_FRONTEND=noninteractive

# Override localisation settings to address a perl warning
export LC_ALL=C

# Debootstrap options
chroot_dir=rootfs
overlay_dir=../overlay

# Extract the compressed root filesystem
rm -rf ${chroot_dir} && mkdir -p ${chroot_dir}
if ! tar -xpJf "ubuntu-${RELASE_VERSION}-preinstalled-${FLAVOR}-arm64.rootfs.tar.xz" -C ${chroot_dir}; then
    echo "Error: Failed to extract root filesystem"
    exit 1
fi

# Mount the root filesystem
setup_mountpoint $chroot_dir

# Update packages
if ! chroot $chroot_dir apt-get update; then
    echo "Error: Failed to update packages"
    exit 1
fi

if ! chroot $chroot_dir apt-get -y upgrade; then
    echo "Error: Failed to upgrade packages"
    exit 1
fi

# Run config hook to handle board specific changes
if [[ $(type -t config_image_hook__"${BOARD}") == function ]]; then
    config_image_hook__"${BOARD}" "${chroot_dir}" "${overlay_dir}" "${SUITE}"
fi 

# Download and install U-Boot
if [[ ${LAUNCHPAD} == "Y" ]]; then
    if ! chroot ${chroot_dir} apt-get -y install "u-boot-${BOARD}"; then
        echo "Error: Failed to install U-Boot"
        exit 1
    fi
else
    cp "${uboot_package}" ${chroot_dir}/tmp/
    if ! chroot ${chroot_dir} dpkg -i "/tmp/${uboot_package}"; then
        echo "Error: Failed to install U-Boot package"
        exit 1
    fi
    chroot ${chroot_dir} apt-mark hold "$(echo "${uboot_package}" | sed -rn 's/(.*)_[[:digit:]].*/\1/p')"

    cp "${linux_image_package}" "${linux_headers_package}" "${linux_modules_package}" "${linux_buildinfo_package}" "${linux_rockchip_headers_package}" ${chroot_dir}/tmp/
    if ! chroot ${chroot_dir} /bin/bash -c "apt-get -y purge \$(dpkg --list | grep -Ei 'linux-image|linux-headers|linux-modules|linux-rockchip' | awk '{ print \$2 }')"; then
        echo "Error: Failed to purge old kernel packages"
        exit 1
    fi
    if ! chroot ${chroot_dir} /bin/bash -c "dpkg -i /tmp/{${linux_image_package},${linux_modules_package},${linux_buildinfo_package},${linux_rockchip_headers_package}}"; then
        echo "Error: Failed to install kernel packages"
        exit 1
    fi
    chroot ${chroot_dir} apt-mark hold "$(echo "${linux_image_package}" | sed -rn 's/(.*)_[[:digit:]].*/\1/p')"
    chroot ${chroot_dir} apt-mark hold "$(echo "${linux_modules_package}" | sed -rn 's/(.*)_[[:digit:]].*/\1/p')"
    chroot ${chroot_dir} apt-mark hold "$(echo "${linux_buildinfo_package}" | sed -rn 's/(.*)_[[:digit:]].*/\1/p')"
    chroot ${chroot_dir} apt-mark hold "$(echo "${linux_rockchip_headers_package}" | sed -rn 's/(.*)_[[:digit:]].*/\1/p')"
fi

# Update the initramfs
if ! chroot ${chroot_dir} update-initramfs -u; then
    echo "Error: Failed to update initramfs"
    exit 1
fi

# Remove packages
chroot ${chroot_dir} apt-get -y clean
chroot ${chroot_dir} apt-get -y autoclean
chroot ${chroot_dir} apt-get -y autoremove

# Umount the root filesystem
teardown_mountpoint $chroot_dir

# Compress the root filesystem and then build a disk image
cd ${chroot_dir} && if ! tar -cpf "../ubuntu-${RELASE_VERSION}-preinstalled-${FLAVOR}-arm64-${BOARD}.rootfs.tar" .; then
    echo "Error: Failed to create root filesystem tarball"
    exit 1
fi
cd .. && rm -rf ${chroot_dir}
if ! ../scripts/build-image.sh "ubuntu-${RELASE_VERSION}-preinstalled-${FLAVOR}-arm64-${BOARD}.rootfs.tar"; then
    echo "Error: Failed to build disk image"
    exit 1
fi
rm -f "ubuntu-${RELASE_VERSION}-preinstalled-${FLAVOR}-arm64-${BOARD}.rootfs.tar"