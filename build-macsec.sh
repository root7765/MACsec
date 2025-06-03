#!/bin/bash

set -e

echo "📁 Schritt 1: Arbeitsverzeichnis anlegen..."
mkdir -p ~/macsec-build2
cd ~/macsec-build2

echo "🐧 Schritt 2: Raspberry Pi Kernelquelle klonen (rpi-6.12.y)..."
rm -rf linux
git clone --depth=1 --branch rpi-6.12.y https://github.com/raspberrypi/linux.git
cd linux

echo "⚙️ Schritt 3: Aktuelle Kernel-Konfiguration übernehmen..."
zcat /proc/config.gz > .config

echo "🧩 Schritt 4: MACsec als Modul aktivieren..."
sed -i 's/^# CONFIG_MACSEC is not set/CONFIG_MACSEC=m/' .config
# Falls Zeile nicht existiert, anhängen
grep -q CONFIG_MACSEC .config || echo "CONFIG_MACSEC=m" >> .config

echo "🛠 Schritt 5: Konfiguration aktualisieren & vorbereiten..."
make olddefconfig
make modules_prepare

echo "🔨 Schritt 6: MACsec-Modul bauen..."
if [ -d "net/macsec" ]; then
  make M=net/macsec modules
else
  echo "❌ Fehler: net/macsec/ wurde nicht gefunden. Prüfe den Branch oder die Quelle!"
  exit 1
fi

echo "📦 Schritt 7: Modul installieren..."
sudo mkdir -p /lib/modules/$(uname -r)/kernel/net/macsec
sudo cp net/macsec/macsec.ko /lib/modules/$(uname -r)/kernel/net/macsec/
sudo depmod

echo "🧪 Schritt 8: Modul laden und prüfen..."
sudo modprobe macsec
lsmod | grep macsec && echo "✅ MACsec erfolgreich geladen!" || echo "❌ MACsec konnte nicht geladen werden."

echo "🌐 Schritt 9: MACsec-Schnittstelle testen..."
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -m 1 -v lo)
echo "Verwende Interface: $IFACE"
sudo ip link add link "$IFACE" macsec0 type macsec || echo "⚠️ Hinweis: MACsec-Schnittstelle konnte nicht erstellt werden – ggf. Interface prüfen."

echo "🏁 Fertig!"

