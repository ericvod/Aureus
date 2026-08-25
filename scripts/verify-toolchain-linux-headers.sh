#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

INCLUDE_DIR="$TOOLCHAIN_SYSROOT/usr/include"

log "Verificando Linux UAPI headers ${KERNEL_VERSION}..."

require_dir "$INCLUDE_DIR"
require_dir "$INCLUDE_DIR/linux"
require_dir "$INCLUDE_DIR/asm"
require_dir "$INCLUDE_DIR/asm-generic"

required_headers=(
    "linux/types.h"
    "linux/errno.h"
    "linux/ioctl.h"
    "linux/socket.h"
    "asm/types.h"
    "asm/unistd.h"
    "asm-generic/types.h"
)

for header in "${required_headers[@]}"; do
    require_file "$INCLUDE_DIR/$header"
done

require_file "$LINUX_HEADERS_STAMP"

header_count="$(
    find "$INCLUDE_DIR" \
        -type f \
        -name '*.h' \
        | wc -l
)"

[[ "$header_count" -gt 100 ]] \
    || die \
        "Quantidade inesperadamente pequena de headers: ${header_count}"

success \
    "Linux UAPI headers ${KERNEL_VERSION} aprovados."

success \
    "${header_count} headers exportados para o sysroot."
