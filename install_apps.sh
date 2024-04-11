#!/bin/bash

# Update package list
sudo apt update

sudo apt upgrade -y

# Install curl
sudo apt install curl -y

# Install git
sudo apt install git -y

# Install Hack font
sudo apt-get install fonts-hack-ttf -y

# MySQL Installation
sudo apt install mysql-client-core-8.0

# MySQL Workbench Installation
wget https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb
sudo dpkg -i mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb

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
sudo apt install -f
# Remove .deb files after installation (optional)
rm discord.deb gimp.deb telegram.deb hero_games.deb google-chrome-stable_current_amd64.deb mysql-apt-config_0.8.16-1_all.deb mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb

# Flat-Remix Theme
sudo add-apt-repository ppa:daniruiz/flat-remix -y && sudo apt-get update && sudo apt-get install flat-remix-gtk -y && sudo apt-get install flat-remix -y
# Install flatpak
sudo apt install flatpak -y
sudo apt install gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Remix themes
sudo add-apt-repository ppa:daniruiz/flat-remix -y && sudo apt-get update && sudo apt-get install flat-remix-gtk -y && sudo apt-get install flat-remix -y

# Install flatpak applications

# InteliJ
flatpak install flathub com.jetbrains.IntelliJ-IDEA-Community -y

# WhatsApp
flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y

# Nintendo Emulator
flatpak install flathub org.ryujinx.Ryujinx -y

# Display completion message
echo "Installation completed."
