#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1
    pwd
)"

source "$PROJECT_ROOT/versions.env"

DOWNLOADS_DIR="$PROJECT_ROOT/downloads"
SOURCES_DIR="$PROJECT_ROOT/sources"
BUILD_DIR="$PROJECT_ROOT/build"
CONFIGS_DIR="$PROJECT_ROOT/configs"
OVERLAY_DIR="$PROJECT_ROOT/rootfs-overlay"
ISO_OVERLAY_DIR="$PROJECT_ROOT/iso-overlay"

KERNEL_ARCHIVE="$DOWNLOADS_DIR/linux-${KERNEL_VERSION}.tar.xz"
KERNEL_SRC="$SOURCES_DIR/linux-${KERNEL_VERSION}"
KERNEL_BUILD="$BUILD_DIR/kernel"
KERNEL_CONFIG="$CONFIGS_DIR/kernel.config"

BUSYBOX_ARCHIVE="$DOWNLOADS_DIR/busybox-${BUSYBOX_VERSION}.tar.bz2"
BUSYBOX_SRC="$SOURCES_DIR/busybox-${BUSYBOX_VERSION}"
BUSYBOX_BUILD="$BUILD_DIR/busybox"
BUSYBOX_CONFIG="$CONFIGS_DIR/busybox.config"

ROOTFS_BUILD="$BUILD_DIR/rootfs"
INITRAMFS_STAGING="$BUILD_DIR/initramfs-root"
ISO_STAGING="$BUILD_DIR/iso-root"

IMAGES_DIR="$BUILD_DIR/images"
KERNEL_IMAGE="$IMAGES_DIR/bzImage"
INITRAMFS_IMAGE="$IMAGES_DIR/initramfs.cpio.gz"
GRUB_CONFIG="$ISO_OVERLAY_DIR/boot/grub/grub.cfg"
ISO_IMAGE="$IMAGES_DIR/aureus-${AUREUS_VERSION}-${AUREUS_ARCH}.iso"

ISO_VOLUME_ID="AUREUS_${AUREUS_VERSION}"
ISO_VOLUME_ID="${ISO_VOLUME_ID^^}"
ISO_VOLUME_ID="${ISO_VOLUME_ID//./_}"
ISO_VOLUME_ID="${ISO_VOLUME_ID//-/_}"
ISO_VOLUME_ID="${ISO_VOLUME_ID:0:32}"

OVMF_CODE="${OVMF_CODE:-/usr/share/edk2/x64/OVMF_CODE.4m.fd}"
OVMF_VARS_TEMPLATE="${OVMF_VARS_TEMPLATE:-/usr/share/edk2/x64/OVMF_VARS.4m.fd}"
OVMF_RUNTIME_DIR="$BUILD_DIR/firmware"
OVMF_VARS_RUNTIME="$OVMF_RUNTIME_DIR/OVMF_VARS.4m.fd"

JOBS="${JOBS:-$(nproc)}"

log() {
    printf '\033[1;34m[Aureus]\033[0m %s\n' "$*"
}

success() {
    printf '\033[1;32m[Aureus]\033[0m %s\n' "$*"
}

warning() {
    printf '\033[1;33m[Aureus]\033[0m %s\n' "$*" >&2
}

die() {
    printf '\033[1;31m[Aureus ERROR]\033[0m %s\n' "$*" >&2
    exit 1
}

require_file() {
    [[ -f "$1" ]] || die "Arquivo não encontrado: $1"
}

require_dir() {
    [[ -d "$1" ]] || die "Diretório não encontrado: $1"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 \
        || die "Comando obrigatório não encontrado: $1"
}

prepare_directories() {
    mkdir -p \
        "$DOWNLOADS_DIR" \
        "$SOURCES_DIR" \
        "$BUILD_DIR" \
        "$IMAGES_DIR"
}
