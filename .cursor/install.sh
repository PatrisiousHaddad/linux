#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
	build-essential \
	bc \
	bison \
	flex \
	libssl-dev \
	libelf-dev \
	libncurses-dev \
	cpio \
	kmod \
	dwarves \
	rsync \
	qemu-system-x86 \
	busybox-static

if [ ! -f .config ]; then
	make defconfig
fi

make -j"$(nproc)" bzImage
