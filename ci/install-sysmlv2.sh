#!/usr/bin/env bash
set -e

TOOLS_DIR=$HOME/sysml-tools
mkdir -p $TOOLS_DIR
cd $TOOLS_DIR

# Download SysML v2 reference implementation
if [ ! -d "sysmlv2" ]; then
  git clone https://github.com/Systems-Modeling/SysML-v2-Release.git sysmlv2
fi

# Download Papyrus headless
if [ ! -d "papyrus" ]; then
  wget -q "https://www.eclipse.org/downloads/download.php?file=/modeling/mdt/papyrus/papyrus-desktop/rcp/2025-06/7.1.0/papyrus-desktop-2025-06-7.1.0-linux.gtk.x86_64.tar.gz&r=1" -O papyrus.tar.gz
  tar -xzf papyrus.tar.gz
  mv Papyrus papyrus
fi

echo "SysML v2 tools installed."