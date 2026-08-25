#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "$0")/lib/common.sh"

AS="$TOOLCHAIN_PREFIX/bin/${AUREUS_TARGET}-as"
LD="$TOOLCHAIN_PREFIX/bin/${AUREUS_TARGET}-ld"
READELF="$TOOLCHAIN_PREFIX/bin/${AUREUS_TARGET}-readelf"
OBJDUMP="$TOOLCHAIN_PREFIX/bin/${AUREUS_TARGET}-objdump"

TEST_DIR="$TOOLCHAIN_DIR/test-binutils"
TEST_SOURCE="$TEST_DIR/exit.S"
TEST_OBJECT="$TEST_DIR/exit.o"
TEST_BINARY="$TEST_DIR/exit"

log "Verificando GNU Binutils ${BINUTILS_VERSION}..."

require_file "$AS"
require_file "$LD"
require_file "$READELF"
require_file "$OBJDUMP"

rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

cat >"$TEST_SOURCE" <<'EOF'
.global _start

.section .text
_start:
    mov $60, %rax
    mov $42, %rdi
    syscall
EOF

log "Montando programa de teste..."

"$AS" \
    "$TEST_SOURCE" \
    -o "$TEST_OBJECT"

require_file "$TEST_OBJECT"

log "Verificando objeto ELF relocável..."

"$READELF" -h "$TEST_OBJECT" \
    | grep -q 'Class:.*ELF64' \
    || die "Objeto não é ELF64."

"$READELF" -h "$TEST_OBJECT" \
    | grep -q 'Type:.*REL' \
    || die "Objeto não é relocável."

"$READELF" -h "$TEST_OBJECT" \
    | grep -q 'Machine:.*X86-64' \
    || die "Objeto não é x86-64."

log "Linkando programa de teste..."

"$LD" \
    -o "$TEST_BINARY" \
    -e _start \
    "$TEST_OBJECT"

require_file "$TEST_BINARY"

log "Verificando executável ELF..."

"$READELF" -h "$TEST_BINARY" \
    | grep -q 'Class:.*ELF64' \
    || die "Executável não é ELF64."

"$READELF" -h "$TEST_BINARY" \
    | grep -q 'Type:.*EXEC' \
    || die "Arquivo final não é executável ELF."

"$READELF" -h "$TEST_BINARY" \
    | grep -q 'Machine:.*X86-64' \
    || die "Executável não é x86-64."

if "$READELF" -l "$TEST_BINARY" | grep -q 'INTERP'; then
    die "Executável possui interpretador dinâmico inesperado."
fi

if "$READELF" -d "$TEST_BINARY" 2>&1 \
    | grep -q 'NEEDED'; then
    die "Executável possui dependências dinâmicas inesperadas."
fi

log "Executando programa de teste..."

set +e
"$TEST_BINARY"
exit_status=$?
set -e

[[ "$exit_status" -eq 42 ]] \
    || die \
        "Programa retornou ${exit_status}; esperado: 42."

success \
    "Binutils ${BINUTILS_VERSION} aprovado para ${AUREUS_TARGET}."

success \
    "Programa ELF mínimo retornou status 42."