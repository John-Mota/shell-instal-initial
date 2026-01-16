#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Arrays para armazenar logs
declare -a SUCCESS_LOG=()
declare -a ERROR_LOG=()

# Diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Função para adicionar GPG key de forma segura
add_gpg_key() {
    local key_url=$1
    local key_file=$2
    
    # Remover chave antiga se existir
    sudo rm -f "$key_file" 2>/dev/null
    
    if curl -fsSL "$key_url" | sudo gpg --dearmor -o "$key_file"; then
        sudo chmod a+r "$key_file"
        return 0
    else
        return 1
    fi
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

# Função para instalar pacotes .deb
install_deb_package() {
    local package_name=$1
    local deb_url=$2
    local deb_file="/tmp/${package_name}.deb"
    
    print_status "Baixando e instalando $package_name..."
    
    # Limpar arquivo anterior se existir
    rm -f "$deb_file" 2>/dev/null
    
    if wget -O "$deb_file" "$deb_url" && \
       sudo dpkg -i "$deb_file" && \
       sudo apt-get install -f -y; then
        print_success "$package_name instalado com sucesso"
        rm -f "$deb_file"
        return 0
    else
        print_error "Falha ao instalar $package_name"
        rm -f "$deb_file"
        return 1
    fi
}

# Função para instalar flatpak
install_flatpak() {
    print_status "Instalando flatpak $1..."
    if flatpak install flathub "$1" -y --noninteractive 2>/dev/null; then
        print_success "Flatpak $1 instalado com sucesso"
        return 0
    else
        print_error "Falha ao instalar flatpak $1"
        return 1
    fi
}

# Função para exibir resumo final
print_summary() {
    echo -e "\n${GREEN}=== RESUMO DA INSTALAÇÃO ===${NC}"
    
    echo -e "\n${GREEN}Instalações bem-sucedidas (${#SUCCESS_LOG[@]}):${NC}"
    if [ ${#SUCCESS_LOG[@]} -eq 0 ]; then
        echo "Nenhuma instalação concluída com sucesso"
    else
        for success in "${SUCCESS_LOG[@]}"; do
            echo -e "${GREEN}✓${NC} $success"
        done
    fi
    
    echo -e "\n${RED}Falhas na instalação (${#ERROR_LOG[@]}):${NC}"
    if [ ${#ERROR_LOG[@]} -eq 0 ]; then
        echo "Nenhuma falha registrada"
    else
        for error in "${ERROR_LOG[@]}"; do
            echo -e "${RED}✗${NC} $error"
        done
    fi
    
    # Salvar logs em arquivo
    local log_file="$SCRIPT_DIR/install_log.txt"
    echo "=== Log de Instalação ===" > "$log_file"
    echo "Data: $(date)" >> "$log_file"
    echo -e "\nSucessos:" >> "$log_file"
    printf '%s\n' "${SUCCESS_LOG[@]}" >> "$log_file"
    echo -e "\nErros:" >> "$log_file"
    printf '%s\n' "${ERROR_LOG[@]}" >> "$log_file"
    
    echo -e "\nLog completo salvo em: $log_file"
}

# ============================================
# FUNÇÕES DE INSTALAÇÃO ESPECÍFICAS
# ============================================

install_docker() {
    print_status "Instalando Docker..."
    
    # Remover versões antigas
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Instalar dependências
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Adicionar chave GPG
    sudo mkdir -p /etc/apt/keyrings
    if ! add_gpg_key "https://download.docker.com/linux/ubuntu/gpg" "/etc/apt/keyrings/docker.gpg"; then
        print_error "Falha ao adicionar chave GPG do Docker"
        return 1
    fi
    
    # Adicionar repositório
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update
    
    if sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        print_success "Docker instalado com sucesso"
        
        # Configurar grupo Docker
        sudo groupadd docker 2>/dev/null || true
        sudo usermod -aG docker "$USER"
        sudo systemctl enable docker
        sudo systemctl start docker
        
        print_success "Grupo Docker configurado (relogin necessário)"
        return 0
    else
        print_error "Falha na instalação do Docker"
        return 1
    fi
}

install_postgresql() {
    print_status "Instalando PostgreSQL..."
    
    if sudo apt-get install -y postgresql postgresql-contrib; then
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        
        # Encontrar o arquivo pg_hba.conf correto
        local pg_hba_file
        pg_hba_file=$(sudo find /etc/postgresql -name "pg_hba.conf" 2>/dev/null | head -1)
        
        if [ -n "$pg_hba_file" ] && [ -f "$pg_hba_file" ]; then
            sudo sed -i 's/^local.*all.*all.*peer/local   all             all                                     md5/' "$pg_hba_file"
            sudo systemctl restart postgresql
            print_success "PostgreSQL instalado e configurado com sucesso"
        else
            print_warning "Arquivo pg_hba.conf não encontrado. Configure manualmente."
            print_success "PostgreSQL instalado com sucesso"
        fi
        return 0
    else
        print_error "Falha na instalação do PostgreSQL"
        return 1
    fi
}

install_mongodb_client() {
    print_status "Instalando MongoDB client..."
    
    if add_gpg_key "https://www.mongodb.org/static/pgp/server-7.0.asc" "/usr/share/keyrings/mongodb-server-7.0.gpg"; then
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | \
            sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        
        sudo apt-get update
        
        if sudo apt-get install -y mongodb-mongosh; then
            print_success "MongoDB client instalado com sucesso"
            return 0
        fi
    fi
    
    print_error "Falha ao instalar MongoDB client"
    return 1
}

install_kubectl() {
    print_status "Instalando kubectl..."
    
    sudo mkdir -p /etc/apt/keyrings
    
    if add_gpg_key "https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key" "/etc/apt/keyrings/kubernetes-apt-keyring.gpg"; then
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
            sudo tee /etc/apt/sources.list.d/kubernetes.list
        
        sudo apt-get update
        
        if sudo apt-get install -y kubectl; then
            print_success "kubectl instalado com sucesso"
            return 0
        fi
    fi
    
    print_error "Falha ao instalar kubectl"
    return 1
}

install_helm() {
    print_status "Instalando Helm..."
    
    if curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; then
        print_success "Helm instalado com sucesso"
        return 0
    else
        print_error "Falha ao instalar Helm"
        return 1
    fi
}

install_k9s() {
    print_status "Instalando k9s..."
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if wget -O "$temp_dir/k9s.tar.gz" "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz" && \
       tar -xzf "$temp_dir/k9s.tar.gz" -C "$temp_dir" && \
       sudo mv "$temp_dir/k9s" /usr/local/bin/; then
        print_success "k9s instalado com sucesso"
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Falha ao instalar k9s"
        rm -rf "$temp_dir"
        return 1
    fi
}

install_minikube() {
    print_status "Instalando Minikube..."
    
    local temp_file="/tmp/minikube-linux-amd64"
    
    if curl -Lo "$temp_file" https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
       sudo install "$temp_file" /usr/local/bin/minikube; then
        print_success "Minikube instalado com sucesso"
        rm -f "$temp_file"
        return 0
    else
        print_error "Falha ao instalar Minikube"
        rm -f "$temp_file"
        return 1
    fi
}

install_aws_cli() {
    print_status "Instalando AWS CLI..."
    
    # Verificar se unzip está instalado
    if ! command_exists unzip; then
        sudo apt-get install -y unzip
    fi
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$temp_dir/awscliv2.zip" && \
       unzip -q "$temp_dir/awscliv2.zip" -d "$temp_dir" && \
       sudo "$temp_dir/aws/install" --update; then
        print_success "AWS CLI instalado com sucesso"
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Falha ao instalar AWS CLI"
        rm -rf "$temp_dir"
        return 1
    fi
}

install_gcloud_cli() {
    print_status "Instalando Google Cloud CLI..."
    
    if add_gpg_key "https://packages.cloud.google.com/apt/doc/apt-key.gpg" "/usr/share/keyrings/cloud.google.gpg"; then
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
            sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
        
        sudo apt-get update
        
        if sudo apt-get install -y google-cloud-cli; then
            print_success "Google Cloud CLI instalado com sucesso"
            return 0
        fi
    fi
    
    print_error "Falha ao instalar Google Cloud CLI"
    return 1
}

install_azure_cli() {
    print_status "Instalando Azure CLI..."
    
    if curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash; then
        print_success "Azure CLI instalado com sucesso"
        return 0
    else
        print_error "Falha ao instalar Azure CLI"
        return 1
    fi
}

install_terraform() {
    print_status "Instalando Terraform..."
    
    if add_gpg_key "https://apt.releases.hashicorp.com/gpg" "/usr/share/keyrings/hashicorp-archive-keyring.gpg"; then
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
            sudo tee /etc/apt/sources.list.d/hashicorp.list
        
        sudo apt-get update
        
        if sudo apt-get install -y terraform; then
            print_success "Terraform instalado com sucesso"
            return 0
        fi
    fi
    
    print_error "Falha ao instalar Terraform"
    return 1
}

install_github_cli() {
    print_status "Instalando GitHub CLI..."
    
    if add_gpg_key "https://cli.github.com/packages/githubcli-archive-keyring.gpg" "/usr/share/keyrings/githubcli-archive-keyring.gpg"; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
            sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        
        sudo apt-get update
        
        if sudo apt-get install -y gh; then
            print_success "GitHub CLI instalado com sucesso"
            return 0
        fi
    fi
    
    print_error "Falha ao instalar GitHub CLI"
    return 1
}

install_lazydocker() {
    print_status "Instalando Lazydocker..."
    
    local version
    version=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    
    if [ -z "$version" ]; then
        print_error "Não foi possível obter versão do Lazydocker"
        return 1
    fi
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if curl -Lo "$temp_dir/lazydocker.tar.gz" "https://github.com/jesseduffield/lazydocker/releases/download/v${version}/lazydocker_${version}_Linux_x86_64.tar.gz" && \
       tar -xzf "$temp_dir/lazydocker.tar.gz" -C "$temp_dir" lazydocker && \
       sudo install "$temp_dir/lazydocker" /usr/local/bin; then
        print_success "Lazydocker instalado com sucesso"
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Falha ao instalar Lazydocker"
        rm -rf "$temp_dir"
        return 1
    fi
}

install_ctop() {
    print_status "Instalando ctop..."
    
    if sudo wget -q https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop && \
       sudo chmod +x /usr/local/bin/ctop; then
        print_success "ctop instalado com sucesso"
        return 0
    else
        print_error "Falha ao instalar ctop"
        return 1
    fi
}

install_mise() {
    print_status "Instalando Mise..."
    
    if curl https://mise.run | sh; then
        # Configurar para Fish (se existir)
        if [ -d "$HOME/.config/fish" ]; then
            if ! grep -q "mise activate" "$HOME/.config/fish/config.fish" 2>/dev/null; then
                echo 'eval (~/.local/bin/mise activate fish | source)' >> "$HOME/.config/fish/config.fish"
            fi
        fi
        
        # Configurar para Bash
        if ! grep -q "mise activate" "$HOME/.bashrc" 2>/dev/null; then
            echo 'eval "$(~/.local/bin/mise activate bash)"' >> "$HOME/.bashrc"
        fi
        
        print_success "Mise instalado com sucesso"
        return 0
    else
        print_error "Falha na instalação do Mise"
        return 1
    fi
}

install_fzf() {
    print_status "Instalando FZF..."
    
    local fzf_dir="$HOME/.fzf"
    
    # Remover instalação anterior se existir
    if [ -d "$fzf_dir" ]; then
        print_warning "FZF já existe. Atualizando..."
        cd "$fzf_dir" && git pull
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir"
    fi
    
    if "$fzf_dir/install" --all --no-update-rc; then
        print_success "FZF instalado com sucesso"
        return 0
    else
        print_error "Falha ao instalar FZF"
        return 1
    fi
}

install_starship() {
    print_status "Instalando Starship..."
    
    # -y para instalação não-interativa
    if curl -sS https://starship.rs/install.sh | sh -s -- -y; then
        # Garantir que diretórios existem
        mkdir -p "$HOME/.config"
        mkdir -p "$HOME/.config/fish"
        
        # Criar arquivo starship.toml se não existir
        touch "$HOME/.config/starship.toml"
        
        # Copiar configurações se existirem
        if [ -f "$SCRIPT_DIR/assets/config.fish" ]; then
            cp "$SCRIPT_DIR/assets/config.fish" "$HOME/.config/fish/config.fish"
        fi
        
        if [ -f "$SCRIPT_DIR/assets/starship.toml" ]; then
            cp "$SCRIPT_DIR/assets/starship.toml" "$HOME/.config/starship.toml"
        fi
        
        print_success "Starship instalado e configurado com sucesso"
        return 0
    else
        print_error "Falha ao instalar Starship"
        return 1
    fi
}

install_brave_browser() {
    print_status "Instalando Brave Browser..."
    
    if curl -fsS https://dl.brave.com/install.sh | sh; then
        print_success "Brave Browser instalado com sucesso"
        return 0
    else
        print_error "Falha na instalação do Brave Browser"
        return 1
    fi
}

# ============================================
# FUNÇÃO PRINCIPAL
# ============================================

main() {
    # Verifica se está rodando como root
    if [ "$EUID" -eq 0 ]; then 
        print_error "Não execute este script como root (sudo)!"
        exit 1
    fi

    print_status "Iniciando instalação do ambiente de desenvolvimento..."
    echo -e "${YELLOW}Este processo pode demorar vários minutos...${NC}"

    # Atualização inicial do sistema
    print_status "Atualizando o sistema..."
    if sudo apt-get update && sudo apt-get upgrade -y; then
        print_success "Sistema atualizado com sucesso"
    else
        print_error "Falha na atualização do sistema"
    fi

    # ============================================
    # PACOTES BÁSICOS
    # ============================================
    print_status "Instalando pacotes básicos..."
    
    install_apt_package "curl"
    install_apt_package "wget"
    install_apt_package "git"
    install_apt_package "unzip"
    install_apt_package "build-essential"
    install_apt_package "software-properties-common"
    install_apt_package "apt-transport-https"
    install_apt_package "gnupg"
    install_apt_package "lsb-release"
    install_apt_package "ca-certificates"
    
    # Java
    install_apt_package "openjdk-21-jdk"
    
    # Ferramentas CLI modernas
    install_apt_package "eza"
    install_apt_package "bat"
    install_apt_package "zoxide"

    # ============================================
    # FLATPAK
    # ============================================
    print_status "Verificando Flatpak..."
    
    if command_exists flatpak && flatpak remotes 2>/dev/null | grep -q "flathub"; then
        print_success "Flatpak já está configurado"
    else
        print_status "Configurando Flatpak..."
        install_apt_package "flatpak"
        install_apt_package "gnome-software-plugin-flatpak"
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        print_success "Flatpak configurado com sucesso"
    fi
    
    # Aplicativos Flatpak
    declare -a flatpak_apps=(
        "com.ktechpit.whatsie"
        "com.mattjakeman.ExtensionManager"
        "io.dbeaver.DBeaverCommunity"
        "io.github.brunofin.Cohesion"
        "com.discordapp.Discord"
        "md.obsidian.Obsidian"
        "com.jetbrains.IntelliJ-IDEA-Community"
        "io.github.ellie_commons.jorts"
        "com.spotify.Client"
    )

    for app in "${flatpak_apps[@]}"; do
        install_flatpak "$app"
    done

    # ============================================
    # DOCKER
    # ============================================
    install_docker

    # ============================================
    # UTILITÁRIOS DESKTOP
    # ============================================
    install_apt_package "flameshot"
    install_apt_package "fonts-firacode"
    install_apt_package "gnome-tweaks"
    install_apt_package "zoxide"
    install_apt_package "eza"
    install_apt_package "bat"

    # ============================================
    # POSTGRESQL
    # ============================================
    install_postgresql

    # ============================================
    # DATABASE CLIENTS
    # ============================================
    print_status "Instalando clientes de banco de dados..."
    
    install_apt_package "redis-tools"
    install_apt_package "mysql-client"
    install_mongodb_client

    # ============================================
    # PRODUCTIVITY TOOLS
    # ============================================
    print_status "Instalando ferramentas de produtividade..."
    
    install_apt_package "tmux"
    install_apt_package "neovim"
    install_apt_package "ripgrep"
    install_apt_package "fd-find"
    install_apt_package "jq"
    install_apt_package "tree"
    install_apt_package "htop"
    install_apt_package "ncdu"
    install_apt_package "httpie"

    # ============================================
    # NETWORK TOOLS
    # ============================================
    print_status "Instalando ferramentas de rede..."
    
    install_apt_package "net-tools"
    install_apt_package "nmap"
    install_apt_package "traceroute"
    install_apt_package "dnsutils"
    install_apt_package "tcpdump"

    # ============================================
    # SECURITY TOOLS
    # ============================================
    print_status "Instalando ferramentas de segurança..."
    
    install_apt_package "pass"
    install_apt_package "openssh-server"

    # ============================================
    # KUBERNETES TOOLS
    # ============================================
    print_status "Instalando ferramentas Kubernetes..."
    
    install_kubectl
    install_helm
    install_k9s
    install_minikube

    # ============================================
    # CLOUD CLIs
    # ============================================
    print_status "Instalando Cloud CLIs..."
    
    install_aws_cli
    install_gcloud_cli
    install_azure_cli

    # ============================================
    # INFRASTRUCTURE AS CODE
    # ============================================
    print_status "Instalando ferramentas IaC..."
    
    install_terraform
    install_apt_package "ansible"

    # ============================================
    # CI/CD TOOLS
    # ============================================
    install_github_cli

    # ============================================
    # CONTAINER & DOCKER TOOLS
    # ============================================
    print_status "Instalando ferramentas para containers..."
    
    install_lazydocker
    install_ctop


    # ============================================
    # DEB PACKAGES
    # ============================================
    install_deb_package "vscode" "https://go.microsoft.com/fwlink/?LinkID=760868"
    install_deb_package "discord" "https://discord.com/api/download?platform=linux&format=deb"

    # ============================================
    # SHELL & TERMINAL TOOLS
    # ============================================
    install_mise
    install_brave_browser
    install_fzf
    install_starship

    # ============================================
    # RESUMO E PRÓXIMOS PASSOS
    # ============================================
    print_summary
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}PRÓXIMOS PASSOS:${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "\n${GREEN}1.${NC} Instale o Fish Shell:"
    echo -e "   ${BLUE}sudo apt-get install fish${NC}"
    echo -e "   ${BLUE}chsh -s /usr/bin/fish${NC}"
    echo -e "\n${GREEN}2.${NC} Faça logout e login novamente para:"
    echo -e "   - Aplicar mudanças do grupo Docker"
    echo -e "   - Ativar o Fish Shell (se instalado)"
    echo -e "\n${GREEN}3.${NC} Após reiniciar, execute o script de configuração do Mise:"
    echo -e "   ${BLUE}./mise_install.sh${NC}"
    echo -e "\n${YELLOW}IMPORTANTE:${NC} Alguns aplicativos Flatpak podem necessitar reiniciar o sistema."
    echo -e "${BLUE}========================================${NC}\n"
}

# Executa o script
main
