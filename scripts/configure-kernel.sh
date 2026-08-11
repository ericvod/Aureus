#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_dir "$KERNEL_SRC"
require_file "$KERNEL_CONFIG"

mkdir -p "$KERNEL_BUILD"

cp "$KERNEL_CONFIG" "$KERNEL_BUILD/.config"

make \
    -C "$KERNEL_SRC" \
    O="$KERNEL_BUILD" \
    LOCALVERSION="$KERNEL_LOCALVERSION" \
    olddefconfig

make \
    -C "$KERNEL_SRC" \
    O="$KERNEL_BUILD" \
    LOCALVERSION="$KERNEL_LOCALVERSION" \
    menuconfig

cp "$KERNEL_BUILD/.config" "$KERNEL_CONFIG"

success "Configuração do kernel salva em:"
success "$KERNEL_CONFIG"
