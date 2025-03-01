#!/bin/bash

# Script zum Erstellen eines Ubuntu Noble Server-Images für den Orange Pi 3B
# Autor: Manfred Zainhofer
# Version: 1.9

# Variablen
REPO_URL="https://github.com/ManfredAabye/ubuntu-rockchip.git"
REPO_DIR="ubuntu-rockchip"
IMAGE_NAME="ubuntu-noble-orangepi-3b.img"
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
    git clone "${REPO_URL}" "${REPO_DIR}"
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
export COMPATIBLE_FLAVORS=("server")
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

    return 0
}
EOF
    echo "[DEBUG] Board-Konfiguration erfolgreich angepasst."
}

function build_image() {
    echo "[DEBUG] Erstelle Image..."
    ./build.sh --board=orangepi-3b --suite=noble --flavor=server
    if [ $? -eq 0 ]; then
        echo "[DEBUG] Image erfolgreich erstellt."
    else
        echo "[DEBUG] Fehler beim Erstellen des Images."
        exit 1
    fi
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

echo "Das Image wurde erfolgreich erstellt: ${IMAGE_PATH}"