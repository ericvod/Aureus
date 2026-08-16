# Desenvolvimento do Aureus

Este documento descreve como preparar o ambiente, construir, executar, verificar, depurar e versionar o Aureus.

Versão documentada: **v0.2.0**

## Escopo

O ambiente atual de desenvolvimento assume:

- host Linux;
- arquitetura x86-64;
- shell Bash;
- toolchain GNU instalada no host;
- QEMU para os testes principais;
- VirtualBox como teste adicional de compatibilidade.

O projeto foi desenvolvido inicialmente no CachyOS, mas os scripts não dependem intencionalmente de componentes exclusivos dessa distribuição. Os nomes dos pacotes podem variar entre distribuições, porém os executáveis necessários são verificados por `make doctor`.

## Estado da versão

A versão `0.2.0` produz três artefatos principais:

```text
build/images/bzImage
build/images/initramfs.cpio.gz
build/images/aureus-0.2.0-x86_64.iso
```

Os componentes utilizados são:

| Componente | Versão |
|---|---|
| Aureus | 0.2.0 |
| Linux | 7.1.8 |
| BusyBox | 1.38.0 |
| Arquitetura | x86-64 |

As versões são centralizadas em:

```text
versions.env
```

## Requisitos

As principais ferramentas verificadas são:

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
grep
cmp
mktemp
grub-script-check
grub-mkrescue
xorriso
mformat
mkfs.fat
qemu-system-x86_64
```

Para testes UEFI pelo QEMU também são esperados os firmwares:

```text
/usr/share/edk2/x64/OVMF_CODE.4m.fd
/usr/share/edk2/x64/OVMF_VARS.4m.fd
```

Execute:

```bash
make doctor
```

O comando:

1. procura cada executável necessário;
2. verifica se o host utiliza a arquitetura configurada;
3. verifica o acesso a `/dev/kvm`;
4. procura os arquivos do OVMF;
5. encerra com erro quando uma dependência obrigatória está ausente.

A ausência de KVM gera um aviso, mas não bloqueia o build. Nesse caso, o QEMU pode utilizar TCG.

A ausência do OVMF também gera um aviso, pois impede testes UEFI no QEMU, mas não impede a construção da ISO.

## Organização das fontes e artefatos

Os diretórios versionados funcionam como entradas do build:

```text
versions.env
configs/
rootfs-overlay/
iso-overlay/
scripts/
Makefile
```

Os diretórios gerados são:

```text
downloads/
sources/
build/
```

A regra fundamental é:

```text
entradas versionadas
        +
regras de build
        │
        ▼
artefatos derivados
```

Nunca trate um arquivo dentro de `build/` como fonte de verdade.

## Makefile

O Makefile representa as dependências entre as etapas, enquanto os scripts Bash implementam os procedimentos.

Os principais alvos são:

| Alvo | Função |
|---|---|
| `make doctor` | verifica o ambiente |
| `make download` | baixa, verifica e extrai as fontes |
| `make kernel` | compila o kernel |
| `make busybox` | compila o BusyBox |
| `make rootfs` | monta o root filesystem |
| `make initramfs` | gera o initramfs |
| `make` | constrói kernel e initramfs |
| `make iso` | constrói a Live ISO |
| `make verify-iso` | constrói e verifica a ISO |
| `make run` | executa kernel e initramfs diretamente |
| `make run-iso` | executa a Live ISO |
| `make kernel-menuconfig` | configura o kernel |
| `make busybox-menuconfig` | configura o BusyBox |
| `make clean` | remove `build/` |
| `make distclean` | remove `build/` e `sources/` |
| `make purge` | remove `build/`, `sources/` e `downloads/` |

Para exibir essa relação no terminal:

```bash
make help
```

## Pipeline de build

O pipeline completo da ISO é:

```text
download
   │
   ├───────────────────┐
   ▼                   ▼
kernel              BusyBox
   │                   │
   │                   ▼
   │                rootfs
   │                   │
   │                   ▼
   │               initramfs
   │                   │
   └─────────┬─────────┘
             ▼
          Live ISO
             │
             ▼
       verificação da ISO
```

Para construir e verificar todo o caminho:

```bash
make verify-iso
```

## Paralelismo

O número de tarefas paralelas é controlado por:

```text
JOBS
```

O padrão é o resultado de:

```bash
nproc
```

Para limitar a compilação:

```bash
JOBS=4 make iso
```

Isso é útil em máquinas com pouca memória ou quando não se deseja utilizar todos os processadores.

## Download e verificação das fontes

Execute:

```bash
make download
```

O procedimento:

1. cria os diretórios necessários;
2. baixa os arquivos que ainda não existem;
3. obtém ou utiliza os checksums esperados;
4. valida os arquivos baixados;
5. extrai as fontes quando necessário.

Os arquivos compactados ficam em:

```text
downloads/
```

As árvores extraídas ficam em:

```text
sources/linux-7.1.8/
sources/busybox-1.38.0/
```

Downloads existentes e válidos podem ser reutilizados.

Uma falha de checksum deve interromper o processo. Não substitua o checksum apenas para fazer um arquivo desconhecido ser aceito; primeiro confirme a origem, a versão e a integridade do download.

## Kernel

Para compilar:

```bash
make kernel
```

A configuração oficial está em:

```text
configs/kernel.config
```

O build é realizado fora da árvore de fontes:

```text
sources/linux-7.1.8/
          │
          ▼
build/kernel/
```

O artefato final é copiado para:

```text
build/images/bzImage
```

### Modificando a configuração do kernel

Execute:

```bash
make kernel-menuconfig
```

Ao sair do menu, a configuração resultante é salva em:

```text
configs/kernel.config
```

Depois de alterar a configuração:

```bash
make kernel
```

Verifique o resultado com:

```bash
file build/images/bzImage
ls -lh build/images/bzImage
```

### Política para mudanças do kernel

Atualizações de versão devem ser separadas, sempre que possível, de grandes mudanças de configuração.

Por exemplo:

```text
Linux 7.1.8 → nova versão
```

e:

```text
habilitar um novo subsistema de drivers
```

introduzem categorias diferentes de risco. Separá-las reduz o número de variáveis durante o debugging.

## BusyBox

Para compilar:

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

O executável final é:

```text
build/busybox/busybox
```

Verifique o binário:

```bash
file build/busybox/busybox
ls -lh build/busybox/busybox
```

O resultado deve indicar um executável ELF x86-64 estaticamente vinculado.

### Normalização da configuração

O sistema Kconfig do BusyBox pode inserir um comentário com data e hora na configuração gerada.

Esse timestamp não altera as funcionalidades habilitadas, mas produz diferenças desnecessárias no Git. Por isso, a configuração oficial é normalizada sem esse comentário volátil.

O build executa:

```text
oldconfig
```

de forma não interativa e registra a saída em:

```text
build/busybox/oldconfig.log
```

Depois do processamento, a configuração de build deve ser idêntica à configuração oficial:

```bash
cmp -s configs/busybox.config build/busybox/.config
```

Para inspecionar diferenças:

```bash
diff -u configs/busybox.config build/busybox/.config
```

### Modificando a configuração do BusyBox

Execute:

```bash
make busybox-menuconfig
```

A configuração normalizada é salva novamente em:

```text
configs/busybox.config
```

Depois:

```bash
make busybox
```

### Avisos do compilador

O código do BusyBox pode produzir avisos com versões recentes do GCC.

Avisos não devem ser confundidos automaticamente com falhas. A compilação é considerada concluída quando:

- o `make` termina com status zero;
- o link final é concluído;
- o executável é produzido;
- o arquivo é reconhecido como ELF válido;
- a configuração de build corresponde à oficial.

Isso não significa que avisos devam ser ignorados para sempre. Eles devem ser analisados separadamente quando indicarem risco real de incompatibilidade ou comportamento indefinido.

## Root filesystem

Execute:

```bash
make rootfs
```

O root filesystem é reconstruído em:

```text
build/rootfs/
```

Sua composição é:

```text
BusyBox instalado
        +
rootfs-overlay/
        +
arquivos gerados
```

Arquivos permanentes pertencentes ao Aureus devem ser adicionados em:

```text
rootfs-overlay/
```

Não faça alterações importantes diretamente em:

```text
build/rootfs/
```

Elas serão descartadas no próximo build.

### Identificação do sistema

O arquivo:

```text
/etc/os-release
```

é gerado de acordo com `AUREUS_VERSION`.

Para conferir a árvore construída:

```bash
cat build/rootfs/etc/os-release
```

O resultado esperado para esta versão é:

```text
NAME="Aureus"
PRETTY_NAME="Aureus Linux 0.2.0"
ID=aureus
VERSION="0.2.0"
VERSION_ID="0.2.0"
```

## Initramfs

Execute:

```bash
make initramfs
```

O artefato gerado é:

```text
build/images/initramfs.cpio.gz
```

O formato utilizado é:

```text
CPIO newc + gzip
```

Uma árvore temporária é utilizada para preparar o conteúdo e inserir device nodes necessários através de `fakeroot`.

Entre os dispositivos fundamentais estão:

```text
/dev/console
/dev/null
/dev/tty
```

Para conferir o artefato:

```bash
file build/images/initramfs.cpio.gz
ls -lh build/images/initramfs.cpio.gz
```

Para listar seu conteúdo sem extraí-lo no diretório atual:

```bash
gzip -dc build/images/initramfs.cpio.gz \
    | cpio -t \
    | sed -n '1,160p'
```

## Live ISO

Execute:

```bash
make iso
```

O script responsável é:

```text
scripts/build-iso.sh
```

Ele:

1. exige kernel e initramfs existentes;
2. valida a configuração do GRUB;
3. recria `build/iso-root/`;
4. copia `iso-overlay/` para o staging;
5. adiciona kernel e initramfs em `/boot`;
6. executa `grub-mkrescue`;
7. produz primeiro um arquivo `.iso.part`;
8. publica o nome final somente após sucesso;
9. calcula o SHA-256 da imagem.

O resultado é:

```text
build/images/aureus-0.2.0-x86_64.iso
```

Para inspecionar:

```bash
file build/images/aureus-0.2.0-x86_64.iso
ls -lh build/images/aureus-0.2.0-x86_64.iso
sha256sum build/images/aureus-0.2.0-x86_64.iso
```

## Overlay da ISO

Arquivos próprios da mídia ficam em:

```text
iso-overlay/
```

A configuração atual do GRUB está em:

```text
iso-overlay/boot/grub/grub.cfg
```

Para verificar sua sintaxe:

```bash
grub-script-check iso-overlay/boot/grub/grub.cfg
```

O arquivo define:

- uma entrada padrão com `console=tty0`;
- uma entrada de desenvolvimento com `ttyS0` como console principal.

Arquivos gerados, como o kernel e o initramfs, não devem ser copiados manualmente para `iso-overlay/`. O script de build é responsável por inseri-los no staging.

## Verificação estrutural da ISO

Execute:

```bash
make verify-iso
```

O alvo depende de `iso`, portanto constrói uma imagem antes de verificá-la.

O script:

```text
scripts/verify-iso.sh
```

confirma:

- formato ISO 9660;
- ausência de `.iso.part` residual;
- sintaxe válida do GRUB;
- entrada El Torito BIOS;
- entrada El Torito UEFI;
- volume `AUREUS_0_2_0`;
- GRUB2 MBR;
- tabela GPT híbrida;
- kernel correto dentro da ISO;
- initramfs correto dentro da ISO;
- `grub.cfg` correto dentro da ISO.

Kernel, initramfs e GRUB são extraídos temporariamente e comparados byte por byte com os artefatos esperados.

Uma verificação aprovada termina com:

```text
[Aureus] ISO do Aureus 0.2.0 aprovada.
```

## Execução direta pelo QEMU

Execute:

```bash
make run
```

Esse modo utiliza:

```text
build/images/bzImage
build/images/initramfs.cpio.gz
```

e não passa pelo GRUB ou pela ISO.

Use-o para alterações rápidas em:

- kernel;
- configuração do kernel;
- initramfs;
- root filesystem;
- `/init`;
- BusyBox.

## Execução da ISO pelo QEMU

Execute:

```bash
make run-iso
```

O firmware padrão é BIOS.

### BIOS

```bash
QEMU_FIRMWARE=bios make run-iso
```

### UEFI

```bash
QEMU_FIRMWARE=uefi make run-iso
```

No modo UEFI, uma cópia do template de variáveis OVMF é criada em:

```text
build/firmware/OVMF_VARS.4m.fd
```

A cópia é recriada para cada execução. Isso impede que o template instalado no host seja modificado.

## Aceleração do QEMU

O modo padrão é:

```text
QEMU_MODE=auto
```

Quando KVM está acessível:

```text
-accel kvm
-cpu host
```

Caso contrário:

```text
-accel tcg
-cpu max
```

É possível forçar cada modo:

```bash
QEMU_MODE=kvm make run-iso
```

```bash
QEMU_MODE=tcg make run-iso
```

Se KVM for explicitamente solicitado e `/dev/kvm` não estiver acessível, o script encerra com erro em vez de fazer fallback silencioso.

## Recursos da máquina virtual

Os valores padrão são:

```text
QEMU_MEMORY=512M
QEMU_CPUS=2
```

Eles podem ser alterados:

```bash
QEMU_MEMORY=1G QEMU_CPUS=4 make run-iso
```

Também podem ser combinados com firmware e acelerador:

```bash
QEMU_MODE=tcg \
QEMU_FIRMWARE=uefi \
QEMU_MEMORY=1G \
QEMU_CPUS=2 \
make run-iso
```

## Console no QEMU

`scripts/run-iso.sh` utiliza:

```text
-nographic
```

No menu do GRUB, selecione:

```text
Aureus Linux (serial console)
```

Essa entrada utiliza:

```text
console=tty0 console=ttyS0,115200
```

Para encerrar o QEMU:

```text
Ctrl+A, depois X
```

Se a entrada local for iniciada no QEMU `-nographic`, o sistema pode estar funcionando em `tty0`, mas o shell não aparecerá no terminal serial.

## Teste no VirtualBox

O VirtualBox é utilizado como teste adicional de compatibilidade da Live ISO.

Procedimento básico:

1. crie uma VM Linux x86-64;
2. configure pelo menos 512 MiB de memória;
3. configure uma ou mais CPUs;
4. associe a ISO ao drive óptico;
5. não crie um disco virtual quando o objetivo for apenas testar a sessão Live;
6. habilite EFI para testar UEFI;
7. desabilite EFI para testar BIOS;
8. inicie a VM;
9. utilize a entrada padrão `Aureus Linux`.

A entrada padrão utiliza:

```text
console=tty0
```

Não selecione a entrada serial no VirtualBox, a menos que uma porta serial virtual tenha sido configurada e conectada a um destino acessível.

### Reinicialização após selecionar o GRUB

Durante o desenvolvimento, o VirtualBox chegava ao GRUB e reiniciava depois que a entrada era selecionada.

A causa era o uso de:

```text
console=tty0 console=ttyS0,115200
```

em uma VM sem console serial configurado. O shell principal era associado a `ttyS0`; quando a sessão não permanecia acessível, o `/init` seguia para seu caminho de encerramento e reinicialização.

A correção foi manter duas entradas distintas no GRUB e tornar `console=tty0` o padrão.

## Testes dentro do Aureus

Depois do boot, execute:

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

### Firmware

```bash
if [ -d /sys/firmware/efi ]; then
    echo "Firmware: UEFI"
else
    echo "Firmware: BIOS"
fi
```

### Clocksource

```bash
cat /sys/devices/system/clocksource/clocksource0/current_clocksource
cat /sys/devices/system/clocksource/clocksource0/available_clocksource
```

Em KVM, o clocksource normalmente selecionado é:

```text
kvm-clock
```

### Mídia óptica

```bash
ls -l /dev/sr0
blkid /dev/sr0
```

O volume esperado é:

```text
AUREUS_0_2_0
```

Monte a própria ISO:

```bash
mount -t iso9660 -o ro /dev/sr0 /mnt
ls -l /mnt/boot
cat /mnt/boot/grub/grub.cfg
```

## Matriz manual de testes

Antes de uma release, valide pelo menos:

| Ambiente | Comando ou configuração | Entrada do GRUB |
|---|---|---|
| QEMU/KVM BIOS | `QEMU_MODE=kvm QEMU_FIRMWARE=bios make run-iso` | serial |
| QEMU/KVM UEFI | `QEMU_MODE=kvm QEMU_FIRMWARE=uefi make run-iso` | serial |
| QEMU/TCG BIOS | `QEMU_MODE=tcg QEMU_FIRMWARE=bios make run-iso` | serial |
| QEMU/TCG UEFI | `QEMU_MODE=tcg QEMU_FIRMWARE=uefi make run-iso` | serial |
| VirtualBox BIOS | EFI desabilitado | padrão/local |
| VirtualBox UEFI | EFI habilitado | padrão/local |

Quando algum modo não puder ser executado no host atual, registre explicitamente que ele não foi testado. Não trate apenas a presença estrutural da entrada de boot como equivalente a uma inicialização completa.

## Política de debugging

O kernel utiliza:

```text
loglevel=7
```

Mensagens informativas não devem ser tratadas automaticamente como falha.

Procure consequências concretas, como:

```text
BUG
Oops
kernel panic
invalid opcode
segmentation fault
PID 1 terminated
VFS: unable to mount
```

Mensagens como detecção de hardware, atualização de greatest stack depth ou avisos isolados de clocksource devem ser analisadas dentro do contexto antes de modificar a configuração apenas para escondê-las.

## Problemas conhecidos e diagnóstico

### `invalid opcode` no BusyBox

O BusyBox ainda utiliza a toolchain e bibliotecas estáticas do host.

Um binário produzido em um host otimizado pode conter instruções não disponíveis em uma CPU virtual genérica.

Soluções temporárias:

```text
KVM + -cpu host
```

ou:

```text
TCG + -cpu max
```

A solução arquitetural futura é uma toolchain controlada pelo projeto.

### KVM indisponível

Verifique:

```bash
ls -l /dev/kvm
```

O usuário precisa ter permissão de leitura e escrita no dispositivo.

Enquanto isso, utilize:

```bash
QEMU_MODE=tcg make run-iso
```

### OVMF ausente

Execute:

```bash
make doctor
```

Se o OVMF estiver ausente, os testes BIOS continuam disponíveis. Instale o pacote de firmware UEFI correspondente à distribuição do host antes de usar `QEMU_FIRMWARE=uefi`.

### ISO não atualizada

Reconstrua e verifique:

```bash
make verify-iso
```

O verificador compara os arquivos internos com os artefatos atuais e detecta uma ISO contendo kernel, initramfs ou GRUB antigos.

### Arquivo `.iso.part`

A presença de:

```text
aureus-0.2.0-x86_64.iso.part
```

indica que uma construção não foi publicada como imagem final.

O verificador trata esse arquivo residual como erro. Investigue primeiro a saída do `grub-mkrescue`.

### GRUB aparece, mas o shell não

Confirme qual entrada foi escolhida:

- VirtualBox e display local: `Aureus Linux`;
- QEMU `-nographic`: `Aureus Linux (serial console)`.

Também confira:

```text
/proc/cmdline
```

quando for possível alcançar o sistema.

## Limpeza

### Remover somente o build

```bash
make clean
```

Remove:

```text
build/
```

### Remover build e fontes extraídas

```bash
make distclean
```

Remove:

```text
build/
sources/
```

### Remover também downloads

```bash
make purge
```

Remove:

```text
build/
sources/
downloads/
```

As operações de limpeza não devem remover:

```text
configs/
rootfs-overlay/
iso-overlay/
scripts/
docs/
versions.env
Makefile
README.md
```

## Reconstrução limpa

Um teste importante do projeto é:

```bash
make purge
make verify-iso
```

Esse processo valida que o repositório contém todas as informações necessárias para baixar, configurar, compilar, empacotar e verificar o sistema novamente.

Entretanto, o build ainda não é considerado completamente reprodutível byte por byte, pois utiliza a toolchain e bibliotecas do host. O termo adequado no estágio atual é um build automatizado e reconstruível dentro de um ambiente compatível.

## Atualização de versão

As versões devem ser alteradas em:

```text
versions.env
```

Exemplo conceitual:

```text
AUREUS_VERSION=0.2.0
AUREUS_ARCH=x86_64
KERNEL_VERSION=7.1.8
BUSYBOX_VERSION=1.38.0
```

Depois da alteração, verifique todos os locais derivados:

- `/etc/os-release`;
- nome da ISO;
- identificador de volume;
- caminhos das fontes;
- documentação;
- mensagens dos scripts;
- tag Git planejada.

Utilize buscas para identificar referências antigas:

```bash
rg -n '0\.1\.0|7\.1\.6' \
    README.md \
    docs \
    versions.env \
    scripts \
    iso-overlay \
    rootfs-overlay
```

## Verificações antes de commit

Verifique a sintaxe dos scripts:

```bash
bash -n scripts/*.sh scripts/lib/*.sh
```

Verifique o GRUB:

```bash
grub-script-check iso-overlay/boot/grub/grub.cfg
```

Verifique problemas de whitespace:

```bash
git diff --check
```

Inspecione as mudanças:

```bash
git status --short
git --no-pager diff --stat
git --no-pager diff
```

Execute o ambiente e a ISO:

```bash
make doctor
make verify-iso
```

Depois complete a matriz manual de boot aplicável ao ambiente.

## Próxima etapa de desenvolvimento

Depois da Live ISO `0.2.0`, a próxima grande demanda arquitetural é construir uma toolchain controlada.

Essa etapa deverá estudar e definir:

- Binutils;
- compilador;
- headers do Linux;
- biblioteca C;
- ABI x86-64;
- baseline de CPU;
- flags de compilação;
- sysroot;
- separação entre toolchain do host e userspace do Aureus.

O objetivo é substituir a compatibilidade implícita com o host por uma plataforma de build explicitamente definida pelo projeto.
