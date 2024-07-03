#!/bin/bash

# Update package list
sudo apt update

sudo apt upgrade -y

# Install curl
sudo apt install curl -y

# Ajustar Hora
timedatectl set-local-rtc 1

# Instalar build-essential
sudo apt-get install build-essential

# Install git
sudo apt install git -y

# Install Docker

sudo apt-get install \ ca-certificates \ curl \ gnupg \ lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
 "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


# Java Development Kit
sudo apt-get -y install openjdk-11-jdk -y
 

# PostgresQL
sudo apt install postgresql -y

# Instalar Edge
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list'
rm microsoft.gpg

sudo apt update

sudo apt install microsoft-edge-stable


# install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

# Download Google Chrome .deb file
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# Install Google Chrome from downloaded .deb file
sudo dpkg -i google-chrome-stable_current_amd64.deb

# If there are unmet dependencies, you can fix them with the following command
sudo apt-get install -f -y

# Download Discord
wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"

# Install Discord
sudo dpkg -i discord.deb
sudo apt-get install -f -y


# Install VSCode
wget "https://go.microsoft.com/fwlink/?LinkID=760868" -O vscode.deb
sudo dpkg -i vscode.deb
sudo apt install -f -y
# Remove .deb files after installation (optional)
rm discord.deb gimp.deb telegram.deb hero_games.deb google-chrome-stable_current_amd64.deb mysql-apt-config_0.8.16-1_all.deb mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb

# Install Tweak-tool
sudo apt install gnome-tweaks -y

# Install flatpak
sudo apt install flatpak -y
sudo apt install gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install flatpak applications


# WhatsApp
flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y

# Extensões
flatpak install flathub com.mattjakeman.ExtensionManager -y

# Deezer
flatpak install flathub dev.aunetx.deezer -y

# OnlyOffice
flatpak install flathub org.onlyoffice.desktopeditors -y

# Postman
flatpak install flathub com.getpostman.Postman -y


# Instalar os pacotes na ordem correta
sudo dpkg -i 1-gconf2-common_3.2.6-7ubuntu2_all.deb
sudo dpkg -i 2-libgconf-2-4_3.2.6-7ubuntu2_amd64.deb
sudo dpkg -i 3-libayatana-indicator7_0.9.1-1_amd64.deb
sudo dpkg -i 4-libdbusmenu-gtk4_16.04.1+18.10.20180917-0ubuntu8_amd64.deb
sudo dpkg -i 5-libldap-2.5-0_2.5.16+dfsg-0ubuntu0.22.04.2_amd64.deb
sudo dpkg -i 6-libappindicator1_12.10.1+20.10.20200706.1-0ubuntu1_amd64.deb
sudo dpkg -i 7-libayatana-appindicator1_0.5.90-7ubuntu2_amd64.deb

# Corrigir possíveis dependências ausentes
sudo apt-get install -f

# Install Fortnet
wget -O fortnet.deb "https://links.fortinet.com/forticlient/deb/vpnagent"
sudo dpkg -i fortnet.deb
sudo apt-get install -f -y
# Display completion message
echo "Installation completed."
