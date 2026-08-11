# Arquitetura do Aureus

Este documento descreve a arquitetura técnica atual do Aureus.

Versão documentada: **v0.1.0**

## Visão geral

O Aureus é atualmente um sistema Linux x86-64 mínimo executado através do QEMU/KVM.

Sua arquitetura pode ser dividida em cinco camadas:

```text
┌───────────────────────────────────────────┐
│ Shell / ferramentas                       │
│ BusyBox                                   │
├───────────────────────────────────────────┤
│ Inicialização do userspace                │
│ /init - PID 1                             │
├───────────────────────────────────────────┤
│ Root filesystem inicial                   │
│ initramfs                                 │
├───────────────────────────────────────────┤
│ Kernel                                    │
│ Linux 7.1.6-aureus                        │
├───────────────────────────────────────────┤
│ Hardware virtual                          │
│ QEMU / KVM                                │
└───────────────────────────────────────────┘
```

## Processo de boot

O Aureus ainda não possui um bootloader convencional.

O QEMU carrega diretamente o kernel e o initramfs:

```text
QEMU
 │
 ├── bzImage
 │
 └── initramfs.cpio.gz
 │
 ▼
Linux
```

Os argumentos principais passados ao kernel são:

```text
console=ttyS0
rdinit=/init
loglevel=7
```

### `console=ttyS0`

Define a primeira porta serial como console do kernel.

O uso conjunto de `-nographic` no QEMU permite interagir com o Aureus diretamente pelo terminal do host.

### `rdinit=/init`

Instrui o kernel a executar `/init` como primeiro processo do userspace proveniente do initramfs.

O processo recebe PID 1.

### `loglevel=7`

Mantém o kernel bastante verboso durante a fase atual de desenvolvimento.

Isso facilita observar:

* detecção de hardware;
* inicialização de drivers;
* clocksource;
* montagem do root filesystem;
* execução do PID 1;
* erros de boot.

## Kernel

O kernel utilizado atualmente é:

```text
Linux 7.1.6-aureus
```

A configuração oficial é armazenada em:

```text
configs/kernel.config
```

A árvore original do kernel permanece separada dos artefatos através de um build out-of-tree:

```text
sources/linux-7.1.6/
        │
        ▼
build/kernel/
```

Entre os recursos fundamentais habilitados estão:

* suporte ELF;
* suporte a scripts executáveis;
* initramfs;
* gzip;
* devtmpfs;
* procfs;
* sysfs;
* tmpfs;
* TTY;
* Unix98 PTYs;
* serial 8250;
* console serial.

A compilação utiliza metadados controlados:

```text
KBUILD_BUILD_USER=aureus
KBUILD_BUILD_HOST=builder
```

para reduzir dependência da identidade da máquina utilizada para construir o sistema.

## Initramfs

O root filesystem atual não reside em disco.

A árvore do sistema é empacotada utilizando:

```text
CPIO newc
+
gzip
```

gerando:

```text
build/images/initramfs.cpio.gz
```

O kernel descompacta esse arquivo na memória durante a inicialização.

Consequentemente, todas as alterações realizadas no filesystem em tempo de execução são descartadas após o desligamento.

## Root filesystem

O root filesystem é construído em:

```text
build/rootfs/
```

Sua origem é uma combinação de:

```text
BusyBox instalado
+
rootfs-overlay/
+
arquivos gerados durante o build
```

Arquivos específicos do Aureus ficam em:

```text
rootfs-overlay/
```

enquanto arquivos gerados ou fornecidos pelo BusyBox não são armazenados no Git.

## `/init`

O arquivo:

```text
rootfs-overlay/init
```

torna-se:

```text
/init
```

dentro do Aureus.

Ele é responsável por:

1. definir variáveis básicas de ambiente;
2. montar `devtmpfs`;
3. montar `/proc`;
4. montar `/sys`;
5. montar `/dev/pts`;
6. montar `/dev/shm`;
7. criar `/run`;
8. configurar o hostname;
9. carregar informações de `/etc/os-release`;
10. iniciar o shell.

O shell é iniciado através de:

```text
setsid cttyhack sh -l
```

para obter uma sessão interativa com controlling TTY apropriado.

## BusyBox

BusyBox 1.38.0 fornece atualmente praticamente todo o userspace.

Um único executável:

```text
/bin/busybox
```

implementa diversos applets.

Exemplos:

```text
/bin/sh
/bin/ls
/bin/cat
/bin/mount
/sbin/reboot
```

são links ou entradas associadas ao executável BusyBox.

O BusyBox é construído estaticamente para evitar a necessidade inicial de uma árvore completa de bibliotecas compartilhadas.

## Pseudo-filesystems

Durante a inicialização são montados:

### `/proc`

Fornece informações de processos e estado do kernel.

Exemplos:

```text
/proc/cpuinfo
/proc/meminfo
/proc/cmdline
/proc/1
```

### `/sys`

Expõe dispositivos, drivers, buses, classes e outros objetos do kernel.

### `/dev`

Utiliza `devtmpfs` para disponibilizar dispositivos mantidos pelo kernel.

### `/dev/pts`

Fornece pseudoterminais Unix98.

### `/dev/shm`

Fornece memória compartilhada através de tmpfs.

### `/run`

Utiliza tmpfs para dados temporários de runtime.

## CPU e virtualização

Quando possível, o Aureus utiliza:

```text
KVM
+
-cpu host
```

Caso KVM não esteja disponível:

```text
TCG
+
-cpu max
```

é utilizado.

Essa decisão surgiu após identificar que o BusyBox construído no CachyOS utilizava instruções AVX provenientes da toolchain ou das bibliotecas estáticas do host.

O modelo genérico de CPU usado inicialmente pelo QEMU não suportava essas instruções, causando:

```text
invalid opcode
SIGILL
PID 1 terminated
kernel panic
```

A solução atual é temporária.

Uma futura versão terá uma toolchain controlada pelo Aureus.

## Clocksource

Quando executado com KVM, o kernel atualmente seleciona:

```text
kvm-clock
```

como clocksource principal.

Outras fontes detectadas incluem:

```text
tsc
hpet
acpi_pm
```

Mensagens ocasionais do clocksource watchdog foram observadas durante virtualização SMP, sem que `kvm-clock` fosse marcado como instável.

## Build system

O build é organizado pelo GNU Make.

O Makefile funciona como orquestrador e delega tarefas para scripts Bash.

Fluxo principal:

```text
make
 │
 ├── download
 │
 ├── kernel
 │
 └── initramfs
       │
       └── rootfs
             │
             └── busybox
```

O objetivo é manter:

```text
Make = dependências e orquestração
Bash = procedimentos de build
```

## Artefatos

Os dois principais artefatos gerados atualmente são:

```text
build/images/bzImage
build/images/initramfs.cpio.gz
```

Eles são suficientes para inicializar a versão atual do Aureus através do QEMU.

## Limitações arquiteturais atuais

A arquitetura v0.1.0 ainda possui algumas limitações deliberadas:

* dependência da toolchain do host;
* ausência de filesystem persistente;
* ausência de bootloader;
* ausência de módulos externos organizados;
* ausência de usuários comuns;
* ausência de gerenciamento de serviços;
* ausência de gerenciamento de pacotes;
* ausência de ambiente gráfico.

Essas limitações serão removidas gradualmente conforme novas camadas forem estudadas.
