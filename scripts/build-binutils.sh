#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

prepare_directories

require_dir "$BINUTILS_SRC"
require_command make
require_command gcc

log "Construindo GNU Binutils ${BINUTILS_VERSION}..."
log "Target: $AUREUS_TARGET"
log "Prefix: $TOOLCHAIN_PREFIX"
log "Sysroot: $TOOLCHAIN_SYSROOT"

#
# Evita que flags configuradas pelo usuário no host contaminem
# a construção da toolchain.
#
unset CFLAGS
unset CXXFLAGS
unset CPPFLAGS
unset LDFLAGS

#
# O build do Binutils é realizado fora da árvore de fontes.
#
rm -rf "$BINUTILS_BUILD"
mkdir -p "$BINUTILS_BUILD"

(
    cd "$BINUTILS_BUILD"

    "$BINUTILS_SRC/configure" \
        --target="$AUREUS_TARGET" \
        --prefix="$TOOLCHAIN_PREFIX" \
        --with-sysroot="$TOOLCHAIN_SYSROOT" \
        --disable-nls \
        --disable-werror \
        --disable-gprofng \
        --enable-deterministic-archives

    make -j"$JOBS"

    make install
)

tools=(
    ar
    as
    ld
    nm
    objcopy
    objdump
    ranlib
    readelf
    strip
)

for tool in "${tools[@]}"; do
    require_file \
        "$TOOLCHAIN_PREFIX/bin/${AUREUS_TARGET}-${tool}"
done

success "GNU Binutils ${BINUTILS_VERSION} construído com sucesso."
success "Target: ${AUREUS_TARGET}"

"$TOOLCHAIN_PREFIX/bin/${AUREUS_TARGET}-as" --version \
    | sed -n '1,2p'