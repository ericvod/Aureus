#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_dir "$BUSYBOX_SRC"
require_file "$BUSYBOX_CONFIG"

mkdir -p "$BUSYBOX_BUILD"

log "Preparando configuração do BusyBox..."

cp "$BUSYBOX_CONFIG" "$BUSYBOX_BUILD/.config"

make \
    -C "$BUSYBOX_SRC" \
    O="$BUSYBOX_BUILD" \
    oldconfig

log "Compilando BusyBox ${BUSYBOX_VERSION}..."

make \
    -C "$BUSYBOX_SRC" \
    O="$BUSYBOX_BUILD" \
    -j"$JOBS"

require_file "$BUSYBOX_BUILD/busybox"

if ! file "$BUSYBOX_BUILD/busybox" | grep -q 'statically linked'; then
    die "BusyBox não foi compilado estaticamente."
fi

success "BusyBox compilado."
success "Binário: $BUSYBOX_BUILD/busybox"
