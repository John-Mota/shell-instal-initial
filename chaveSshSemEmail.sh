#!/bin/bash

# Definir variável de e-mail
EMAIL=""

# Install NODE
nvm install 20.18.0

# Install Spring Tool
wget https://cdn.spring.io/spring-tools/release/STS4/4.24.0.RELEASE/dist/e4.32/spring-tool-suite-4-4.24.0.RELEASE-e4.32.0-linux.gtk.x86_64.tar.gz
sudo tar zxvf spring-tool-suite-4-4.24.0.RELEASE-e4.32.0-linux.gtk.x86_64.tar.gz
sudo mv sts-4.24.0.RELEASE/ /opt/SpringToolSuite
cd /opt/
sudo ln -s /opt/SpringToolSuite/SpringToolSuite4 /usr/local/bin/sts
sudo bash -c 'cat > /usr/share/applications/stsLauncher.desktop <<EOL
[Desktop Entry]
Name=Spring Tool Suite
Comment=Spring Tool Suite 4.24.0
Exec=/opt/SpringToolSuite/SpringToolSuite4
Icon=/opt/SpringToolSuite/icon.xpm
StartupNotify=true
Terminal=false
Type=Application
Categories=Development;IDE;Java;
EOL'


git config --global user.name "John Mota"
git config --global user.email "$EMAIL"
ssh-keygen -t rsa -b 4096 -C "$EMAIL" # Email Git Bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub