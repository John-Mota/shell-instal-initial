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

# Download do arquivo .deb do Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# Instalação do Google Chrome a partir do arquivo .deb baixado
sudo dpkg -i google-chrome-stable_current_amd64.deb

# Se houver dependências não satisfeitas, você pode corrigi-las com o seguinte comando
sudo apt-get install -f

# Remover o arquivo .deb após a instalação (opcional)
rm google-chrome-stable_current_amd64.deb

#install flatpak
sudo apt install flatpak -y
sudo apt install gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# install themes remix
git clone https://github.com/daniruiz/flat-remix
git clone https://github.com/daniruiz/flat-remix-gtk
mkdir -p ~/.icons && mkdir -p ~/.themes
cp -r flat-remix/Flat-Remix* ~/.icons/ && cp -r flat-remix-gtk/Flat-Remix-GTK* ~/.themes/

# install font hack
sudo apt install gnome-tweaks fonts-hack-ttf -y

# Instalar aplicativos flatpak

# InteliJ
flatpak install flathub com.jetbrains.IntelliJ-IDEA-Community -y

#Discord
flatpak install flathub com.discordapp.Discord -y

# Gimp
flatpak install flathub org.gimp.GIMP -y

# Telegram
flatpak install flathub org.telegram.desktop -y


#Hero Games
flatpak install flathub com.heroicgameslauncher.hgl -y

# WhatsApp
flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y

# Emulador Nitendo
flatpak install flathub org.ryujinx.Ryujinx -y


# Exibe uma mensagem de conclusão
echo "A instalação foi concluída."

