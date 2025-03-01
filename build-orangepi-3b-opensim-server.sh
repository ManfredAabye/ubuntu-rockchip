#!/bin/bash

# Script zum Erstellen eines Ubuntu Noble OpenSim-Server-Images für den Orange Pi 3B
# Autor: Manfred Zainhofer
# Version: 1.0

# Variablen
REPO_URL="https://github.com/ManfredAabye/ubuntu-rockchip.git"
REPO_DIR="ubuntu-rockchip"
IMAGE_NAME="ubuntu-noble-orangepi-3b-opensim-server.img"
KERNEL_VERSION="6.6"  # Neuerer Kernel

# Funktionen
function cleanup() {
    echo "[DEBUG] Aufräumen..."
    if [ -d "${REPO_DIR}" ]; then
        rm -rf "${REPO_DIR}"
        echo "[DEBUG] Verzeichnis ${REPO_DIR} gelöscht."
    fi
}

function check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Bitte führe das Skript als root aus."
        exit 1
    fi
}

function check_dependencies() {
    echo "[DEBUG] Überprüfe Abhängigkeiten..."
    local dependencies=("git" "debootstrap" "qemu-user-static" "binfmt-support" "build-essential" "dh-make" "debhelper" "devscripts" "crossbuild-essential-arm64" "flex" "bison" "libssl-dev" "bc")
    for dep in "${dependencies[@]}"; do
        if ! command -v "${dep}" &>/dev/null; then
            echo "[DEBUG] Installiere ${dep}..."
            apt install -y "${dep}"
        else
            echo "[DEBUG] ${dep} ist bereits installiert."
        fi
    done
}

function clone_repo() {
    echo "[DEBUG] Klonen des Repositories..."
    if ! git clone "${REPO_URL}" "${REPO_DIR}"; then
        echo "Error: Failed to clone repository"
        exit 1
    fi
    cd "${REPO_DIR}" || exit 1
    echo "[DEBUG] Repository erfolgreich geklont."
}

function configure_board() {
    echo "[DEBUG] Konfiguriere Orange Pi 3B..."
    cp config/boards/orangepi-3b.sh config/boards/orangepi-3b.sh.bak  # Backup der originalen Datei
    cat <<EOF > config/boards/orangepi-3b.sh
export BOARD_NAME="Orange Pi 3B"
export BOARD_MAKER="Xulong"
export BOARD_SOC="Rockchip RK3566"
export BOARD_CPU="ARM Cortex A55"
export BOARD_GPU="Mali G52"
export UBOOT_PACKAGE="u-boot-turing-rk3588"
export UBOOT_RULES_TARGET="orangepi-3b-rk3566"
export COMPATIBLE_SUITES=("noble")
export COMPATIBLE_FLAVORS=("opensim-server")  # OpenSim-Server-Flavor
export KERNEL_VERSION="${KERNEL_VERSION}"

function config_image_hook__orangepi-3b() {
    local rootfs="\$1"
    local overlay="\$2"
    local suite="\$3"

    # Mali-Treiber hinzufügen
    echo "mali" >> "\${rootfs}/etc/modules"

    # Touchscreen-Treiber hinzufügen
    echo "ads7846" >> "\${rootfs}/etc/modules"

    # Zusätzliche Pakete installieren
    chroot "\${rootfs}" apt-get update
    chroot "\${rootfs}" apt-get install -y wiringpi-opi libwiringpi2-opi libwiringpi-opi-dev

    # OpenSim-Server-Pakete installieren
    chroot "\${rootfs}" apt-get install -y \\
        apache2 \\
        libapache2-mod-php \\
        php \\
        mariadb-server \\
        php-mysql \\
        php-common \\
        php-gd \\
        php-pear \\
        php-xmlrpc \\
        php-curl \\
        php-mbstring \\
        php-gettext \\
        zip \\
        screen \\
        git \\
        nant \\
        libopenjp2-tools \\
        graphicsmagick \\
        imagemagick \\
        curl \\
        php-cli \\
        php-bcmath \\
        dialog \\
        at \\
        mysqltuner \\
        crudini \\
        apt-utils \\
        libgdiplus \\
        zlib1g-dev \\
        libc6-dev

    # Dotnet 8 installieren
    chroot "\${rootfs}" wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
    chroot "\${rootfs}" dpkg -i /tmp/packages-microsoft-prod.deb
    chroot "\${rootfs}" apt-get update
    chroot "\${rootfs}" apt-get install -y dotnet-sdk-8.0

    # MariaDB-Datenbanken anlegen
    chroot "\${rootfs}" mysql -u root -e "CREATE DATABASE robust;"
    chroot "\${rootfs}" mysql -u root -e "CREATE DATABASE sim1;"
    chroot "\${rootfs}" mysql -u root -e "CREATE DATABASE sim2;"
    chroot "\${rootfs}" mysql -u root -e "CREATE DATABASE sim3;"
    chroot "\${rootfs}" mysql -u root -e "CREATE DATABASE sim4;"
    chroot "\${rootfs}" mysql -u root -e "CREATE DATABASE sim5;"

    # OpenSim herunterladen und entpacken
    chroot "\${rootfs}" mkdir -p /home/opensim
    chroot "\${rootfs}" wget http://opensimulator.org/dist/opensim-0.9.3.0.tar.gz -O /home/opensim/opensim-0.9.3.0.tar.gz
    chroot "\${rootfs}" tar -xzf /home/opensim/opensim-0.9.3.0.tar.gz -C /home/opensim
    chroot "\${rootfs}" rm /home/opensim/opensim-0.9.3.0.tar.gz

    return 0
}
EOF
    echo "[DEBUG] Board-Konfiguration erfolgreich angepasst."
}

function build_image() {
    echo "[DEBUG] Erstelle Image..."
    if ! ./build.sh --board=orangepi-3b --suite=noble --flavor=opensim-server; then
        echo "[DEBUG] Fehler beim Erstellen des Images."
        exit 1
    fi
    echo "[DEBUG] Image erfolgreich erstellt."
}

function locate_image() {
    echo "[DEBUG] Suche das erstellte Image..."
    IMAGE_PATH=$(find "${REPO_DIR}" -name "${IMAGE_NAME}" -type f)
    if [ -z "${IMAGE_PATH}" ]; then
        echo "Fehler: Image wurde nicht gefunden."
        exit 1
    else
        echo "Image erfolgreich erstellt: ${IMAGE_PATH}"
    fi
}

# Hauptprogramm
check_root
cleanup
check_dependencies
clone_repo
configure_board
build_image
locate_image

echo "Das OpenSim-Server-Image wurde erfolgreich erstellt: ${IMAGE_PATH}"