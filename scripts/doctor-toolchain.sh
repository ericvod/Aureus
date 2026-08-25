#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

log "Verificando dependências da toolchain..."

commands=(
    gcc
    g++
    make
    awk
    curl
    tar
    xz
    sha512sum
    makeinfo
)

failed=0

for cmd in "${commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf '  [OK] %-22s %s\n' \
            "$cmd" \
            "$(command -v "$cmd")"
    else
        printf '  [ERRO] %s\n' "$cmd"
        failed=1
    fi
done

echo

if [[ "$(uname -m)" != "$AUREUS_ARCH" ]]; then
    warning \
        "Host detectado como $(uname -m); target atual é ${AUREUS_ARCH}."
    failed=1
fi

if (( failed != 0 )); then
    die "O ambiente ainda possui dependências ausentes para a toolchain."
fi

success "Ambiente pronto para construir a toolchain do Aureus."
