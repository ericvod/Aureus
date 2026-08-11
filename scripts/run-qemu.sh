#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

require_file "$KERNEL_IMAGE"
require_file "$INITRAMFS_IMAGE"
require_command qemu-system-x86_64

memory="${QEMU_MEMORY:-512M}"
cpus="${QEMU_CPUS:-2}"
mode="${QEMU_MODE:-auto}"

cpu_args=()

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

        cpu_args=(
            -accel kvm
            -cpu host
        )
        ;;

    tcg)
        cpu_args=(
            -accel tcg
            -cpu max
        )
        ;;

    *)
        die "QEMU_MODE inválido: $mode. Use auto, kvm ou tcg."
        ;;
esac

log "Iniciando Aureus ${AUREUS_VERSION}..."

exec qemu-system-x86_64 \
    -machine q35 \
    "${cpu_args[@]}" \
    -m "$memory" \
    -smp "$cpus" \
    -kernel "$KERNEL_IMAGE" \
    -initrd "$INITRAMFS_IMAGE" \
    -append "console=ttyS0 rdinit=/init loglevel=7" \
    -nographic \
    -no-reboot
