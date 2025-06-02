#!/bin/bash
set -e

echo "📦 Schritt 1: Abhängigkeiten installieren..."
sudo apt update
sudo apt install -y git bc bison flex libssl-dev make libncurses-dev \
  raspberrypi-kernel-headers build-essential

echo "📁 Schritt 2: Arbeitsverzeichnis erstellen..."
mkdir -p ~/macsec-build
cd ~/macsec-build

echo "🔍 Schritt 3: Aktuelle Kernel-Version holen..."
KERNEL_VER=$(uname -r)
echo "👉 Aktive Kernel-Version: $KERNEL_VER"

echo "🐧 Schritt 4: Raspberry Pi Kernel-Quellen klonen..."
git clone --depth=1 https://github.com/raspberrypi/linux
cd linux

echo "⚙️ Schritt 5: Konfiguration übernehmen..."
zcat /proc/config.gz > .config || cp /boot/config-"$KERNEL_VER" .config
make olddefconfig

echo "✅ Schritt 6: MACsec in .config aktivieren..."
sed -i 's/^# CONFIG_MACSEC is not set/CONFIG_MACSEC=m/' .config
# Wenn schon CONFIG_MACSEC=m da ist, kein Problem

echo "🔧 Schritt 7: Build vorbereiten..."
make modules_prepare

echo "🔨 Schritt 8: Nur macsec.ko bauen..."
make M=net/macsec modules

echo "📥 Schritt 9: Modul installieren..."
sudo mkdir -p /lib/modules/"$KERNEL_VER"/kernel/net/macsec
sudo cp net/macsec/macsec.ko /lib/modules/"$KERNEL_VER"/kernel/net/macsec/
sudo depmod
sudo modprobe macsec

echo "✅ Fertig! Modulstatus:"
lsmod | grep macsec || echo "⚠️ Modul nicht geladen"

echo "🧪 Optionaler Test:"
echo "Versuche: sudo ip link add link eth0 macsec0 type macsec"
