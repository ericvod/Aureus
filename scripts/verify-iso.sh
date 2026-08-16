#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_file "$ISO_IMAGE"
require_file "$KERNEL_IMAGE"
require_file "$INITRAMFS_IMAGE"
require_file "$GRUB_CONFIG"

require_command file
require_command grep
require_command cmp
require_command mktemp
require_command sha256sum
require_command grub-script-check
require_command xorriso

expected_volume="AUREUS_${AUREUS_VERSION//./_}"

log "Verificando a ISO do Aureus ${AUREUS_VERSION}..."

if [[ ! -s "$ISO_IMAGE" ]]; then
    die "A imagem ISO está vazia: $ISO_IMAGE"
fi

file_output="$(file "$ISO_IMAGE")"

if [[ "$file_output" != *"ISO 9660"* ]]; then
    die "O arquivo não foi reconhecido como uma imagem ISO 9660."
fi

success "Formato ISO 9660 reconhecido."

if [[ -e "${ISO_IMAGE}.part" ]]; then
    die "Arquivo temporário permaneceu após o build: ${ISO_IMAGE}.part"
fi

success "Nenhum arquivo temporário .part permaneceu."

log "Validando a configuração do GRUB..."

grub-script-check "$GRUB_CONFIG"

success "Sintaxe do grub.cfg válida."

log "Inspecionando as estruturas El Torito..."

if ! boot_report="$(
    xorriso \
        -indev "$ISO_IMAGE" \
        -report_el_torito plain \
        2>&1
)"; then
    die "Não foi possível ler as estruturas El Torito da ISO."
fi

if ! grep -Eq \
    'El Torito boot img .* BIOS[[:space:]]+y' \
    <<<"$boot_report"; then
    die "Entrada inicializável para BIOS não encontrada."
fi

success "Boot BIOS encontrado."

if ! grep -Eq \
    'El Torito boot img .* UEFI[[:space:]]+y' \
    <<<"$boot_report"; then
    die "Entrada inicializável para UEFI não encontrada."
fi

success "Boot UEFI encontrado."

if ! grep -Eq \
    "Volume id[[:space:]]*:[[:space:]]*'${expected_volume}'" \
    <<<"$boot_report"; then
    die "Volume esperado não encontrado: $expected_volume"
fi

success "Volume da ISO confirmado: $expected_volume"

log "Inspecionando a área de sistema híbrida..."

if ! system_report="$(
    xorriso \
        -indev "$ISO_IMAGE" \
        -report_system_area plain \
        2>&1
)"; then
    die "Não foi possível ler a área de sistema da ISO."
fi

if ! grep -Eq \
    'System area summary:.*grub2-mbr' \
    <<<"$system_report"; then
    die "Estrutura GRUB2 MBR não encontrada."
fi

success "Estrutura GRUB2 MBR encontrada."

if ! grep -Eq \
    'System area summary:.*GPT' \
    <<<"$system_report"; then
    die "Tabela GPT híbrida não encontrada."
fi

success "Tabela GPT híbrida encontrada."

log "Comparando os arquivos armazenados na ISO..."

verification_dir="$(mktemp -d)"
kernel_from_iso="$verification_dir/bzImage"
initramfs_from_iso="$verification_dir/initramfs.cpio.gz"
grub_from_iso="$verification_dir/grub.cfg"

cleanup() {
    rm -f -- \
        "$kernel_from_iso" \
        "$initramfs_from_iso" \
        "$grub_from_iso"

    rmdir -- "$verification_dir" 2>/dev/null || true
}

trap cleanup EXIT

if ! xorriso \
    -osirrox on \
    -indev "$ISO_IMAGE" \
    -extract /boot/bzImage "$kernel_from_iso" \
    -extract /boot/initramfs.cpio.gz "$initramfs_from_iso" \
    -extract /boot/grub/grub.cfg "$grub_from_iso" \
    >/dev/null 2>&1; then
    die "Não foi possível extrair os arquivos da ISO para verificação."
fi

if ! cmp -s "$KERNEL_IMAGE" "$kernel_from_iso"; then
    die "O kernel armazenado na ISO é diferente de $KERNEL_IMAGE."
fi

success "Kernel da ISO confirmado."

if ! cmp -s "$INITRAMFS_IMAGE" "$initramfs_from_iso"; then
    die "O initramfs armazenado na ISO é diferente de $INITRAMFS_IMAGE."
fi

success "Initramfs da ISO confirmado."

if ! cmp -s "$GRUB_CONFIG" "$grub_from_iso"; then
    die "O grub.cfg armazenado na ISO é diferente de $GRUB_CONFIG."
fi

success "Configuração do GRUB confirmada."

read -r iso_sha256 _ < <(sha256sum "$ISO_IMAGE")

echo
success "ISO do Aureus ${AUREUS_VERSION} aprovada."
log "Imagem: $ISO_IMAGE"
log "SHA-256: $iso_sha256"
