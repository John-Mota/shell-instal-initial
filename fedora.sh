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

# Função para instalar pacotes dnf
install_dnf_package() {
    print_status "Instalando $1..."
    if sudo dnf install -y "$1" 2>/dev/null; then
        print_success "Pacote $1 instalado com sucesso"
        return 0
    else
        print_error "Falha ao instalar pacote $1"
        return 1
    fi
}

# Função para instalar pacotes .rpm
install_rpm_package() {
    local package_name=$1
    local rpm_url=$2
    local rpm_file="/tmp/${package_name}.rpm"
    
    print_status "Baixando e instalando $package_name..."
    
    # Limpar arquivo anterior se existir
    rm -f "$rpm_file" 2>/dev/null
    
    if wget -O "$rpm_file" "$rpm_url" && \
       sudo dnf install -y "$rpm_file"; then
        print_success "$package_name instalado com sucesso"
        rm -f "$rpm_file"
        return 0
    else
        print_error "Falha ao instalar $package_name"
        rm -f "$rpm_file"
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
    sudo dnf remove -y docker docker-client docker-client-latest docker-common \
        docker-latest docker-latest-logrotate docker-logrotate docker-selinux \
        docker-engine-selinux docker-engine 2>/dev/null || true
    
    # Instalar dependências
    sudo dnf install -y dnf-plugins-core
    
    # Adicionar repositório Docker
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    
    if sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
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
    
    if sudo dnf install -y postgresql-server postgresql-contrib; then
        # Inicializar banco de dados
        sudo postgresql-setup --initdb 2>/dev/null || true
        
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        
        # Encontrar o arquivo pg_hba.conf correto
        local pg_hba_file="/var/lib/pgsql/data/pg_hba.conf"
        
        if [ -f "$pg_hba_file" ]; then
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
    
    # Criar arquivo de repositório MongoDB
    cat <<EOF | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
    
    if sudo dnf install -y mongodb-mongosh; then
        print_success "MongoDB client instalado com sucesso"
        return 0
    fi
    
    print_error "Falha ao instalar MongoDB client"
    return 1
}

install_kubectl() {
    print_status "Instalando kubectl..."
    
    # Criar repositório Kubernetes
    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF
    
    if sudo dnf install -y kubectl; then
        print_success "kubectl instalado com sucesso"
        return 0
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
        sudo dnf install -y unzip
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
    
    # Criar repositório Google Cloud
    cat <<EOF | sudo tee /etc/yum.repos.d/google-cloud-sdk.repo
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    
    if sudo dnf install -y google-cloud-cli; then
        print_success "Google Cloud CLI instalado com sucesso"
        return 0
    fi
    
    print_error "Falha ao instalar Google Cloud CLI"
    return 1
}

install_azure_cli() {
    print_status "Instalando Azure CLI..."
    
    # Importar chave GPG da Microsoft
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    
    # Adicionar repositório
    cat <<EOF | sudo tee /etc/yum.repos.d/azure-cli.repo
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    
    if sudo dnf install -y azure-cli; then
        print_success "Azure CLI instalado com sucesso"
        return 0
    else
        print_error "Falha ao instalar Azure CLI"
        return 1
    fi
}

install_terraform() {
    print_status "Instalando Terraform..."
    
    # Adicionar repositório HashiCorp
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    
    if sudo dnf install -y terraform; then
        print_success "Terraform instalado com sucesso"
        return 0
    fi
    
    print_error "Falha ao instalar Terraform"
    return 1
}

install_github_cli() {
    print_status "Instalando GitHub CLI..."
    
    sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    
    if sudo dnf install -y gh; then
        print_success "GitHub CLI instalado com sucesso"
        return 0
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
    
    # Adicionar repositório Brave
    sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    
    if sudo dnf install -y brave-browser; then
        print_success "Brave Browser instalado com sucesso"
        return 0
    else
        print_error "Falha na instalação do Brave Browser"
        return 1
    fi
}

install_antigravity() {
    print_status "Instalando Antigravity..."

    # Tentar via repositório RPM primeiro
    cat <<EOF | sudo tee /etc/yum.repos.d/antigravity.repo
[antigravity]
name=Antigravity
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=1
gpgkey=https://us-central1-yum.pkg.dev/doc/repo-signing-key.gpg
EOF

    if sudo dnf install -y antigravity 2>/dev/null; then
        print_success "Antigravity instalado com sucesso via RPM"
        return 0
    fi
    
    # Fallback: tentar baixar binário diretamente ou via script oficial
    print_warning "Repositório RPM não disponível, tentando instalação alternativa..."
    sudo rm -f /etc/yum.repos.d/antigravity.repo 2>/dev/null
    
    # Tentar via npm (se disponível)
    if command_exists npm; then
        if npm install -g @anthropic/antigravity 2>/dev/null; then
            print_success "Antigravity instalado via npm"
            return 0
        fi
    fi
    
    print_error "Falha ao instalar Antigravity - instale manualmente"
    return 1
}

install_flutter() {
    print_status "Instalando Flutter SDK..."

    # Dependências do Flutter (Fedora)
    local flutter_deps=(
        "curl" "git" "unzip" "xz" "zip" "mesa-libGLU"
        "clang" "cmake" "ninja-build" "pkgconfig" "gtk3-devel"
    )

    for dep in "${flutter_deps[@]}"; do
        install_dnf_package "$dep"
    done

    # Diretório de instalação (Local do usuário)
    local dev_dir="$HOME/development"
    local flutter_dir="$dev_dir/flutter"
    mkdir -p "$dev_dir"

    # Baixar/Atualizar Flutter
    if [ -d "$flutter_dir" ]; then
        print_warning "Diretório flutter já existe. Atualizando..."
        cd "$flutter_dir" && git pull
    else
        print_status "Clonando repositório do Flutter (stable)..."
        git clone https://github.com/flutter/flutter.git -b stable "$flutter_dir"
    fi

    # Configurar PATH e Variáveis
    local flutter_bin="$flutter_dir/bin"
    
    # Adicionar ao PATH atual para uso imediato no script
    export PATH="$PATH:$flutter_bin"
    
    # Persistir no .bashrc
    if ! grep -q "flutter/bin" "$HOME/.bashrc"; then
        echo -e "\n# Flutter SDK Configuration" >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:$flutter_bin\"" >> "$HOME/.bashrc"
        echo "export CHROME_EXECUTABLE=\"/usr/bin/google-chrome-stable\"" >> "$HOME/.bashrc"
    fi

    # Persistir no config.fish
    local fish_config="$HOME/.config/fish/config.fish"
    if [ -f "$fish_config" ]; then
        if ! grep -q "flutter/bin" "$fish_config"; then
            echo -e "\n# Flutter SDK Configuration" >> "$fish_config"
            echo "set -gx PATH \$PATH $flutter_bin" >> "$fish_config"
            echo "set -gx CHROME_EXECUTABLE /usr/bin/google-chrome-stable" >> "$fish_config"
        fi
    fi

    # Configurar diretório seguro no git
    git config --global --add safe.directory "$flutter_dir"

    # Precache de binários (downloads necessários)
    print_status "Executando flutter precache..."
    "$flutter_bin/flutter" precache

    # Habilitar web
    print_status "Habilitando suporte web..."
    "$flutter_bin/flutter" config --enable-web
    
    # Tentar instalar extensão do Flutter no VSCode se o code estiver disponível
    if command_exists code; then
        print_status "Instalando extensões do VSCode para Flutter..."
        code --install-extension dart-code.flutter --force
        code --install-extension dart-code.dart-code --force
    fi

    print_success "Flutter SDK instalado e configurado"
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
    if sudo dnf update -y; then
        print_success "Sistema atualizado com sucesso"
    else
        print_error "Falha na atualização do sistema"
    fi

    # ============================================
    # PACOTES BÁSICOS
    # ============================================
    print_status "Instalando pacotes básicos..."
    
    install_dnf_package "curl"
    install_dnf_package "wget"
    install_dnf_package "git"
    install_dnf_package "unzip"
    install_dnf_package "gcc"
    install_dnf_package "gcc-c++"
    install_dnf_package "make"
    install_dnf_package "dnf-plugins-core"
    install_dnf_package "gnupg2"
    install_dnf_package "ca-certificates"
    
    # Java
    install_dnf_package "java-21-openjdk-devel"
    
    # Ferramentas CLI modernas
    install_dnf_package "eza"
    install_dnf_package "bat"
    install_dnf_package "zoxide"

    # ============================================
    # FLATPAK
    # ============================================
    print_status "Verificando Flatpak..."
    
    if command_exists flatpak && flatpak remotes 2>/dev/null | grep -q "flathub"; then
        print_success "Flatpak já está configurado"
    else
        print_status "Configurando Flatpak..."
        install_dnf_package "flatpak"
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
    install_dnf_package "flameshot"
    install_dnf_package "fira-code-fonts"
    install_dnf_package "gnome-tweaks"
    install_dnf_package "zoxide"
    install_dnf_package "eza"
    install_dnf_package "bat"

    # ============================================
    # POSTGRESQL
    # ============================================
    install_postgresql

    # ============================================
    # DATABASE CLIENTS
    # ============================================
    print_status "Instalando clientes de banco de dados..."
    
    install_dnf_package "redis"
    install_dnf_package "mariadb"
    install_mongodb_client

    # ============================================
    # PRODUCTIVITY TOOLS
    # ============================================
    print_status "Instalando ferramentas de produtividade..."
    
    install_dnf_package "tmux"
    install_dnf_package "neovim"
    install_dnf_package "ripgrep"
    install_dnf_package "fd-find"
    install_dnf_package "jq"
    install_dnf_package "tree"
    install_dnf_package "htop"
    install_dnf_package "ncdu"
    install_dnf_package "httpie"

    # ============================================
    # NETWORK TOOLS
    # ============================================
    print_status "Instalando ferramentas de rede..."
    
    install_dnf_package "net-tools"
    install_dnf_package "nmap"
    install_dnf_package "traceroute"
    install_dnf_package "bind-utils"
    install_dnf_package "tcpdump"

    # ============================================
    # SECURITY TOOLS
    # ============================================
    print_status "Instalando ferramentas de segurança..."
    
    install_dnf_package "pass"
    install_dnf_package "openssh-server"

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
    install_dnf_package "ansible"

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
    # ANTIGRAVITY
    # ============================================
    install_antigravity

    # ============================================
    # RPM PACKAGES
    # ============================================
    install_rpm_package "vscode" "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"
    install_rpm_package "google-chrome-stable" "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"

    # ============================================
    # SHELL & TERMINAL TOOLS
    # ============================================
    install_starship
    install_mise
    install_brave_browser
    install_fzf

    # ============================================
    # FLUTTER SDK
    # ============================================
    install_flutter

    # ============================================
    # RESUMO E PRÓXIMOS PASSOS
    # ============================================
    print_summary
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}PRÓXIMOS PASSOS:${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "\n${GREEN}1.${NC} Instale o Fish Shell:"
    echo -e "   ${BLUE}sudo dnf install fish${NC}"
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