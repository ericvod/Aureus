#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_dir "$BUSYBOX_SRC"
require_file "$BUSYBOX_CONFIG"

mkdir -p "$BUSYBOX_BUILD"

cp "$BUSYBOX_CONFIG" "$BUSYBOX_BUILD/.config"

make \
    -C "$BUSYBOX_SRC" \
    O="$BUSYBOX_BUILD" \
    oldconfig

make \
    -C "$BUSYBOX_SRC" \
    O="$BUSYBOX_BUILD" \
    menuconfig

cp "$BUSYBOX_BUILD/.config" "$BUSYBOX_CONFIG"

success "Configuração do BusyBox salva em:"
success "$BUSYBOX_CONFIG"
