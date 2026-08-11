#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_dir "$BUSYBOX_BUILD"
require_file "$BUSYBOX_BUILD/busybox"
require_dir "$OVERLAY_DIR"

log "Criando root filesystem..."

rm -rf "$ROOTFS_BUILD"

mkdir -p "$ROOTFS_BUILD"

make \
    -C "$BUSYBOX_SRC" \
    O="$BUSYBOX_BUILD" \
    CONFIG_PREFIX="$ROOTFS_BUILD" \
    install

mkdir -p \
    "$ROOTFS_BUILD/dev/pts" \
    "$ROOTFS_BUILD/dev/shm" \
    "$ROOTFS_BUILD/etc" \
    "$ROOTFS_BUILD/proc" \
    "$ROOTFS_BUILD/sys" \
    "$ROOTFS_BUILD/tmp" \
    "$ROOTFS_BUILD/run" \
    "$ROOTFS_BUILD/root" \
    "$ROOTFS_BUILD/mnt"

cp -a "$OVERLAY_DIR/." "$ROOTFS_BUILD/"

cat > "$ROOTFS_BUILD/etc/os-release" <<EOF_OS_RELEASE
NAME="Aureus"
PRETTY_NAME="Aureus Linux ${AUREUS_VERSION}"
ID=aureus
VERSION="${AUREUS_VERSION}"
VERSION_ID="${AUREUS_VERSION}"
EOF_OS_RELEASE

chmod 0755 "$ROOTFS_BUILD/init"
chmod 1777 "$ROOTFS_BUILD/tmp"

require_file "$ROOTFS_BUILD/bin/busybox"
require_file "$ROOTFS_BUILD/init"
require_file "$ROOTFS_BUILD/etc/os-release"

[[ -e "$ROOTFS_BUILD/bin/sh" ]] \
    || die "/bin/sh não foi instalado pelo BusyBox."

success "Root filesystem criado."
success "Diretório: $ROOTFS_BUILD"
