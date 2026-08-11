# Aureus

**Aureus** é uma distribuição Linux minimalista criada do zero como projeto educacional para estudar, na prática, as camadas que compõem um sistema Linux.

O projeto não tem como objetivo inicial competir com distribuições como Arch Linux, Debian, Fedora ou Alpine. Seu propósito é construir gradualmente um sistema pequeno, compreensível e controlado, adicionando componentes à medida que eles são estudados.

A filosofia do projeto é:

> Construir primeiro o menor sistema que conseguimos entender completamente e evoluí-lo gradualmente.

## Estado atual

A versão atual é:

**Aureus v0.1.0**

O Aureus atualmente consegue:

* inicializar em uma máquina virtual QEMU/KVM;
* executar um kernel Linux compilado especificamente para o projeto;
* carregar um initramfs próprio;
* iniciar um `/init` próprio como PID 1;
* montar os principais pseudo-filesystems do Linux;
* executar um userspace baseado em BusyBox;
* disponibilizar um shell interativo;
* utilizar múltiplas CPUs virtuais;
* detectar dispositivos virtuais básicos;
* utilizar console serial;
* identificar-se através de `/etc/os-release`;
* ser reconstruído através de um sistema de build automatizado.

A versão atual utiliza:

* Linux 7.1.6;
* BusyBox 1.38.0;
* arquitetura x86-64;
* QEMU/KVM para virtualização.

## Arquitetura atual

A inicialização do Aureus funciona aproximadamente assim:

```text
QEMU / KVM
    │
    ▼
Linux 7.1.6-aureus
    │
    ▼
initramfs
    │
    ▼
/init
PID 1
    │
    ├── monta /dev
    ├── monta /proc
    ├── monta /sys
    ├── monta /dev/pts
    ├── monta /dev/shm
    ├── configura hostname
    └── inicia o shell
            │
            ▼
        BusyBox
            │
            ▼
    [root@aureus]#
```

O sistema ainda vive inteiramente em memória.

Ao desligar a máquina virtual, alterações realizadas dentro do Aureus são perdidas.

## Estrutura do projeto

```text
aureus/
├── Makefile
├── README.md
├── versions.env
├── configs/
├── docs/
├── rootfs-overlay/
├── scripts/
├── downloads/
├── sources/
└── build/
```

Os diretórios possuem responsabilidades diferentes.

### `configs/`

Contém as configurações oficiais utilizadas para construir os componentes do sistema.

Atualmente:

```text
configs/kernel.config
configs/busybox.config
```

Esses arquivos fazem parte da definição do Aureus e são versionados.

### `rootfs-overlay/`

Contém arquivos pertencentes diretamente ao Aureus e que serão copiados para o root filesystem durante o build.

Entre eles:

```text
/init
/etc/hostname
/etc/passwd
/etc/group
/etc/profile
```

Arquivos fornecidos automaticamente pelo BusyBox não são armazenados nesse diretório.

### `scripts/`

Contém os scripts responsáveis pela construção e execução do sistema.

Entre eles:

```text
doctor.sh
download.sh
build-kernel.sh
build-busybox.sh
build-rootfs.sh
build-initramfs.sh
run-qemu.sh
```

### `downloads/`

Contém os tarballs originais baixados dos projetos upstream.

Esse diretório é gerado e não faz parte do repositório Git.

### `sources/`

Contém o código-fonte extraído do Linux e do BusyBox.

Também é gerado automaticamente.

### `build/`

Contém todos os resultados da compilação.

Exemplos:

```text
build/kernel/
build/busybox/
build/rootfs/
build/images/bzImage
build/images/initramfs.cpio.gz
```

Todo o diretório pode ser removido e reconstruído.

## Dependências

O ambiente de desenvolvimento atual é baseado em Arch Linux/CachyOS x86-64.

Entre as ferramentas necessárias estão:

* Bash;
* GCC;
* Binutils;
* GNU Make;
* Bison;
* Flex;
* OpenSSL;
* libelf;
* pahole;
* CPIO;
* gzip;
* xz;
* bzip2;
* curl;
* fakeroot;
* QEMU.

O projeto possui uma verificação automática:

```bash
make doctor
```

## Construindo o Aureus

Para baixar as fontes:

```bash
make download
```

Para construir somente o kernel:

```bash
make kernel
```

Para construir somente o BusyBox:

```bash
make busybox
```

Para construir o root filesystem:

```bash
make rootfs
```

Para gerar o initramfs:

```bash
make initramfs
```

Para construir todo o sistema:

```bash
make
```

## Executando

O comando principal é:

```bash
make run
```

Ele constrói o sistema, caso necessário, e inicia o Aureus através do QEMU.

Quando KVM está disponível, o projeto prefere:

```text
KVM + CPU host
```

Caso contrário, utiliza:

```text
QEMU TCG + CPU max
```

Essa escolha é particularmente importante na versão atual porque o BusyBox ainda é construído utilizando componentes da toolchain do sistema host.

## Limpando o projeto

Remover somente artefatos de build:

```bash
make clean
```

Remover também as fontes extraídas:

```bash
make distclean
```

Remover build, fontes e downloads:

```bash
make purge
```

Depois de:

```bash
make purge
```

o Aureus pode ser reconstruído novamente com:

```bash
make
```

## Configuração

O kernel pode ser configurado através de:

```bash
make kernel-menuconfig
```

As alterações são salvas em:

```text
configs/kernel.config
```

O BusyBox pode ser configurado através de:

```bash
make busybox-menuconfig
```

As alterações são salvas em:

```text
configs/busybox.config
```

Esses arquivos são parte da definição versionada do sistema.

## Root filesystem atual

A versão atual possui uma estrutura semelhante a:

```text
/
├── bin/
├── dev/
├── etc/
├── mnt/
├── proc/
├── root/
├── run/
├── sbin/
├── sys/
├── tmp/
└── usr/
```

Pseudo-filesystems como `/proc`, `/sys` e `/dev` são montados durante a inicialização.

## PID 1

O Aureus utiliza atualmente um script próprio:

```text
/init
```

como PID 1.

Ele é responsável pela inicialização básica do userspace e posteriormente inicia um shell BusyBox.

Essa solução é intencionalmente simples e será evoluída nas próximas versões.

## Limitações atuais

Aureus v0.1.0 ainda não possui:

* disco persistente;
* bootloader próprio;
* boot UEFI convencional;
* sistema de pacotes;
* usuários comuns e autenticação completa;
* gerenciamento de serviços;
* configuração de rede em userspace;
* toolchain própria;
* ambiente gráfico;
* Wayland;
* window manager;
* áudio;
* Bluetooth;
* instalador.

O sistema atualmente é voltado exclusivamente para desenvolvimento e aprendizado.

## Toolchain

Uma limitação importante da versão atual é que o BusyBox ainda utiliza a toolchain e bibliotecas estáticas do sistema host.

Durante o desenvolvimento foi observado que binários construídos no CachyOS continham instruções AVX que não eram suportadas pelo modelo genérico de CPU utilizado inicialmente pelo QEMU.

O problema foi identificado através de uma exceção `invalid opcode` dentro do BusyBox e solucionado temporariamente executando a VM com uma CPU compatível.

Essa experiência motivou uma das próximas etapas do projeto: construir uma toolchain controlada pelo próprio Aureus.

## Roadmap

Os próximos objetivos incluem:

1. criar uma toolchain independente do sistema host;
2. definir uma baseline de arquitetura x86-64 para o Aureus;
3. criar um root filesystem persistente;
4. adicionar um disco virtual e filesystem ext4;
5. evoluir o processo PID 1;
6. implementar serviços básicos;
7. adicionar usuários e login;
8. configurar rede;
9. estudar e desenvolver um sistema de pacotes;
10. adicionar um bootloader;
11. suportar boot UEFI;
12. introduzir Wayland;
13. adicionar um window manager minimalista;
14. evoluir o Aureus para uma distribuição desktop personalizável.

## Filosofia

O Aureus prioriza:

* minimalismo;
* compreensão do sistema;
* componentes explícitos;
* automação reproduzível;
* modularidade;
* personalização;
* aprendizado por implementação.

Funcionalidades são adicionadas somente quando há valor educacional ou arquitetural claro para o projeto.

## Licença

A licença do código próprio do Aureus ainda será definida.

Componentes externos, incluindo Linux e BusyBox, continuam sujeitos às suas respectivas licenças.
