#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

log "Verificando ambiente de desenvolvimento..."

commands=(
    bash
    make
    gcc
    ld
    bc
    bison
    flex
    openssl
    pahole
    perl
    cpio
    gzip
    xz
    bzip2
    tar
    curl
    sha256sum
    file
    objdump
    fakeroot
    grub-mkrescue
    xorriso
    mformat
    mkfs.fat
    qemu-system-x86_64
)

failed=0

for cmd in "${commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf '  [OK] %-22s %s\n' "$cmd" "$(command -v "$cmd")"
    else
        printf '  [ERRO] %s\n' "$cmd"
        failed=1
    fi
done

echo

arch="$(uname -m)"

if [[ "$arch" != "x86_64" ]]; then
    warning "Host detectado como $arch; Aureus ${AUREUS_VERSION} suporta apenas x86_64."
    failed=1
else
    success "Arquitetura do host: x86_64"
fi

if [[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
    success "KVM disponível."
else
    warning "KVM indisponível para este usuário."
    warning "O Aureus usará QEMU/TCG com '-cpu max'."
fi

echo

if (( failed != 0 )); then
    die "O ambiente ainda possui dependências ausentes."
fi

success "Ambiente pronto para construir o Aureus."
