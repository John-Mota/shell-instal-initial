#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Diretório do script (para referenciar assets)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Função para imprimir avisos
print_warning() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" &> /dev/null
}

# Função para instalar pacotes apt
install_apt_package() {
    print_status "Instalando $1..."
    if sudo apt-get install -y "$1" 2>/dev/null; then
        print_success "Pacote $1 instalado com sucesso"
        return 0
    else
        print_error "Falha ao instalar pacote $1"
        return 1
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

# Função para instalar Docker
install_docker() {
    print_status "Instalando Docker..."
    
    # Remover versões antigas
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Instalar dependências
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Adicionar chave GPG oficial do Docker
    sudo mkdir -p /etc/apt/keyrings
    
    # Remover chave antiga se existir
    sudo rm -f /etc/apt/keyrings/docker.gpg
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Adicionar repositório
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker
    sudo apt-get update
    if sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        print_success "Docker instalado com sucesso"
        
        # Configurar grupo Docker
        sudo groupadd docker 2>/dev/null || true
        sudo usermod -aG docker "$USER"
        
        # Iniciar serviço Docker
        sudo systemctl enable docker
        sudo systemctl start docker
        
        print_success "Grupo Docker configurado (relogin necessário para efetivar)"
        return 0
    else
        print_error "Falha na instalação do Docker"
        return 1
    fi
}

# Função para instalar Terraform
install_terraform() {
    print_status "Instalando Terraform..."
    
    # Instalar dependências
    sudo apt-get install -y gnupg software-properties-common
    
    # Adicionar chave GPG HashiCorp
    wget -O- https://apt.releases.hashicorp.com/gpg | \
        sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null || \
        sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    
    # Adicionar repositório
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list
    
    sudo apt-get update
    
    if sudo apt-get install -y terraform; then
        print_success "Terraform instalado com sucesso"
        return 0
    else
        print_error "Falha na instalação do Terraform"
        return 1
    fi
}

# Função para instalar kubectl
install_kubectl() {
    print_status "Instalando kubectl..."
    
    # Baixar a versão mais recente
    local kubectl_version
    kubectl_version=$(curl -sL https://dl.k8s.io/release/stable.txt)
    
    if curl -LO "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl"; then
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        print_success "kubectl instalado com sucesso"
        rm -f kubectl 2>/dev/null
        return 0
    else
        print_error "Falha na instalação do kubectl"
        rm -f kubectl 2>/dev/null
        return 1
    fi
}

# Função para instalar Minikube
install_minikube() {
    print_status "Instalando Minikube..."
    
    if curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64; then
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        rm -f minikube-linux-amd64
        print_success "Minikube instalado com sucesso"
        return 0
    else
        print_error "Falha na instalação do Minikube"
        rm -f minikube-linux-amd64 2>/dev/null
        return 1
    fi
}

# Função para instalar PostgreSQL
install_postgresql() {
    print_status "Instalando PostgreSQL..."
    
    if sudo apt-get install -y postgresql postgresql-contrib; then
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        
        # Configurar autenticação md5
        local pg_hba_file
        pg_hba_file=$(sudo find /etc/postgresql -name "pg_hba.conf" 2>/dev/null | head -1)
        
        if [ -n "$pg_hba_file" ]; then
            sudo sed -i 's/^local.*all.*all.*peer/local   all             all                                     md5/' "$pg_hba_file"
            sudo systemctl restart postgresql
        fi
        
        print_success "PostgreSQL instalado e configurado com sucesso"
        return 0
    else
        print_error "Falha na instalação do PostgreSQL"
        return 1
    fi
}

# Função para instalar Mise
install_mise() {
    print_status "Instalando Mise..."
    
    if curl https://mise.run | sh; then
        # Verificar se o diretório de configuração do fish existe
        if [ -d "$HOME/.config/fish" ]; then
            # Verificar se já está configurado
            if ! grep -q "mise activate" "$HOME/.config/fish/config.fish" 2>/dev/null; then
                echo 'eval (~/.local/bin/mise activate fish | source)' >> "$HOME/.config/fish/config.fish"
            fi
            print_success "Mise instalado e configurado para Fish"
        else
            print_warning "Diretório Fish não encontrado. Configure manualmente se necessário."
            print_success "Mise instalado com sucesso"
        fi
        
        # Configurar para bash também
        if ! grep -q "mise activate" "$HOME/.bashrc" 2>/dev/null; then
            echo 'eval "$(~/.local/bin/mise activate bash)"' >> "$HOME/.bashrc"
        fi
        
        return 0
    else
        print_error "Falha na instalação do Mise"
        return 1
    fi
}

# Função para configurar Docker Registry local
setup_docker_registry() {
    print_status "Configurando Docker Registry local..."
    
    # Verificar se Docker está rodando
    if ! sudo docker info &>/dev/null; then
        print_warning "Docker não está rodando. Tentando iniciar..."
        sudo systemctl start docker
        sleep 3
    fi
    
    # Verificar se o registry já existe
    if sudo docker ps -a --format '{{.Names}}' | grep -q '^registry$'; then
        print_warning "Registry já existe. Removendo e recriando..."
        sudo docker rm -f registry 2>/dev/null
    fi
    
    if sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2; then
        print_success "Docker Registry local configurado na porta 5000"
        return 0
    else
        print_error "Falha ao configurar Docker Registry local"
        return 1
    fi
}

# Função para configurar Node.js
configure_node_options() {
    print_status "Configurando NODE_OPTIONS..."
    
    # Configurar para bash
    if ! grep -q "NODE_OPTIONS" "$HOME/.bashrc" 2>/dev/null; then
        echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> "$HOME/.bashrc"
    fi
    
    # Configurar para fish se existir
    if [ -d "$HOME/.config/fish" ]; then
        if ! grep -q "NODE_OPTIONS" "$HOME/.config/fish/config.fish" 2>/dev/null; then
            echo 'set -gx NODE_OPTIONS "--max-old-space-size=4096"' >> "$HOME/.config/fish/config.fish"
        fi
    fi
    
    print_success "NODE_OPTIONS configurado"
}

# Função para instalar Fish Shell
install_fish() {
    print_status "Instalando Fish Shell..."
    
    if sudo apt-get install -y fish; then
        print_success "Fish Shell instalado com sucesso"
        
        # Criar diretório de configuração se não existir
        mkdir -p "$HOME/.config/fish"
        
        return 0
    else
        print_error "Falha na instalação do Fish Shell"
        return 1
    fi
}

# Função para instalar Starship
install_starship() {
    print_status "Instalando Starship..."
    
    # -y para instalação não-interativa
    if curl -sS https://starship.rs/install.sh | sh -s -- -y; then
        print_success "Starship instalado com sucesso"
        return 0
    else
        print_error "Falha ao instalar Starship"
        return 1
    fi
}

# Função para configurar arquivos do shell (config.fish e starship.toml)
configure_shell_files() {
    print_status "Configurando arquivos do shell..."
    
    # Garantir que os diretórios existem
    mkdir -p "$HOME/.config/fish"
    mkdir -p "$HOME/.config"
    
    # Copiar config.fish se existir nos assets
    if [ -f "$SCRIPT_DIR/assets/config.fish" ]; then
        cp "$SCRIPT_DIR/assets/config.fish" "$HOME/.config/fish/config.fish"
        print_success "config.fish configurado com sucesso"
    else
        print_warning "Arquivo assets/config.fish não encontrado"
    fi
    
    # Copiar starship.toml se existir nos assets
    if [ -f "$SCRIPT_DIR/assets/starship.toml" ]; then
        cp "$SCRIPT_DIR/assets/starship.toml" "$HOME/.config/starship.toml"
        print_success "starship.toml configurado com sucesso"
    else
        print_warning "Arquivo assets/starship.toml não encontrado"
    fi
}

main() {
    # Verifica se está rodando como root
    if [ "$EUID" -eq 0 ]; then 
        print_error "Não execute este script como root (sudo)!"
        exit 1
    fi

    print_status "Iniciando instalação do ambiente de desenvolvimento..."
    echo -e "${YELLOW}Este processo pode demorar alguns minutos...${NC}"

    # Atualização inicial do sistema
    print_status "Atualizando o sistema..."
    if sudo apt-get update && sudo apt-get upgrade -y; then
        print_success "Sistema atualizado com sucesso"
    else
        print_error "Falha na atualização do sistema"
    fi

    # Instalar pacotes básicos
    install_apt_package "curl"
    install_apt_package "wget"
    install_apt_package "git"
    install_apt_package "build-essential"
    install_apt_package "openjdk-21-jdk"
    install_apt_package "ansible"

    # Instalar Docker (deve ser antes de outros que dependem dele)
    install_docker

    # Instalar Terraform (repositório HashiCorp)
    install_terraform

    # Instalar kubectl
    install_kubectl

    # Instalar Minikube
    install_minikube

    # Instalar PostgreSQL
    install_postgresql

    # Configurar Docker Registry local
    setup_docker_registry

    # Instalar Fish Shell
    install_fish

    # Instalar Starship
    install_starship

    # Configurar arquivos do shell (config.fish e starship.toml)
    configure_shell_files

    # Instalar Mise
    install_mise

    # Configurar NODE_OPTIONS
    configure_node_options

    # Imprimir resumo final
    print_summary

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}PRÓXIMOS PASSOS:${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "\n${GREEN}1.${NC} Defina o Fish como shell padrão:"
    echo -e "   ${BLUE}chsh -s /usr/bin/fish${NC}"
    echo -e "\n${GREEN}2.${NC} Faça logout e login novamente para:"
    echo -e "   - Aplicar mudanças do grupo Docker"
    echo -e "   - Ativar o Fish Shell"
    echo -e "   - Carregar configurações do Starship"
    echo -e "\n${GREEN}3.${NC} Para iniciar o Minikube (após relogar):"
    echo -e "   ${BLUE}minikube start --driver=docker${NC}"
    echo -e "\n${GREEN}4.${NC} Execute o script de instalação do Mise:"
    echo -e "   ${BLUE}./mise_install.sh${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Executa o script
main
