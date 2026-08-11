# Desenvolvimento do Aureus

Este documento descreve o processo utilizado para construir, testar e modificar o Aureus.

Versão atual: **v0.1.0**

## Requisitos

O ambiente atual de desenvolvimento assume um host Linux x86-64.

O projeto foi desenvolvido inicialmente utilizando CachyOS.

As principais ferramentas necessárias incluem:

```text
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
qemu-system-x86_64
```

Execute:

```bash
make doctor
```

para verificar o ambiente.

## Pipeline de build

O processo completo pode ser executado através de:

```bash
make
```

O fluxo atual é:

```text
download
  │
  ├─────────────┐
  ▼             ▼
kernel       BusyBox
                │
                ▼
              rootfs
                │
                ▼
             initramfs
```

Os artefatos finais ficam em:

```text
build/images/
```

## Download

```bash
make download
```

Baixa e verifica as fontes utilizadas pelo projeto.

Atualmente:

```text
Linux 7.1.6
BusyBox 1.38.0
```

Os arquivos compactados ficam em:

```text
downloads/
```

e as fontes extraídas em:

```text
sources/
```

## Kernel

```bash
make kernel
```

A configuração oficial está em:

```text
configs/kernel.config
```

A compilação utiliza uma árvore separada:

```text
build/kernel/
```

O resultado final é copiado para:

```text
build/images/bzImage
```

### Modificando a configuração

Utilize:

```bash
make kernel-menuconfig
```

Ao sair, a configuração resultante é salva novamente em:

```text
configs/kernel.config
```

Esse arquivo deve ser versionado no Git.

## BusyBox

```bash
make busybox
```

A configuração oficial está em:

```text
configs/busybox.config
```

O build ocorre em:

```text
build/busybox/
```

O BusyBox atualmente precisa ser estaticamente linkado.

Verifique com:

```bash
file build/busybox/busybox
```

O resultado deve conter:

```text
statically linked
```

### Modificando a configuração

```bash
make busybox-menuconfig
```

A nova configuração será armazenada em:

```text
configs/busybox.config
```

## Root filesystem

```bash
make rootfs
```

O root filesystem é reconstruído do zero em:

```text
build/rootfs/
```

Ele é formado por:

```text
BusyBox
+
rootfs-overlay/
+
arquivos gerados
```

Nunca faça mudanças importantes diretamente em:

```text
build/rootfs/
```

porque elas serão descartadas no próximo build.

Arquivos permanentes pertencentes ao Aureus devem ser adicionados em:

```text
rootfs-overlay/
```

## Initramfs

```bash
make initramfs
```

Cria:

```text
build/images/initramfs.cpio.gz
```

Uma árvore temporária é usada para inserir device nodes como:

```text
/dev/console
/dev/null
/dev/tty
```

através de `fakeroot`.

O formato utilizado é CPIO `newc`, compactado com gzip.

## Executando

```bash
make run
```

Quando KVM está disponível:

```text
KVM + -cpu host
```

é utilizado.

Caso contrário:

```text
TCG + -cpu max
```

é utilizado como fallback.

É possível forçar o modo:

```bash
QEMU_MODE=kvm make run
```

ou:

```bash
QEMU_MODE=tcg make run
```

## Testes dentro do Aureus

Depois do boot, alguns comandos úteis são:

```bash
uname -a
cat /etc/os-release
cat /proc/version
cat /proc/cmdline
cat /proc/cpuinfo
cat /proc/meminfo
ps
mount
free
```

Para verificar o clocksource:

```bash
cat /sys/devices/system/clocksource/clocksource0/current_clocksource
```

E os clocks disponíveis:

```bash
cat /sys/devices/system/clocksource/clocksource0/available_clocksource
```

## Limpando

### Somente artefatos

```bash
make clean
```

Remove:

```text
build/
```

### Artefatos e fontes extraídas

```bash
make distclean
```

Remove:

```text
build/
sources/
```

### Reconstrução completa

```bash
make purge
```

Remove:

```text
build/
sources/
downloads/
```

Depois:

```bash
make
```

deve reconstruir completamente o sistema.

Esse é um dos testes mais importantes para validar o build system.

## Regra importante

Diretórios gerados nunca devem ser tratados como fonte de verdade.

A relação correta é:

```text
inputs versionados
       +
regras de build
       ↓
artefatos gerados
```

Os principais inputs versionados são:

```text
versions.env
configs/
rootfs-overlay/
scripts/
Makefile
```

## Atualização do kernel

Atualizações de versão devem ser feitas separadamente de mudanças estruturais grandes.

Por exemplo:

```text
7.1.6
↓
7.1.8
```

deve ser uma alteração isolada sempre que possível.

Isso reduz o número de variáveis durante debugging.

## Política de debugging

Durante as primeiras versões, o kernel é executado com:

```text
loglevel=7
```

para manter logs detalhados.

Mensagens informativas como detecção de hardware, utilização de stack ou watchdogs não devem ser tratadas automaticamente como falhas.

Sempre deve ser analisado se houve consequências como:

```text
BUG
Oops
panic
unstable clocksource
segmentation fault
invalid opcode
```

antes de modificar configurações apenas para esconder logs.

## Próximo objetivo

A próxima grande etapa arquitetural é remover a dependência excessiva da toolchain do host.

O objetivo futuro será aproximar o processo de:

```text
Host
  │
  ▼
Toolchain Aureus
  │
  ├── Binutils
  ├── compiler
  ├── Linux headers
  └── libc
       │
       ▼
    userspace Aureus
```

Isso permitirá definir explicitamente a compatibilidade de CPU e ABI do sistema.
