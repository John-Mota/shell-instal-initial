#!/bin/bash

# Update package list
sudo dnf update

sudo dnf upgrade -y

# Install curl
sudo dnf install curl -y

# Ajustar Hora
timedatectl set-local-rtc 1

# Install build-essential
sudo dnf install build-essential -y

# Install EDGE
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf install microsoft-edge-stable


# Install Docker

sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

wget https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64

sudo dnf install ./docker-desktop-x86_64.rpm

systemctl --user start docker-desktop

if ! getent group docker > /dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker $USER
sudo systemctl restart docker


# PostgresQL
sudo apt install postgresql -y

# Inicia o serviço do PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Cria um novo usuário no PostgreSQL
sudo -u postgres psql -c "CREATE USER john WITH PASSWORD 'john3472';"

# Concede privilégios de superusuário (opcional - remova se não precisar)
sudo -u postgres psql -c "ALTER USER john WITH SUPERUSER;"

# Cria um banco de dados com o mesmo nome do usuário (prática comum)
sudo -u postgres psql -c "CREATE DATABASE john OWNER john;"

# Configura a autenticação no arquivo pg_hba.conf para permitir login com senha
sudo sed -i '/^local.*all.*all.*peer/c\local   all             all                                     md5' /etc/postgresql/*/main/pg_hba.conf
sudo systemctl restart postgresql

sudo dnf install gnome-tweaks -y

# Install Google Chrome 
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.rpm
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f -y

#Discord
wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
sudo dpkg -i discord.deb
sudo apt-get install -f -y

# VsCode
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf check-update
sudo dnf install code -y

# Install Mise
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# WhatsApp
flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y

# Extensões
flatpak install flathub com.mattjakeman.ExtensionManager -y

# Deezer
flatpak install flathub dev.aunetx.deezer -y

# DBeaver Community
flatpak install flathub io.dbeaver.DBeaverCommunity -y

# InteliJ
flatpak install flathub com.jetbrains.IntelliJ-IDEA-Community -y

# Postman
sudo snap install postman

sudo tee -a ~/.zshrc > /dev/null << 'EOF'

export NODE_OPTIONS="--max-old-space-size=8192"
EOF
source ~/.zshrc

# Adicionar as configurações de DNS e FallbackDNS ao arquivo /etc/systemd/resolved.conf
sudo tee -a /etc/systemd/resolved.conf > /dev/null << EOF
DNS=172.29.0.25 172.29.0.23
EOF

sudo systemctl restart systemd-resolved