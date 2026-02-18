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
  wget -q https://www.eclipse.org/downloads/download.php?file=/modeling/mdt/papyrus/rcp/latest/papyrus-rcp-linux64.tar.gz -O papyrus.tar.gz
  tar -xzf papyrus.tar.gz
  mv Papyrus papyrus
fi

echo "SysML v2 tools installed."