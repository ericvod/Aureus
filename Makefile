SHELL := /bin/bash

.DEFAULT_GOAL := all

JOBS ?= $(shell nproc)

.PHONY: \
	all \
	doctor \
	download \
	kernel \
	busybox \
	rootfs \
	initramfs \
	iso \
	verify-iso \
	run \
	run-iso \
	kernel-menuconfig \
	busybox-menuconfig \
	clean \
	distclean \
	purge \
	help

all: kernel initramfs

doctor:
	@./scripts/doctor.sh

download:
	@./scripts/download.sh

kernel: download
	@JOBS="$(JOBS)" ./scripts/build-kernel.sh

busybox: download
	@JOBS="$(JOBS)" ./scripts/build-busybox.sh

rootfs: busybox
	@./scripts/build-rootfs.sh

initramfs: rootfs
	@./scripts/build-initramfs.sh

iso: all
	@./scripts/build-iso.sh

verify-iso: iso
	@./scripts/verify-iso.sh

run: all
	@./scripts/run-qemu.sh

run-iso: iso
	@./scripts/run-iso.sh

kernel-menuconfig: download
	@./scripts/configure-kernel.sh

busybox-menuconfig: download
	@./scripts/configure-busybox.sh

clean:
	@echo "[Aureus] Removendo artefatos de build..."
	@rm -rf build

distclean: clean
	@echo "[Aureus] Removendo fontes extraídas..."
	@rm -rf sources

purge: distclean
	@echo "[Aureus] Removendo downloads..."
	@rm -rf downloads

help:
	@echo "Aureus build system"
	@echo
	@echo "Targets:"
	@echo "  make doctor             Verifica dependências do host"
	@echo "  make download           Baixa e extrai as fontes"
	@echo "  make kernel             Compila o kernel"
	@echo "  make busybox            Compila o BusyBox"
	@echo "  make rootfs             Monta o root filesystem"
	@echo "  make initramfs          Gera o initramfs"
	@echo "  make                    Constrói o kernel e o initramfs"
	@echo "  make iso                Gera a Live ISO inicializável"
	@echo "  make verify-iso         Constrói e verifica a Live ISO"
	@echo "  make run                Constrói e inicia pelo boot direto"
	@echo "  make run-iso            Constrói e inicia a Live ISO"
	@echo "  make kernel-menuconfig  Configura o kernel"
	@echo "  make busybox-menuconfig Configura o BusyBox"
	@echo "  make clean              Remove build/"
	@echo "  make distclean          Remove build/ e sources/"
	@echo "  make purge              Remove build/, sources/ e downloads/"
