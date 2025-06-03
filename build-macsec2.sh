#!/bin/bash
set -e

# Verzeichnisse
WORKDIR=~/macsec-build
RPI_KERNEL_DIR=$WORKDIR/rpi-linux
MAINLINE_KERNEL_DIR=$WORKDIR/mainline-linux

echo "📁 1. Arbeitsverzeichnis erstellen..."
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "🐧 2. RPi-Kernel klonen (rpi-6.1.y)..."
rm -rf "$RPI_KERNEL_DIR"
git clone --depth=1 --branch rpi-6.1.y https://github.com/raspberrypi/linux.git "$RPI_KERNEL_DIR"

echo "🧠 3. Mainline-Linux v6.1 klonen (für MACsec)..."
rm -rf "$MAINLINE_KERNEL_DIR"
git clone --depth=1 --branch v6.1 https://github.com/torvalds/linux.git "$MAINLINE_KERNEL_DIR"

echo "📦 4. MACsec-Code in Raspberry Pi Kernel kopieren..."
mkdir -p "$RPI_KERNEL_DIR/net/macsec"
cp -r "$MAINLINE_KERNEL_DIR/net/macsec/"* "$RPI_KERNEL_DIR/net/macsec/"

echo "⚙️ 5. Konfiguration übernehmen..."
cd "$RPI_KERNEL_DIR"
cp /boot/config-$(uname -r) .config
scripts/config --module CONFIG_MACSEC

echo "🔨 6. MACsec-Modul bauen..."
make olddefconfig
make M=net/macsec modules

echo "✅ 7. MACsec-Modul ist gebaut:"
find net/macsec -name '*.ko'
