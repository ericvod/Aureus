#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

prepare_directories

KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_SERIES}/linux-${KERNEL_VERSION}.tar.xz"
KERNEL_SUMS_URL="https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_SERIES}/sha256sums.asc"

BUSYBOX_URL="https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"

download_if_missing \
    "$KERNEL_URL" \
    "$KERNEL_ARCHIVE"

download_if_missing \
    "$BUSYBOX_URL" \
    "$BUSYBOX_ARCHIVE"

KERNEL_SUMS="$DOWNLOADS_DIR/kernel-${KERNEL_SERIES}-sha256sums.asc"

log "Obtendo checksums do kernel..."

curl \
    --fail \
    --location \
    --output "$KERNEL_SUMS" \
    "$KERNEL_SUMS_URL"

kernel_filename="linux-${KERNEL_VERSION}.tar.xz"

kernel_expected="$(
    awk -v filename="$kernel_filename" \
        '$2 == filename { print $1; exit }' \
        "$KERNEL_SUMS"
)"

[[ -n "$kernel_expected" ]] \
    || die "Checksum oficial do kernel não encontrado."

kernel_actual="$(
    sha256sum "$KERNEL_ARCHIVE" | awk '{ print $1 }'
)"

[[ "$kernel_actual" == "$kernel_expected" ]] \
    || die "Checksum do kernel não corresponde."

success "Checksum do Linux ${KERNEL_VERSION}: OK"

BUSYBOX_SUM="$DOWNLOADS_DIR/busybox-${BUSYBOX_VERSION}.tar.bz2.sha256"

download_if_missing \
    "${BUSYBOX_URL}.sha256" \
    "$BUSYBOX_SUM"

(
    cd "$DOWNLOADS_DIR"
    sha256sum -c "$(basename "$BUSYBOX_SUM")"
)

success "Checksum do BusyBox ${BUSYBOX_VERSION}: OK"

if [[ ! -d "$KERNEL_SRC" ]]; then
    log "Extraindo Linux ${KERNEL_VERSION}..."

    tar \
        --extract \
        --file "$KERNEL_ARCHIVE" \
        --directory "$SOURCES_DIR"
else
    log "Fonte do Linux já extraída."
fi

if [[ ! -d "$BUSYBOX_SRC" ]]; then
    log "Extraindo BusyBox ${BUSYBOX_VERSION}..."

    tar \
        --extract \
        --file "$BUSYBOX_ARCHIVE" \
        --directory "$SOURCES_DIR"
else
    log "Fonte do BusyBox já extraída."
fi

success "Fontes prontas."
