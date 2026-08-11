#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_dir "$KERNEL_SRC"
require_file "$KERNEL_CONFIG"

mkdir -p "$KERNEL_BUILD" "$IMAGES_DIR"

log "Preparando configuração do kernel..."

cp "$KERNEL_CONFIG" "$KERNEL_BUILD/.config"

export KBUILD_BUILD_USER="aureus"
export KBUILD_BUILD_HOST="builder"
export KBUILD_BUILD_TIMESTAMP="$AUREUS_BUILD_TIMESTAMP"
export SOURCE_DATE_EPOCH="$(
    date -d "$AUREUS_BUILD_TIMESTAMP" +%s
)"

make \
    -C "$KERNEL_SRC" \
    O="$KERNEL_BUILD" \
    LOCALVERSION="$KERNEL_LOCALVERSION" \
    olddefconfig

log "Compilando Linux ${KERNEL_VERSION}${KERNEL_LOCALVERSION}..."

make \
    -C "$KERNEL_SRC" \
    O="$KERNEL_BUILD" \
    LOCALVERSION="$KERNEL_LOCALVERSION" \
    -j"$JOBS" \
    bzImage

cp \
    "$KERNEL_BUILD/arch/x86/boot/bzImage" \
    "$KERNEL_IMAGE"

kernel_release="$(
    make \
        --silent \
        -C "$KERNEL_SRC" \
        O="$KERNEL_BUILD" \
        LOCALVERSION="$KERNEL_LOCALVERSION" \
        kernelrelease
)"

success "Kernel compilado: $kernel_release"
success "Imagem: $KERNEL_IMAGE"
