#!/bin/bash

# Atualizar a lista de pacotes
sudo apt update

sudo apt upgrade -y

# install curl
sudo apt install curl -y

# install git
sudo apt install git -y

# install font-hack
sudo apt-get install fonts-hack-ttf -y

# Instalação do MySQL
sudo apt install mysql-client-core-8.0

# Instalação do MySQL Workbench
wget https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb
sudo dpkg -i mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb

# instal MVN
 curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash


# Download do arquivo .deb do Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# Instalação do Google Chrome a partir do arquivo .deb baixado
sudo dpkg -i google-chrome-stable_current_amd64.deb

# Se houver dependências não satisfeitas, você pode corrigi-las com o seguinte comando
sudo apt-get install -f -y

# Download do Discord
wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"

# Instalação do Discord
sudo dpkg -i discord.deb
sudo apt-get install -f -y

# Remover os arquivos .deb após a instalação (opcional)
rm discord.deb gimp.deb telegram.deb hero_games.deb google-chrome-stable_current_amd64.deb mysql-apt-config_0.8.16-1_all.deb mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb

# Flat-Remix
sudo add-apt-repository ppa:daniruiz/flat-remix -y && sudo apt-get update && sudo apt-get install flat-remix-gtk -y && sudo apt-get install flat-remix -y
#install flatpak
sudo apt install flatpak -y
sudo apt install gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# install themes remix
sudo add-apt-repository ppa:daniruiz/flat-remix -y && sudo apt-get update && sudo apt-get install flat-remix-gtk -y && sudo apt-get install flat-remix -y


# Instalar aplicativos flatpak

# InteliJ
flatpak install flathub com.jetbrains.IntelliJ-IDEA-Community -y

# WhatsApp
flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y

# Emulador Nitendo
flatpak install flathub org.ryujinx.Ryujinx -y


# Exibe uma mensagem de conclusão
echo "A instalação foi concluída."

