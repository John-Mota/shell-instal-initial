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

    install_apt_package "curl"
    install_apt_package "build-essential"

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
    else
        print_error "Falha na instalação do Docker"
    fi
    
    # Configuração do grupo Docker
    if sudo groupadd docker 2>/dev/null || true && sudo usermod -aG docker "$USER" && sudo systemctl restart docker; then
        print_success "Grupo Docker configurado com sucesso"
    else
        print_error "Falha na configuração do grupo Docker"
    fi

    # PostgreSQL
    print_status "Instalando PostgreSQL"
    if install_apt_package "postgresql" && {
        sudo systemctl start postgresql &&
        sudo systemctl enable postgresql &&
        sudo -u postgres psql -c "CREATE USER john WITH PASSWORD 'john3472' SUPERUSER;" 2>/dev/null || true &&
        sudo -u postgres psql -c "CREATE DATABASE john OWNER john;" 2>/dev/null || true &&
        sudo sed -i 's/^local.*all.*all.*peer/local   all             all                                     md5/' /etc/postgresql/*/main/pg_hba.conf &&
        sudo systemctl restart postgresql
    }; then
        print_success "PostgreSQL configurado com sucesso"
    else
        print_error "Falha na configuração do PostgreSQL"
    fi

    # [... resto do script continua igual ...]

    # DNS - Versão simplificada e mais robusta
    print_status "Configurando DNS"
    if {
        sudo echo "DNS=172.29.0.25 172.29.0.23" | sudo tee -a /etc/systemd/resolved.conf &&
        sudo systemctl restart systemd-resolved
    }; then
        print_success "DNS configurado com sucesso"
    else
        print_error "Falha na configuração do DNS"
    fi

    # Imprimir resumo final
    print_summary
}

# Executa o script
main