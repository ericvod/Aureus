#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

prepare_directories

require_dir "$KERNEL_SRC"
require_command make

if [[ -f "$LINUX_HEADERS_STAMP" ]]; then
    log "Linux UAPI headers ${KERNEL_VERSION} já instalados."
    exit 0
fi

log "Instalando Linux UAPI headers ${KERNEL_VERSION}..."
log "Arquitetura: ${AUREUS_ARCH}"
log "Sysroot: ${TOOLCHAIN_SYSROOT}"

#
# Se estivermos instalando uma nova versão dos headers antes da libc,
# começamos com uma árvore de include limpa.
#
rm -rf "$LINUX_HEADERS_BUILD"
mkdir -p "$LINUX_HEADERS_BUILD"

rm -rf "$TOOLCHAIN_SYSROOT/usr/include"

make \
    -C "$KERNEL_SRC" \
    O="$LINUX_HEADERS_BUILD" \
    ARCH="$AUREUS_ARCH" \
    headers_install \
    INSTALL_HDR_PATH="$TOOLCHAIN_SYSROOT/usr"

require_dir "$TOOLCHAIN_SYSROOT/usr/include/linux"
require_dir "$TOOLCHAIN_SYSROOT/usr/include/asm"
require_dir "$TOOLCHAIN_SYSROOT/usr/include/asm-generic"

rm -f "$TOOLCHAIN_DIR"/.linux-headers-*

touch "$LINUX_HEADERS_STAMP"

success "Linux UAPI headers ${KERNEL_VERSION} instalados."
