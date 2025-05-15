#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Arrays para armazenar logs
declare -a SUCCESS_LOG=()
declare -a ERROR_LOG=()

# Função para imprimir mensagens de status
print_status() {
    echo -e "\n${BLUE}[INFO] $1${NC}"
}

# Função para imprimir mensagens de sucesso
print_success() {
    echo -e "${GREEN}[SUCESSO] $1${NC}"
    SUCCESS_LOG+=("$1")
}

# Função para imprimir mensagens de erro
print_error() {
    echo -e "${RED}[ERRO] $1${NC}"
    ERROR_LOG+=("$1")
}

# Função para verificar erros
check_error() {
    if [ $? -ne 0 ]; then
        print_error "$1"
        return 1
    else
        print_success "$1 instalado com sucesso"
        return 0
    fi
}

# Função para instalar pacotes apt
install_apt_package() {
    print_status "Instalando $1..."
    if sudo apt-get install -y "$1"; then
        print_success "Pacote $1 instalado com sucesso"
    else
        print_error "Falha ao instalar pacote $1"
    fi
}

# Função para instalar pacotes .deb
install_deb_package() {
    local package_name=$1
    local deb_url=$2
    local deb_file="$package_name.deb"
    
    print_status "Baixando e instalando $package_name..."
    if wget -O "$deb_file" "$deb_url" && \
       sudo dpkg -i "$deb_file" && \
       sudo apt-get install -f -y; then
        print_success "$package_name instalado com sucesso"
        rm -f "$deb_file"
    else
        print_error "Falha ao instalar $package_name"
        rm -f "$deb_file"
    fi
}

# Função para instalar flatpak
install_flatpak() {
    print_status "Instalando $1..."
    if flatpak install flathub "$1" -y; then
        print_success "Flatpak $1 instalado com sucesso"
    else
        print_error "Falha ao instalar flatpak $1"
    fi
}

# Função para exibir resumo final
print_summary() {
    echo -e "\n${GREEN}=== RESUMO DA INSTALAÇÃO ===${NC}"
    
    echo -e "\n${GREEN}Instalações bem-sucedidas:${NC}"
    if [ ${#SUCCESS_LOG[@]} -eq 0 ]; then
        echo "Nenhuma instalação concluída com sucesso"
    else
        for success in "${SUCCESS_LOG[@]}"; do
            echo -e "${GREEN}✓${NC} $success"
        done
    fi
    
    echo -e "\n${RED}Falhas na instalação:${NC}"
    if [ ${#ERROR_LOG[@]} -eq 0 ]; then
        echo "Nenhuma falha registrada"
    else
        for error in "${ERROR_LOG[@]}"; do
            echo -e "${RED}✗${NC} $error"
        done
    fi
    
    # Salvar logs em arquivo
    echo "=== Log de Instalação ===" > install_log.txt
    echo "Data: $(date)" >> install_log.txt
    echo -e "\nSucessos:" >> install_log.txt
    printf '%s\n' "${SUCCESS_LOG[@]}" >> install_log.txt
    echo -e "\nErros:" >> install_log.txt
    printf '%s\n' "${ERROR_LOG[@]}" >> install_log.txt
    
    echo -e "\nLog completo salvo em: install_log.txt"
}

main() {
    # Verifica se está rodando como root
    if [ "$EUID" -eq 0 ]; then 
        print_error "Não execute este script como root (sudo)!"
        exit 1
    fi

    print_status "Iniciando instalação do ambiente de desenvolvimento..."

    # Atualização inicial do sistema
    print_status "Atualizando o sistema"
    if sudo apt-get update && sudo apt-get upgrade -y; then
        print_success "Sistema atualizado com sucesso"
    else
        print_error "Falha na atualização do sistema"
    fi

    # Instalar pacotes básicos
    install_apt_package "curl"
    install_apt_package "build-essential"
    install_apt_package "openjdk-21-jdk"
    install_apt_package "docker-compose-plugin"
    install_apt_package "terraform"
    install_apt_package "ansible"

    echo "🔧 Instalando kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

    echo "🔧 Instalando Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube

    echo "🚀 Iniciando Minikube com Docker como driver..."
    minikube start --driver=docker

    # Docker
    print_status "Instalando Docker"
    if {
        sudo apt-get install -y ca-certificates curl gnupg lsb-release &&
        sudo mkdir -p /etc/apt/keyrings &&
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
        sudo apt-get update &&
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    }; then
        print_success "Docker instalado com sucesso"
        
        # Configuração do grupo Docker
        if sudo groupadd docker 2>/dev/null || true && sudo usermod -aG docker "$USER" && sudo systemctl restart docker; then
            print_success "Grupo Docker configurado com sucesso"
        else
            print_error "Falha na configuração do grupo Docker"
        fi
    else
        print_error "Falha na instalação do Docker"
    fi

    # PostgreSQL
    print_status "Instalando PostgreSQL"
    if install_apt_package "postgresql" && {
        sudo systemctl start postgresql &&
        sudo systemctl enable postgresql &&
        sudo sed -i '/^local.*all.*all.*peer/c\local   all             all                                     md5' /etc/postgresql/*/main/pg_hba.conf &&
        sudo systemctl restart postgresql
    }; then
        print_success "PostgreSQL configurado com sucesso"
    else
        print_error "Falha na configuração do PostgreSQL"
    fi

    echo "🗃️ Subindo Docker Registry local (porta 5000)..."
    docker run -d -p 5000:5000 --restart=always --name registry registry:2


    # Mise
    print_status "Instalando Mise"
    if curl https://mise.run | sh; then
        echo 'eval "$(~/.local/bin/mise activate fish | source)"' >> ~/.config/fish/config.fish
        print_success "Mise instalado com sucesso"
    else
        print_error "Falha na instalação do Mise"
    fi

    # Configurações do sistema
    print_status "Aplicando configurações do sistema"
    
    # NODE_OPTIONS
    echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> ~/.config/fish/config.fish
    source ~/.config/fish/config.fish

    # Imprimir resumo final
    print_summary
}

# Executa o script
main
