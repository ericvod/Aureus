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
    grep
    cmp
    mktemp
    grub-script-check
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

if [[ "$arch" != "$AUREUS_ARCH" ]]; then
    warning "Host detectado como $arch; Aureus ${AUREUS_VERSION} espera ${AUREUS_ARCH}."
    failed=1
else
    success "Arquitetura do host: $arch"
fi

if [[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
    success "KVM disponível."
else
    warning "KVM indisponível para este usuário."
    warning "O Aureus usará QEMU/TCG com '-cpu max'."
fi

if [[ -f "$OVMF_CODE" && -f "$OVMF_VARS_TEMPLATE" ]]; then
    success "OVMF disponível para testes UEFI."
else
    warning "OVMF incompleto; testes UEFI pelo QEMU estarão indisponíveis."

    [[ -f "$OVMF_CODE" ]] \
        || warning "Firmware ausente: $OVMF_CODE"

    [[ -f "$OVMF_VARS_TEMPLATE" ]] \
        || warning "Template de variáveis ausente: $OVMF_VARS_TEMPLATE"
fi

echo

if (( failed != 0 )); then
    die "O ambiente ainda possui dependências ausentes."
fi

success "Ambiente pronto para construir o Aureus."
