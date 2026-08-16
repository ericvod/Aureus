# Arquitetura do Aureus

Este documento descreve a arquitetura técnica do Aureus na versão **v0.2.0**.

## Objetivo arquitetural

O Aureus é uma distribuição Linux x86-64 minimalista e educacional. A arquitetura atual foi deliberadamente mantida pequena para que o caminho completo entre o firmware e o primeiro shell possa ser estudado, construído e verificado pelo próprio projeto.

A versão `0.2.0` introduz uma camada de inicialização convencional baseada em GRUB e uma Live ISO híbrida, sem abandonar o caminho de boot direto utilizado durante o desenvolvimento da versão anterior.

Os princípios atuais são:

- manter os componentes explícitos;
- separar arquivos-fonte de artefatos gerados;
- automatizar procedimentos repetíveis;
- validar cada fronteira do processo de boot;
- preservar um caminho rápido para depuração;
- adicionar novas camadas somente quando sua função estiver compreendida.

## Visão geral

A arquitetura da Live ISO pode ser dividida nas seguintes camadas:

```text
┌─────────────────────────────────────────────┐
│ Shell e utilitários                         │
│ BusyBox 1.38.0                              │
├─────────────────────────────────────────────┤
│ Inicialização do userspace                  │
│ /init como PID 1                            │
├─────────────────────────────────────────────┤
│ Root filesystem inicial                     │
│ initramfs CPIO newc + gzip                  │
├─────────────────────────────────────────────┤
│ Kernel                                      │
│ Linux 7.1.8-aureus                          │
├─────────────────────────────────────────────┤
│ Bootloader                                  │
│ GRUB 2                                      │
├─────────────────────────────────────────────┤
│ Firmware                                    │
│ BIOS legado ou UEFI                         │
├─────────────────────────────────────────────┤
│ Hardware                                    │
│ QEMU/KVM, QEMU/TCG ou VirtualBox            │
└─────────────────────────────────────────────┘
```

## Caminhos de inicialização

O Aureus mantém dois caminhos de boot com finalidades diferentes.

### Boot direto

O comando:

```bash
make run
```

faz o QEMU carregar diretamente:

```text
build/images/bzImage
build/images/initramfs.cpio.gz
```

O fluxo é:

```text
QEMU
  │
  ├── carrega bzImage
  ├── carrega initramfs.cpio.gz
  └── fornece a linha de comando do kernel
               │
               ▼
             Linux
               │
               ▼
             /init
```

Esse caminho não testa:

- o firmware da máquina virtual;
- a imagem ISO;
- o catálogo El Torito;
- o GRUB;
- a seleção BIOS ou UEFI.

Ele permanece disponível porque reduz o número de camadas envolvidas durante a depuração do kernel, do initramfs e do PID 1.

### Boot pela Live ISO

O comando:

```bash
make run-iso
```

utiliza a imagem:

```text
build/images/aureus-0.2.0-x86_64.iso
```

O fluxo completo é:

```text
Hardware virtual
       │
       ▼
BIOS ou UEFI
       │
       ▼
Estrutura inicializável da ISO
       │
       ▼
GRUB
       │
       ├── /boot/bzImage
       └── /boot/initramfs.cpio.gz
                    │
                    ▼
             Linux 7.1.8-aureus
                    │
                    ▼
               rdinit=/init
                    │
                    ▼
               /init - PID 1
                    │
                    ▼
              BusyBox shell
```

Esse é o caminho usado para validar a distribuição como mídia inicializável.

## Live ISO híbrida

A ISO é construída por:

```text
scripts/build-iso.sh
```

O script combina:

```text
iso-overlay/
    +
build/images/bzImage
    +
build/images/initramfs.cpio.gz
    +
módulos e imagens gerados pelo GRUB
```

O diretório temporário da imagem é:

```text
build/iso-root/
```

O resultado final é:

```text
build/images/aureus-0.2.0-x86_64.iso
```

O identificador de volume é:

```text
AUREUS_0_2_0
```

### Estruturas de boot

A imagem contém:

- catálogo El Torito;
- imagem El Torito para BIOS;
- imagem El Torito para UEFI;
- GRUB2 MBR;
- tabela de partições GPT híbrida;
- partição de sistema EFI incorporada.

Uma única imagem pode, portanto, ser apresentada a uma máquina BIOS ou UEFI.

O suporte estrutural não implica suporte a Secure Boot. Os componentes atuais não são assinados e o projeto utiliza o OVMF convencional, sem habilitar a variante de Secure Boot.

### Escrita atômica da imagem

Durante a criação, o destino temporário utiliza a extensão:

```text
.iso.part
```

O nome final somente é atribuído após a conclusão bem-sucedida do `grub-mkrescue`.

O fluxo é:

```text
aureus-0.2.0-x86_64.iso.part
                 │
                 ├── falha: não é publicada como ISO final
                 │
                 └── sucesso
                        │
                        ▼
             aureus-0.2.0-x86_64.iso
```

Essa estratégia evita que uma construção interrompida deixe um arquivo incompleto com o nome de um artefato válido.

## GRUB

A configuração versionada está em:

```text
iso-overlay/boot/grub/grub.cfg
```

Ela define duas entradas de boot.

### Console local

```text
Aureus Linux
```

Utiliza:

```text
console=tty0 rdinit=/init loglevel=7
```

Essa é a entrada padrão e atende a:

- VirtualBox;
- QEMU com display gráfico;
- máquinas com monitor;
- futuras validações em hardware físico.

`tty0` é o console virtual local do kernel. Ele não representa um ambiente gráfico, Wayland ou desktop.

### Console serial

```text
Aureus Linux (serial console)
```

Utiliza:

```text
console=tty0 console=ttyS0,115200 rdinit=/init loglevel=7
```

O kernel envia mensagens aos consoles configurados. Como `ttyS0` é o último console declarado, `/dev/console` fica associado à porta serial nesse cenário.

Essa entrada atende a:

- QEMU com `-nographic`;
- depuração por porta serial;
- ambientes sem console de vídeo interativo.

### Motivo das duas entradas

A configuração anterior utilizava sempre:

```text
console=tty0 console=ttyS0,115200
```

Ela funcionava corretamente no QEMU com console serial, mas fazia o PID 1 iniciar o shell em `ttyS0` também no VirtualBox. Sem uma porta serial virtual conectada, o shell não permanecia acessível pela janela da VM e o encerramento da sessão levava o `/init` ao caminho de reinicialização.

A separação das entradas tornou explícita a escolha do console e preservou os dois ambientes de teste.

## BIOS

No modo BIOS, o firmware encontra a estrutura El Torito para plataforma BIOS e transfere o controle ao GRUB.

O teste pelo QEMU utiliza, por padrão:

```bash
QEMU_FIRMWARE=bios make run-iso
```

Como BIOS é o valor padrão, o comando pode ser reduzido para:

```bash
make run-iso
```

Dentro do Aureus, a ausência do diretório:

```text
/sys/firmware/efi
```

indica que o kernel não foi inicializado por UEFI.

## UEFI e OVMF

O teste UEFI pelo QEMU utiliza OVMF.

Os arquivos esperados são:

```text
/usr/share/edk2/x64/OVMF_CODE.4m.fd
/usr/share/edk2/x64/OVMF_VARS.4m.fd
```

O firmware é fornecido ao QEMU através de duas unidades PFlash:

- `OVMF_CODE.4m.fd` é aberto somente para leitura;
- uma cópia de `OVMF_VARS.4m.fd` é aberta para escrita.

A cópia utilizada durante a execução fica em:

```text
build/firmware/OVMF_VARS.4m.fd
```

O template instalado no host nunca é modificado diretamente.

O teste é iniciado com:

```bash
QEMU_FIRMWARE=uefi make run-iso
```

Depois do boot, a presença de:

```text
/sys/firmware/efi
```

confirma que o kernel foi inicializado em modo UEFI.

## Kernel

O kernel utilizado é:

```text
Linux 7.1.8-aureus
```

A configuração oficial é armazenada em:

```text
configs/kernel.config
```

O código-fonte e a árvore de build permanecem separados:

```text
sources/linux-7.1.8/
          │
          ▼
build/kernel/
          │
          ▼
build/images/bzImage
```

Entre os recursos fundamentais utilizados pela arquitetura estão:

- formato executável ELF;
- suporte a scripts executáveis;
- initramfs;
- descompactação gzip;
- devtmpfs;
- procfs;
- sysfs;
- tmpfs;
- TTY e consoles virtuais;
- pseudoterminais Unix98;
- serial 8250/16550;
- console serial;
- filesystem ISO 9660;
- dispositivos de mídia óptica virtuais;
- suporte necessário ao ambiente QEMU e VirtualBox.

O sufixo local identifica o kernel como pertencente ao projeto:

```text
-aureus
```

Metadados de compilação controlados reduzem a dependência da identidade da máquina de build.

## Linha de comando do kernel

Os parâmetros comuns são:

```text
rdinit=/init loglevel=7
```

### `rdinit=/init`

Instrui o kernel a executar `/init` como primeiro processo do userspace carregado a partir do initramfs.

Esse processo recebe PID 1.

### `loglevel=7`

Mantém mensagens detalhadas durante a fase atual de desenvolvimento.

Isso permite observar:

- detecção de CPU e memória;
- inicialização de dispositivos;
- seleção de clocksource;
- montagem do root filesystem inicial;
- execução do PID 1;
- falhas antes do início do shell.

O nível é uma decisão de desenvolvimento e poderá ser reduzido em versões destinadas a uso cotidiano.

## Initramfs

O root filesystem inicial é empacotado como:

```text
CPIO newc
    +
gzip
```

O artefato é:

```text
build/images/initramfs.cpio.gz
```

O kernel descompacta seu conteúdo diretamente na memória.

Não existe atualmente:

- partição raiz em disco;
- `switch_root`;
- persistência das alterações;
- separação entre initramfs de emergência e root filesystem definitivo.

O initramfs é, ao mesmo tempo, o ambiente inicial e o sistema em execução.

## Construção do root filesystem

O root filesystem é montado em:

```text
build/rootfs/
```

Ele resulta da combinação:

```text
BusyBox instalado
        +
rootfs-overlay/
        +
arquivos gerados durante o build
```

Arquivos próprios do sistema ficam em:

```text
rootfs-overlay/
```

Arquivos derivados, applets instalados e metadados gerados ficam apenas dentro de `build/`.

A identificação em `/etc/os-release` é gerada a partir da versão central definida em:

```text
versions.env
```

Isso mantém o nome da ISO, o volume, o userspace e a documentação de release alinhados à versão `0.2.0`.

## PID 1

O arquivo versionado:

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
2. preparar os diretórios necessários;
3. montar `devtmpfs` em `/dev`;
4. montar `proc` em `/proc`;
5. montar `sysfs` em `/sys`;
6. montar `devpts` em `/dev/pts`;
7. montar `tmpfs` em `/dev/shm`;
8. preparar `/run`;
9. configurar o hostname;
10. carregar informações de `/etc/os-release`;
11. iniciar um shell BusyBox interativo.

O shell é iniciado através de:

```text
setsid cttyhack sh -l
```

`setsid` cria uma nova sessão e `cttyhack` associa o processo ao terminal de controle selecionado pelo kernel.

Quando o shell principal termina, o script executa seu caminho de encerramento e reinicialização. Essa implementação é intencionalmente simples, mas ainda não oferece supervisão de serviços, múltiplas sessões ou tratamento avançado de sinais próprio de um sistema init completo.

## BusyBox

BusyBox `1.38.0` fornece a maior parte do userspace.

O executável principal é:

```text
/bin/busybox
```

Applets como:

```text
/bin/sh
/bin/ls
/bin/cat
/bin/mount
/sbin/reboot
```

são disponibilizados a partir desse executável.

O BusyBox é construído estaticamente para evitar, nesta etapa, uma árvore completa de bibliotecas compartilhadas dentro do initramfs.

### Configuração

A configuração oficial está em:

```text
configs/busybox.config
```

O build:

1. copia a configuração oficial para a árvore de build;
2. executa `oldconfig` de forma não interativa;
3. registra a saída em `build/busybox/oldconfig.log`;
4. compila o executável estático.

O timestamp volátil produzido pelo Kconfig foi removido da configuração oficial. Dessa forma, a mesma configuração não gera diferenças apenas por ter sido processada em outro dia.

## Pseudo-filesystems

### `/dev`

Utiliza `devtmpfs` para expor dispositivos mantidos pelo kernel.

Exemplos observados incluem:

```text
/dev/console
/dev/tty
/dev/tty0
/dev/ttyS0
/dev/sr0
```

### `/proc`

Fornece informações sobre processos e estado do kernel:

```text
/proc/cmdline
/proc/cpuinfo
/proc/meminfo
/proc/version
/proc/1
```

### `/sys`

Expõe dispositivos, drivers, barramentos, classes e informações de firmware.

O diretório `/sys/firmware/efi` é utilizado para distinguir boots UEFI de boots BIOS.

### `/dev/pts`

Fornece pseudoterminais Unix98.

### `/dev/shm`

Fornece memória compartilhada baseada em tmpfs.

### `/run`

Armazena dados temporários de runtime e também reside em memória.

## Mídia óptica

Quando a Live ISO é apresentada como CD-ROM virtual, o kernel expõe normalmente:

```text
/dev/sr0
```

O dispositivo pode ser identificado por:

```bash
blkid /dev/sr0
```

e montado somente para leitura:

```bash
mount -t iso9660 -o ro /dev/sr0 /mnt
```

Isso permite verificar, a partir do próprio Aureus, os arquivos usados em seu boot:

```text
/mnt/boot/bzImage
/mnt/boot/initramfs.cpio.gz
/mnt/boot/grub/grub.cfg
```

## CPU e virtualização

O modo automático do QEMU escolhe:

```text
KVM + -cpu host
```

quando `/dev/kvm` está acessível.

Caso contrário, utiliza:

```text
TCG + -cpu max
```

O comportamento pode ser selecionado por:

```text
QEMU_MODE=auto
QEMU_MODE=kvm
QEMU_MODE=tcg
```

Essa escolha também contorna uma limitação atual: o BusyBox estático ainda depende da toolchain e das bibliotecas do host. Binários construídos em um host otimizado podem utilizar instruções ausentes em modelos genéricos de CPU virtual.

Durante o desenvolvimento, essa condição foi observada como:

```text
invalid opcode
SIGILL
PID 1 terminated
kernel panic
```

Uma toolchain controlada pelo Aureus substituirá essa solução em uma versão futura.

## Sistema de build

O GNU Make atua como orquestrador e os scripts Bash implementam as tarefas.

O fluxo principal é:

```text
make iso
   │
   ▼
download
   │
   ├───────────────┐
   ▼               ▼
kernel          BusyBox
   │               │
   │               ▼
   │            rootfs
   │               │
   │               ▼
   │           initramfs
   │               │
   └───────┬───────┘
           ▼
      Live ISO
```

A divisão de responsabilidades é:

```text
Makefile = dependências e orquestração
scripts/ = procedimentos de construção e execução
configs/ = configuração oficial dos componentes
overlays = arquivos próprios do sistema e da ISO
build/   = artefatos derivados
```

## Variáveis e caminhos centrais

As versões são definidas em:

```text
versions.env
```

Os caminhos compartilhados são definidos em:

```text
scripts/lib/common.sh
```

Entre as variáveis centrais estão:

```text
AUREUS_VERSION
AUREUS_ARCH
KERNEL_VERSION
BUSYBOX_VERSION
KERNEL_IMAGE
INITRAMFS_IMAGE
ISO_IMAGE
ISO_OVERLAY_DIR
ISO_STAGING
GRUB_CONFIG
OVMF_CODE
OVMF_VARS_TEMPLATE
OVMF_VARS_RUNTIME
```

Centralizar essas definições evita que scripts diferentes construam nomes ou caminhos incompatíveis.

## Verificação estrutural da ISO

O script:

```text
scripts/verify-iso.sh
```

é executado por:

```bash
make verify-iso
```

A verificação confirma:

1. que o arquivo existe e não está vazio;
2. que é reconhecido como ISO 9660;
3. que nenhum `.iso.part` permaneceu;
4. que o `grub.cfg` possui sintaxe válida;
5. que existe uma entrada El Torito BIOS inicializável;
6. que existe uma entrada El Torito UEFI inicializável;
7. que o volume é `AUREUS_0_2_0`;
8. que existe uma estrutura GRUB2 MBR;
9. que existe uma tabela GPT híbrida;
10. que o kernel da ISO é idêntico ao artefato de build;
11. que o initramfs da ISO é idêntico ao artefato de build;
12. que o `grub.cfg` da ISO é idêntico ao arquivo versionado.

Os arquivos internos são extraídos para um diretório temporário e comparados byte por byte.

Essa verificação detecta casos em que uma ISO aparentemente válida contém artefatos antigos ou diferentes dos resultados atuais do build.

## Artefatos principais

Os artefatos finais são:

```text
build/images/bzImage
build/images/initramfs.cpio.gz
build/images/aureus-0.2.0-x86_64.iso
```

Artefatos auxiliares incluem:

```text
build/busybox/busybox
build/busybox/oldconfig.log
build/rootfs/
build/initramfs-root/
build/iso-root/
build/firmware/OVMF_VARS.4m.fd
```

Nenhum arquivo dentro de `build/` deve ser tratado como fonte de verdade.

## Matriz atual de validação

A versão `0.2.0` foi validada nos seguintes cenários:

| Hipervisor | Firmware | Console | Resultado |
|---|---|---|---|
| QEMU/KVM | BIOS | serial | inicialização confirmada |
| QEMU/KVM | UEFI/OVMF | serial | inicialização confirmada |
| QEMU/TCG | BIOS ou UEFI/OVMF | serial | fallback implementado; deve permanecer na validação de release |
| VirtualBox | firmware selecionado na VM | `tty0` | inicialização confirmada após a correção do console |

A validação em hardware físico ainda não faz parte da matriz oficial.

## Limitações arquiteturais

A arquitetura `0.2.0` ainda possui limitações deliberadas:

- dependência da toolchain do host;
- BusyBox estaticamente vinculado à libc do host;
- ausência de root filesystem persistente;
- ausência de `switch_root`;
- ausência de gerenciamento de serviços;
- PID 1 baseado em um script simples;
- ausência de usuários comuns e autenticação;
- shell de root sem senha;
- ausência de rede configurada em userspace;
- ausência de sistema de pacotes;
- ausência de instalador;
- ausência de Secure Boot;
- suporte a hardware físico ainda não validado amplamente;
- ausência de ambiente gráfico.

Essas limitações fazem parte do estágio educacional atual e definem as próximas fronteiras de evolução.

## Próximo marco arquitetural

O próximo grande objetivo é reduzir a dependência do host através de uma toolchain controlada pelo Aureus.

O fluxo pretendido é:

```text
Host Linux
    │
    ▼
Toolchain controlada
    │
    ├── Binutils
    ├── compilador
    ├── headers do Linux
    └── biblioteca C
             │
             ▼
      userspace do Aureus
```

Essa etapa permitirá definir explicitamente:

- baseline x86-64;
- conjunto de instruções permitido;
- ABI;
- versão e configuração da libc;
- flags de compilação;
- compatibilidade entre máquinas;
- maior reprodutibilidade dos binários.

Depois dessa fundação, o projeto poderá evoluir com menor dependência das características do sistema utilizado para construí-lo.
