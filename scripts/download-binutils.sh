#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

prepare_directories

require_command curl
require_command sha512sum
require_command awk
require_command tar

BINUTILS_URL="https://sourceware.org/pub/binutils/releases/binutils-${BINUTILS_VERSION}.tar.xz"
BINUTILS_SUMS_URL="https://sourceware.org/pub/binutils/releases/sha512.sum"

download_if_missing \
    "$BINUTILS_URL" \
    "$BINUTILS_ARCHIVE"

BINUTILS_SUM="$DOWNLOADS_DIR/binutils-${BINUTILS_VERSION}-sha512.sum"

download_if_missing \
    "$BINUTILS_SUMS_URL" \
    "$BINUTILS_SUM"

binutils_filename="binutils-${BINUTILS_VERSION}.tar.xz"

binutils_expected="$(
    awk -v filename="$binutils_filename" \
        '$2 == filename { print $1; exit }' \
        "$BINUTILS_SUM"
)"

[[ -n "$binutils_expected" ]] \
    || die "Checksum oficial do Binutils não encontrado."

binutils_actual="$(
    sha512sum "$BINUTILS_ARCHIVE" | awk '{ print $1 }'
)"

[[ "$binutils_actual" == "$binutils_expected" ]] \
    || die "Checksum do Binutils não corresponde."

success "Checksum do Binutils ${BINUTILS_VERSION}: OK"

if [[ ! -d "$BINUTILS_SRC" ]]; then
    log "Extraindo Binutils ${BINUTILS_VERSION}..."

    tar \
        --extract \
        --file "$BINUTILS_ARCHIVE" \
        --directory "$SOURCES_DIR"
else
    log "Fonte do Binutils já extraída."
fi

success "Fonte do Binutils ${BINUTILS_VERSION} pronta."
