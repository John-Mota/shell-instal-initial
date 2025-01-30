#!/bin/bash

# Função para imprimir mensagens de status
print_status() {
    echo -e "\n\033[1;34m[INFO] $1\033[0m"
}

# Função para verificar erros
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "\033[1;31m[ERRO] $1\033[0m"
        exit 1
    fi
}

print_status "Iniciando instalação do ambiente de desenvolvimento..."

# Atualização inicial do sistema
print_status "Atualizando o sistema"
sudo apt update && sudo apt upgrade -y
sudo apt install curl build-essential -y
check_error "Falha na atualização do sistema"

# Docker
print_status "Instalando Docker"
sudo apt-get install ca-certificates curl gnupg lsb-release -y
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
check_error "Falha na instalação do Docker"

# Configuração do grupo Docker
if ! getent group docker > /dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker $USER
sudo systemctl restart docker

# PostgreSQL
print_status "Instalando PostgreSQL"
sudo apt install postgresql -y
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -u postgres psql -c "CREATE USER john WITH PASSWORD 'john3472' SUPERUSER;"
sudo -u postgres psql -c "CREATE DATABASE john OWNER john;"
sudo sed -i '/^local.*all.*all.*peer/c\local   all             all                                     md5' /etc/postgresql/*/main/pg_hba.conf
sudo systemctl restart postgresql
check_error "Falha na configuração do PostgreSQL"

# Ferramentas de Sistema
print_status "Instalando ferramentas do sistema"
sudo apt install -y \
    gnome-tweak-tool \
    flameshot \
    fonts-firacode
check_error "Falha na instalação das ferramentas do sistema"

# VSCode
print_status "Instalando VSCode"
wget "https://go.microsoft.com/fwlink/?LinkID=760868" -O vscode.deb
sudo dpkg -i vscode.deb
sudo apt install -f -y
rm vscode.deb

# Mise
print_status "Instalando Mise"
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc

# Braver Browser
print_status "Instalando Braver Browser"
curl -fsS https://dl.brave.com/install.sh | sh

# Flatpak
print_status "Configurando Flatpak"
sudo apt install flatpak gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Aplicativos Flatpak
print_status "Instalando aplicativos Flatpak"
declare -a FLATPAK_APPS=(
    "io.github.mimbrero.WhatsAppDesktop"
    "com.mattjakeman.ExtensionManager"
    "dev.aunetx.deezer"
    "io.dbeaver.DBeaverCommunity"
    "com.jetbrains.IntelliJ-IDEA-Community"
    "org.onlyoffice.desktopeditors"
    "net.mkiol.SpeechNote"
    "com.vixalien.sticky"
    "me.iepure.devtoolbox"
    "io.github.brunofin.Cohesion"
)

for app in "${FLATPAK_APPS[@]}"; do
    print_status "Instalando $app"
    flatpak install flathub "$app" -y
done

# Postman
print_status "Instalando Postman"
sudo snap install postman

# Configurações do Sistema
print_status "Aplicando configurações do sistema"
echo 'export NODE_OPTIONS="--max-old-space-size=8192"' >> ~/.zshrc

print_status "Instalando dependências do sistema"
declare -a DEPS=(
    "1-gconf2-common_3.2.6-7ubuntu2_all.deb"
    "2-libgconf-2-4_3.2.6-7ubuntu2_amd64.deb"
    "3-libayatana-indicator7_0.9.1-1_amd64.deb"
    "4-libdbusmenu-gtk4_16.04.1+18.10.20180917-0ubuntu8_amd64.deb"
    "5-libldap-2.5-0_2.5.16+dfsg-0ubuntu0.22.04.2_amd64.deb"
    "6-libappindicator1_12.10.1+20.10.20200706.1-0ubuntu1_amd64.deb"
    "7-libayatana-appindicator1_0.5.90-7ubuntu2_amd64.deb"
)

for dep in "${DEPS[@]}"; do
    print_status "Instalando $dep"
    sudo dpkg -i "$dep"
    check_error "Falha na instalação de $dep"
done

# Corrigir dependências
sudo apt-get install -f -y
check_error "Falha na correção de dependências"

# FortiClient VPN
print_status "Instalando FortiClient VPN"
wget -O fortnet.deb "https://links.fortinet.com/forticlient/deb/vpnagent"
check_error "Falha no download do FortiClient"
sudo dpkg -i fortnet.deb
sudo apt-get install -f -y
rm fortnet.deb
check_error "Falha na instalação do FortiClient"

# DNS
print_status "Configurando DNS"
sudo tee -a /etc/systemd/resolved.conf > /dev/null << EOF
DNS=172.29.0.25 172.29.0.23
EOF
sudo systemctl restart systemd-resolved

print_status "Instalação concluída! Por favor, reinicie seu sistema."