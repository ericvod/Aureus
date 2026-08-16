#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_dir "$ISO_OVERLAY_DIR"
require_file "$GRUB_CONFIG"
require_file "$KERNEL_IMAGE"
require_file "$INITRAMFS_IMAGE"

require_command grub-mkrescue
require_command xorriso
require_command mformat
require_command mkfs.fat
require_command sha256sum

[[ "$ISO_STAGING" == "$BUILD_DIR/"* ]] \
    || die "Diretório temporário da ISO fora de build/: $ISO_STAGING"

mkdir -p "$IMAGES_DIR"

log "Preparando árvore temporária da ISO..."

rm -rf "$ISO_STAGING"

mkdir -p "$ISO_STAGING"

cp -a \
    "$ISO_OVERLAY_DIR/." \
    "$ISO_STAGING/"

mkdir -p "$ISO_STAGING/boot"

cp \
    "$KERNEL_IMAGE" \
    "$ISO_STAGING/boot/bzImage"

cp \
    "$INITRAMFS_IMAGE" \
    "$ISO_STAGING/boot/initramfs.cpio.gz"

find "$ISO_STAGING" \
    -exec touch -h -d "$AUREUS_BUILD_TIMESTAMP" {} +

epoch="$(
    date -d "$AUREUS_BUILD_TIMESTAMP" +%s
)"

export SOURCE_DATE_EPOCH="$epoch"

temporary_image="${ISO_IMAGE}.part"

rm -f "$temporary_image"

log "Criando ISO inicializável do Aureus ${AUREUS_VERSION}..."

grub-mkrescue \
    --output="$temporary_image" \
    "$ISO_STAGING" \
    -- \
    -volid "$ISO_VOLUME_ID"

[[ -s "$temporary_image" ]] \
    || die "A imagem ISO não foi criada ou está vazia."

mv \
    "$temporary_image" \
    "$ISO_IMAGE"

iso_sha256="$(
    sha256sum "$ISO_IMAGE" | awk '{ print $1 }'
)"

success "ISO criada."
success "Imagem: $ISO_IMAGE"
success "SHA-256: $iso_sha256"
