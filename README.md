# Aureus

**Aureus** é uma distribuição Linux minimalista criada como projeto educacional para estudar, na prática, as camadas que formam um sistema Linux.

O objetivo inicial não é competir com distribuições como Arch Linux, Debian, Fedora ou Alpine. O projeto busca construir gradualmente um sistema pequeno, compreensível e controlado, adicionando novos componentes à medida que eles são estudados.

A filosofia do projeto é:

> Construir primeiro o menor sistema que conseguimos entender completamente e evoluí-lo gradualmente.

## Estado atual

A versão atual é:

**Aureus v0.2.0**

O Aureus atualmente consegue:

- inicializar diretamente pelo QEMU;
- inicializar por uma Live ISO;
- utilizar GRUB como bootloader;
- inicializar em modo BIOS legado;
- inicializar em modo UEFI;
- executar em QEMU/KVM;
- executar em QEMU/TCG;
- executar no VirtualBox;
- carregar um kernel compilado especificamente para o projeto;
- carregar um initramfs próprio;
- executar um `/init` próprio como PID 1;
- montar os principais pseudo-filesystems do Linux;
- executar um userspace baseado em BusyBox;
- disponibilizar um shell interativo;
- utilizar console local e console serial;
- utilizar múltiplas CPUs virtuais;
- detectar dispositivos virtuais básicos;
- identificar-se através de `/etc/os-release`;
- verificar automaticamente a estrutura da ISO;
- ser reconstruído através de um sistema de build automatizado.

## Componentes

A versão `0.2.0` utiliza:

| Componente | Versão ou configuração |
|---|---|
| Sistema | Aureus 0.2.0 |
| Arquitetura | x86-64 |
| Kernel | Linux 7.1.8-aureus |
| Userspace | BusyBox 1.38.0 |
| Bootloader | GRUB 2 |
| Root filesystem | initramfs em memória |
| Formato da imagem | ISO 9660 híbrida |
| Firmware suportado | BIOS e UEFI |
| Virtualização principal | QEMU/KVM e QEMU/TCG |
| Virtualização adicional | VirtualBox |

## Processo de inicialização

O boot através da Live ISO segue este fluxo:

```text
BIOS ou UEFI
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
                  ├── monta /dev
                  ├── monta /proc
                  ├── monta /sys
                  ├── monta /dev/pts
                  ├── monta /dev/shm
                  ├── prepara /run
                  ├── configura hostname
                  └── inicia o shell
                           │
                           ▼
                       BusyBox
                           │
                           ▼
                  [root@aureus]#
```

O sistema ainda vive inteiramente no initramfs.

Não existe, nesta versão, uma transição para outro root filesystem através de `switch_root`. Consequentemente, todas as alterações realizadas durante a execução são perdidas quando a máquina é desligada ou reiniciada.

## Live ISO

A imagem gerada possui o formato:

```text
build/images/aureus-0.2.0-x86_64.iso
```

O identificador de volume é:

```text
AUREUS_0_2_0
```

A ISO contém:

```text
/boot/bzImage
/boot/initramfs.cpio.gz
/boot/grub/grub.cfg
```

O `grub-mkrescue` adiciona os módulos e as estruturas necessárias para inicialização.

A imagem possui:

- catálogo El Torito;
- entrada inicializável para BIOS;
- entrada inicializável para UEFI;
- GRUB2 MBR;
- tabela GPT híbrida;
- partição de inicialização EFI.

A estrutura híbrida permite que a mesma imagem seja apresentada a firmwares BIOS e UEFI. A inicialização em hardware físico e a gravação em dispositivos USB ainda não fazem parte da matriz oficial de testes da versão `0.2.0`.

## Entradas do GRUB

O menu possui duas opções:

### `Aureus Linux`

Utiliza:

```text
console=tty0
```

Essa é a entrada padrão e deve ser usada em:

- VirtualBox;
- máquinas virtuais com janela gráfica;
- computadores com monitor;
- futuras validações em hardware físico.

Nesse contexto, `tty0` representa o console virtual local do Linux. Isso não significa que o Aureus já possui uma interface gráfica ou ambiente desktop.

### `Aureus Linux (serial console)`

Utiliza:

```text
console=tty0 console=ttyS0,115200
```

Essa entrada é destinada a:

- QEMU com `-nographic`;
- depuração através de porta serial;
- ambientes sem uma janela gráfica.

Como `ttyS0` aparece por último, ela se torna o console principal associado a `/dev/console`.

## Estrutura do projeto

```text
aureus/
├── Makefile
├── README.md
├── versions.env
├── configs/
│   ├── kernel.config
│   └── busybox.config
├── docs/
│   ├── architecture.md
│   └── development.md
├── iso-overlay/
│   └── boot/
│       └── grub/
│           └── grub.cfg
├── rootfs-overlay/
│   ├── init
│   └── etc/
├── scripts/
│   ├── lib/
│   │   └── common.sh
│   ├── doctor.sh
│   ├── download.sh
│   ├── build-kernel.sh
│   ├── build-busybox.sh
│   ├── build-rootfs.sh
│   ├── build-initramfs.sh
│   ├── build-iso.sh
│   ├── verify-iso.sh
│   ├── run-qemu.sh
│   ├── run-iso.sh
│   ├── configure-kernel.sh
│   └── configure-busybox.sh
├── downloads/
├── sources/
└── build/
```

### `configs/`

Contém as configurações oficiais utilizadas para construir os componentes:

```text
configs/kernel.config
configs/busybox.config
```

Esses arquivos fazem parte da definição versionada do Aureus.

### `rootfs-overlay/`

Contém arquivos que pertencem diretamente ao root filesystem:

```text
/init
/etc/hostname
/etc/passwd
/etc/group
/etc/profile
```

Arquivos fornecidos automaticamente pelo BusyBox não são armazenados nesse diretório.

### `iso-overlay/`

Contém arquivos próprios da imagem ISO.

Atualmente, o principal arquivo é:

```text
iso-overlay/boot/grub/grub.cfg
```

Kernel, initramfs e módulos do GRUB são adicionados durante o build e não são versionados nesse diretório.

### `scripts/`

Contém os procedimentos de download, construção, execução e verificação.

O Makefile atua como orquestrador, enquanto os scripts Bash implementam cada procedimento.

### `downloads/`

Contém os arquivos originais baixados dos projetos upstream.

É um diretório gerado e não deve ser versionado.

### `sources/`

Contém o código-fonte extraído do Linux e do BusyBox.

Também é gerado automaticamente.

### `build/`

Contém os resultados da compilação e os arquivos temporários.

Exemplos:

```text
build/kernel/
build/busybox/
build/rootfs/
build/initramfs-root/
build/iso-root/
build/firmware/
build/images/bzImage
build/images/initramfs.cpio.gz
build/images/aureus-0.2.0-x86_64.iso
```

Todo o diretório pode ser removido e reconstruído.

## Requisitos

O ambiente de desenvolvimento atual assume um host Linux x86-64.

Entre as ferramentas verificadas estão:

- Bash;
- GNU Make;
- GCC;
- GNU Binutils;
- BC;
- Bison;
- Flex;
- OpenSSL;
- pahole;
- Perl;
- CPIO;
- gzip;
- xz;
- bzip2;
- tar;
- curl;
- fakeroot;
- GRUB;
- xorriso;
- mtools;
- dosfstools;
- QEMU;
- utilitários básicos do sistema.

Para verificar o ambiente:

```bash
make doctor
```

O firmware OVMF é opcional para a construção da ISO, mas necessário para executar testes UEFI pelo QEMU.

## Construindo o Aureus

### Baixar e verificar as fontes

```bash
make download
```

### Compilar somente o kernel

```bash
make kernel
```

### Compilar somente o BusyBox

```bash
make busybox
```

### Construir o root filesystem

```bash
make rootfs
```

### Gerar o initramfs

```bash
make initramfs
```

### Construir kernel e initramfs

```bash
make
```

### Construir a Live ISO

```bash
make iso
```

O build da ISO utiliza um arquivo temporário com a extensão:

```text
.iso.part
```

A imagem somente assume o nome final após o `grub-mkrescue` terminar com sucesso. Isso evita que uma compilação interrompida deixe uma ISO incompleta aparentando ser válida.

Ao final, o script apresenta o caminho da imagem e seu SHA-256.

## Verificando a ISO

Execute:

```bash
make verify-iso
```

Esse alvo constrói a ISO e verifica:

- reconhecimento como ISO 9660;
- ausência de arquivo `.part`;
- sintaxe do `grub.cfg`;
- entrada El Torito BIOS;
- entrada El Torito UEFI;
- identificador de volume;
- presença do GRUB2 MBR;
- presença da tabela GPT;
- integridade do kernel armazenado na ISO;
- integridade do initramfs armazenado na ISO;
- integridade da configuração do GRUB.

Os arquivos são extraídos temporariamente da ISO e comparados byte por byte com os artefatos produzidos pelo build.

## Executando diretamente pelo QEMU

O comando:

```bash
make run
```

inicializa diretamente:

```text
bzImage + initramfs.cpio.gz
```

Esse caminho não utiliza a ISO nem o GRUB. Ele continua disponível por ser mais rápido durante o desenvolvimento do kernel, do initramfs e do userspace.

Quando KVM está disponível, o projeto utiliza:

```text
KVM + CPU host
```

Caso contrário, utiliza:

```text
QEMU TCG + CPU max
```

É possível escolher explicitamente:

```bash
QEMU_MODE=kvm make run
```

ou:

```bash
QEMU_MODE=tcg make run
```

## Executando a Live ISO pelo QEMU

Para iniciar com BIOS:

```bash
make run-iso
```

ou explicitamente:

```bash
QEMU_FIRMWARE=bios make run-iso
```

Para iniciar com UEFI/OVMF:

```bash
QEMU_FIRMWARE=uefi make run-iso
```

Também é possível combinar firmware e acelerador:

```bash
QEMU_MODE=tcg QEMU_FIRMWARE=uefi make run-iso
```

As principais variáveis aceitas são:

| Variável | Valores | Padrão |
|---|---|---|
| `QEMU_MODE` | `auto`, `kvm`, `tcg` | `auto` |
| `QEMU_FIRMWARE` | `bios`, `uefi` | `bios` |
| `QEMU_MEMORY` | tamanho aceito pelo QEMU | `512M` |
| `QEMU_CPUS` | quantidade de CPUs | `2` |

Exemplo:

```bash
QEMU_MEMORY=1G QEMU_CPUS=4 QEMU_FIRMWARE=uefi make run-iso
```

O modo UEFI utiliza:

```text
/usr/share/edk2/x64/OVMF_CODE.4m.fd
/usr/share/edk2/x64/OVMF_VARS.4m.fd
```

O template de variáveis não é alterado diretamente. Uma cópia temporária é criada em:

```text
build/firmware/OVMF_VARS.4m.fd
```

Como `run-iso.sh` utiliza `-nographic`, selecione no GRUB:

```text
Aureus Linux (serial console)
```

Para encerrar o QEMU em modo `-nographic`, utilize:

```text
Ctrl+A, depois X
```

## Executando no VirtualBox

Para testar no VirtualBox:

1. crie uma máquina virtual Linux x86-64;
2. não é necessário criar um disco virtual para a Live ISO;
3. associe a ISO ao drive óptico virtual;
4. utilize pelo menos 512 MiB de memória;
5. utilize uma ou mais CPUs virtuais;
6. habilite EFI para testar UEFI;
7. desabilite EFI para testar BIOS;
8. inicie a máquina;
9. selecione a entrada padrão `Aureus Linux`.

A entrada serial não deve ser utilizada no VirtualBox, a menos que uma porta serial virtual tenha sido configurada explicitamente.

## Comandos de validação dentro do Aureus

Depois do boot:

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

Para identificar o firmware:

```bash
if [ -d /sys/firmware/efi ]; then
    echo "Firmware: UEFI"
else
    echo "Firmware: BIOS"
fi
```

Para verificar a mídia óptica:

```bash
blkid /dev/sr0
```

O resultado deve conter:

```text
LABEL="AUREUS_0_2_0"
TYPE="iso9660"
```

A ISO pode ser montada dentro do próprio Aureus:

```bash
mount -t iso9660 -o ro /dev/sr0 /mnt
ls -l /mnt/boot
cat /mnt/boot/grub/grub.cfg
```

## Configuração do kernel

Para abrir o menu de configuração:

```bash
make kernel-menuconfig
```

A configuração resultante é salva em:

```text
configs/kernel.config
```

## Configuração do BusyBox

Para abrir o menu de configuração:

```bash
make busybox-menuconfig
```

A configuração resultante é salva em:

```text
configs/busybox.config
```

O build executa `oldconfig` de forma não interativa para resolver símbolos da configuração.

O timestamp volátil gerado pelo sistema Kconfig é removido da configuração oficial. Isso evita diferenças sem significado entre builds executados em datas diferentes.

## Limpando o projeto

### Remover artefatos de build

```bash
make clean
```

Remove:

```text
build/
```

### Remover artefatos e fontes extraídas

```bash
make distclean
```

Remove:

```text
build/
sources/
```

### Remover também os downloads

```bash
make purge
```

Remove:

```text
build/
sources/
downloads/
```

Depois de um `make purge`, o projeto pode ser reconstruído com:

```bash
make iso
```

## Limitações atuais

O Aureus `0.2.0` ainda não possui:

- filesystem persistente;
- instalador;
- sistema de pacotes;
- gerenciamento de serviços;
- usuários comuns e autenticação completa;
- configuração de rede em userspace;
- toolchain própria;
- biblioteca C controlada pelo projeto;
- ambiente gráfico;
- Wayland;
- window manager;
- áudio;
- Bluetooth;
- suporte a Secure Boot;
- matriz abrangente de hardware físico.

A sessão atual concede um shell de root sem autenticação e deve ser utilizada somente em ambientes de desenvolvimento e aprendizado.

## Toolchain

O BusyBox ainda é construído estaticamente utilizando a toolchain e as bibliotecas estáticas do sistema host.

Durante o desenvolvimento foi observado que binários produzidos no CachyOS podiam conter instruções AVX não suportadas pelo modelo genérico de CPU utilizado inicialmente pelo QEMU.

O problema foi identificado através de uma exceção `invalid opcode` no BusyBox.

A solução atual utiliza:

```text
KVM + CPU host
```

ou:

```text
TCG + CPU max
```

Essa é uma solução temporária. Uma versão futura utilizará uma toolchain controlada pelo Aureus e uma baseline explícita de arquitetura.

## Roadmap

Os próximos objetivos incluem:

1. construir uma toolchain independente do host;
2. definir uma baseline de CPU e ABI para x86-64;
3. evoluir o PID 1 e o gerenciamento de processos;
4. adicionar consoles e sessões através de um mecanismo semelhante a `getty`;
5. adicionar um root filesystem persistente;
6. adicionar suporte a disco e filesystem ext4;
7. configurar rede em userspace;
8. adicionar usuários e autenticação;
9. estudar e desenvolver um sistema de pacotes;
10. criar um instalador;
11. ampliar os testes em hardware físico;
12. estudar Secure Boot;
13. introduzir Wayland;
14. adicionar um window manager minimalista;
15. evoluir o Aureus para uma distribuição desktop personalizável.

## Documentação adicional

Detalhes técnicos estão disponíveis em:

```text
docs/architecture.md
docs/development.md
```

## Filosofia

O Aureus prioriza:

- minimalismo;
- compreensão do sistema;
- componentes explícitos;
- automação reproduzível;
- modularidade;
- personalização;
- aprendizado por implementação.

Funcionalidades são adicionadas quando possuem valor educacional ou arquitetural claro para o projeto.

## Licença

A licença do código próprio do Aureus ainda será definida.

Componentes externos, incluindo Linux, BusyBox e GRUB, continuam sujeitos às suas respectivas licenças.