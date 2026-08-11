#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_dir "$ROOTFS_BUILD"
require_file "$ROOTFS_BUILD/init"
require_file "$ROOTFS_BUILD/bin/busybox"
require_command fakeroot
require_command cpio
require_command gzip

mkdir -p "$IMAGES_DIR"

log "Preparando árvore temporária do initramfs..."

rm -rf "$INITRAMFS_STAGING"

cp -a \
    "$ROOTFS_BUILD" \
    "$INITRAMFS_STAGING"

epoch="$(
    date -d "$AUREUS_BUILD_TIMESTAMP" +%s
)"

export SOURCE_DATE_EPOCH="$epoch"

log "Criando initramfs..."

fakeroot -- bash -s -- \
    "$INITRAMFS_STAGING" \
    "$AUREUS_BUILD_TIMESTAMP" <<'EOF_FAKEROOT' \
    | gzip -n -9 > "$INITRAMFS_IMAGE"

set -Eeuo pipefail

rootfs="$1"
timestamp="$2"

rm -f \
    "$rootfs/dev/console" \
    "$rootfs/dev/null" \
    "$rootfs/dev/tty"

mknod -m 600 "$rootfs/dev/console" c 5 1
mknod -m 666 "$rootfs/dev/null"    c 1 3
mknod -m 666 "$rootfs/dev/tty"     c 5 0

find "$rootfs" -exec touch -h -d "$timestamp" {} +

cd "$rootfs"

find . -print0 \
    | LC_ALL=C sort -z \
    | cpio \
        --null \
        --create \
        --format=newc \
        --owner=0:0

EOF_FAKEROOT

require_file "$INITRAMFS_IMAGE"

success "Initramfs criado."
success "Imagem: $INITRAMFS_IMAGE"
