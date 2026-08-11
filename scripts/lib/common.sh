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

IMAGES_DIR="$BUILD_DIR/images"
KERNEL_IMAGE="$IMAGES_DIR/bzImage"
INITRAMFS_IMAGE="$IMAGES_DIR/initramfs.cpio.gz"

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
