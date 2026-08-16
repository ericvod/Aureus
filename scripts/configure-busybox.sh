#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_dir "$BUSYBOX_SRC"
require_file "$BUSYBOX_CONFIG"

mkdir -p "$BUSYBOX_BUILD"

export KCONFIG_NOTIMESTAMP=1

cp "$BUSYBOX_CONFIG" "$BUSYBOX_BUILD/.config"

config_log="$BUSYBOX_BUILD/oldconfig.log"

if ! make \
    -C "$BUSYBOX_SRC" \
    O="$BUSYBOX_BUILD" \
    oldconfig \
    </dev/null \
    >"$config_log" 2>&1; then

    cat "$config_log" >&2
    die "Falha ao atualizar a configuração do BusyBox."
fi

make \
    -C "$BUSYBOX_SRC" \
    O="$BUSYBOX_BUILD" \
    menuconfig

cp "$BUSYBOX_BUILD/.config" "$BUSYBOX_CONFIG"

success "Configuração do BusyBox salva em:"
success "$BUSYBOX_CONFIG"
