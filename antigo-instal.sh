#!/bin/bash

# Update package list
sudo apt update
sudo apt upgrade -y

# Install curl
sudo apt install curl -y

# Instalar build-essential
sudo apt-get install build-essential -y

# Install Docker

sudo apt-get install \ ca-certificates \ curl \ gnupg \ lsb-release

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
 "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if ! getent group docker > /dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker $USER
sudo systemctl restart docker

 # Flameshot
 sudo apt install flameshot -y

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

# Install gnome-tweak-tool
sudo apt install gnome-tweak-tool -y

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


# Install Mise
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc

# Fira Code
sudo apt install flameshot -y

# Braver
curl -fsS https://dl.brave.com/install.sh | sh

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

# DBeaver Community
flatpak install flathub io.dbeaver.DBeaverCommunity -y

# InteliJ
flatpak install flathub com.jetbrains.IntelliJ-IDEA-Community -y

# Postman
sudo snap install postman

# OnlyOffice
flatpak install flathub org.onlyoffice.desktopeditors -y

# Note Translate
flatpak install flathub net.mkiol.SpeechNote -y

# Notes
flatpak install flathub com.vixalien.sticky -y

#DevToll
flatpak install flathub me.iepure.devtoolbox -y

flatpak install flathub io.github.brunofin.Cohesion -y
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


# Adicionar a função parse_git_branch e configuração do PS1
sudo tee -a ~/.zshrc > /dev/null << 'EOF'

export NODE_OPTIONS="--max-old-space-size=4096"
EOF
source ~/.zshrc

# Adicionar as configurações de DNS e FallbackDNS ao arquivo /etc/systemd/resolved.conf
sudo tee -a /etc/systemd/resolved.conf > /dev/null << EOF
DNS=172.29.0.25 172.29.0.23
EOF

sudo systemctl restart systemd-resolved
