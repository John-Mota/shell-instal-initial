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
wget https://dev.mysql.com/get/mysql-apt-config_0.8.16-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.16-1_all.deb
sudo apt-get update
sudo apt-get install mysql-server -y

# Instalação do MySQL Workbench
wget https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb
sudo dpkg -i mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb

# Limpeza
rm mysql-apt-config_0.8.16-1_all.deb mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb


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

# Download do Gimp
wget -O gimp.deb "https://download.gimp.org/pub/gimp/v2.10/gimp-2.10.30-x86_64.deb"

# Instalação do Gimp
sudo dpkg -i gimp.deb
sudo apt-get install -f -y

# Download do Telegram
wget -O telegram.deb "https://telegram.org/dl/desktop/linux"

# Instalação do Telegram
sudo dpkg -i telegram.deb
sudo apt-get install -f -y

# Download do Hero Games
wget -O hero_games.deb "https://heroicgameslauncher.com/HeroicGamesLauncher_latest_amd64.deb"

# Instalação do Hero Games
sudo dpkg -i hero_games.deb
sudo apt-get install -f -y

# Remover os arquivos .deb após a instalação (opcional)
rm discord.deb gimp.deb telegram.deb hero_games.deb google-chrome-stable_current_amd64.deb


#install flatpak
sudo apt install flatpak -y
sudo apt install gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# install themes remix
git clone https://github.com/daniruiz/flat-remix
git clone https://github.com/daniruiz/flat-remix-gtk
mkdir -p ~/.icons && mkdir -p ~/.themes
cp -r flat-remix/Flat-Remix* ~/.icons/ && cp -r flat-remix-gtk/Flat-Remix-GTK* ~/.themes/


# Instalar aplicativos flatpak

# InteliJ
flatpak install flathub com.jetbrains.IntelliJ-IDEA-Community -y

# WhatsApp
flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y

# Emulador Nitendo
flatpak install flathub org.ryujinx.Ryujinx -y


# Exibe uma mensagem de conclusão
echo "A instalação foi concluída."

