#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_file "$ISO_IMAGE"
require_command qemu-system-x86_64

memory="${QEMU_MEMORY:-512M}"
cpus="${QEMU_CPUS:-2}"
mode="${QEMU_MODE:-auto}"
firmware="${QEMU_FIRMWARE:-bios}"

cpu_args=()
firmware_args=()

case "$mode" in
    auto)
        if [[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
            log "Usando KVM com CPU host."

            cpu_args=(
                -accel kvm
                -cpu host
            )
        else
            warning "KVM indisponível; utilizando TCG com CPU max."

            cpu_args=(
                -accel tcg
                -cpu max
            )
        fi
        ;;

    kvm)
        [[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]] \
            || die "KVM solicitado, mas /dev/kvm não está acessível."

        log "Usando KVM com CPU host."

        cpu_args=(
            -accel kvm
            -cpu host
        )
        ;;

    tcg)
        log "Usando TCG com CPU max."

        cpu_args=(
            -accel tcg
            -cpu max
        )
        ;;

    *)
        die "QEMU_MODE inválido: $mode. Use auto, kvm ou tcg."
        ;;
esac

case "$firmware" in
    bios)
        log "Firmware selecionado: BIOS."
        ;;

    uefi)
        require_file "$OVMF_CODE"
        require_file "$OVMF_VARS_TEMPLATE"

        mkdir -p "$OVMF_RUNTIME_DIR"

        log "Preparando variáveis temporárias do OVMF..."

        cp \
            "$OVMF_VARS_TEMPLATE" \
            "$OVMF_VARS_RUNTIME"

        firmware_args=(
            -drive
            "if=pflash,format=raw,unit=0,readonly=on,file=$OVMF_CODE"
            -drive
            "if=pflash,format=raw,unit=1,file=$OVMF_VARS_RUNTIME"
        )

        log "Firmware selecionado: UEFI/OVMF."
        ;;

    *)
        die "QEMU_FIRMWARE inválido: $firmware. Use bios ou uefi."
        ;;
esac

log "Iniciando a ISO do Aureus ${AUREUS_VERSION} em modo ${firmware^^}..."

exec qemu-system-x86_64 \
    -machine q35 \
    "${cpu_args[@]}" \
    "${firmware_args[@]}" \
    -m "$memory" \
    -smp "$cpus" \
    -boot order=d \
    -cdrom "$ISO_IMAGE" \
    -nographic \
    -no-reboot
