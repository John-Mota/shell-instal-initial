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
    install_apt_package "eza"
    install_apt_package "bat"
    install_apt_package "zoxide"

     # Flatpak
    print_status "Verificando Flatpak"
    
    # Verifica se o Flatpak já está instalado e configurado
    if command -v flatpak &> /dev/null && flatpak remotes | grep -q "flathub"; then
        print_success "Flatpak já está configurado"
        
        # Instalação de aplicativos Flatpak
        declare -a flatpak_apps=(
            "com.ktechpit.whatsie"
            "com.mattjakeman.ExtensionManager"
            "io.dbeaver.DBeaverCommunity"
            "io.github.brunofin.Cohesion"
            "io.github.lainsce.Notejot"
            "com.discordapp.Discord"
            "md.obsidian.Obsidian"
            "org.onlyoffice.desktopeditors"
        )

        for app in "${flatpak_apps[@]}"; do
            install_flatpak "$app"
        done
    else
        print_status "Configurando Flatpak"
        if {
            install_apt_package "flatpak" &&
            install_apt_package "gnome-software-plugin-flatpak" &&
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        }; then
            print_success "Flatpak configurado com sucesso"

            # Instalação de aplicativos Flatpak
            declare -a flatpak_apps=(
                "com.mattjakeman.ExtensionManager"
                "io.dbeaver.DBeaverCommunity"
            )

            for app in "${flatpak_apps[@]}"; do
                install_flatpak "$app"
            done
        else
            print_error "Falha na configuração do Flatpak"
        fi
    fi

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

    # Flameshot
    install_apt_package "flameshot"
    
    # Fira code
    install_apt_package "fonts-firacode"

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

    # ============================================
    # DATABASE CLIENTS
    # ============================================
    print_status "Instalando clientes de banco de dados"
    
    install_apt_package "redis-tools"
    install_apt_package "mysql-client"
    
    # MongoDB client
    print_status "Instalando MongoDB client"
    if {
        curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg &&
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list &&
        sudo apt-get update &&
        sudo apt-get install -y mongodb-mongosh
    }; then
        print_success "MongoDB client instalado com sucesso"
    else
        print_error "Falha ao instalar MongoDB client"
    fi

    # ============================================
    # PRODUCTIVITY TOOLS
    # ============================================
    print_status "Instalando ferramentas de produtividade"
    
    install_apt_package "tmux"
    install_apt_package "neovim"
    install_apt_package "ripgrep"
    install_apt_package "fd-find"
    install_apt_package "jq"
    install_apt_package "tree"
    install_apt_package "htop"
    install_apt_package "ncdu"
    
    # HTTPie - cliente HTTP melhorado
    install_apt_package "httpie"

    # ============================================
    # NETWORK TOOLS
    # ============================================
    print_status "Instalando ferramentas de rede"
    
    install_apt_package "net-tools"
    install_apt_package "nmap"
    install_apt_package "traceroute"
    install_apt_package "dnsutils"
    install_apt_package "tcpdump"

    # ============================================
    # SECURITY TOOLS
    # ============================================
    print_status "Instalando ferramentas de segurança"
    
    install_apt_package "gnupg"
    install_apt_package "pass"
    install_apt_package "openssh-server"

    # ============================================
    # KUBERNETES TOOLS
    # ============================================
    print_status "Instalando ferramentas Kubernetes"
    
    # kubectl
    print_status "Instalando kubectl"
    if {
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg &&
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list &&
        sudo apt-get update &&
        sudo apt-get install -y kubectl
    }; then
        print_success "kubectl instalado com sucesso"
    else
        print_error "Falha ao instalar kubectl"
    fi
    
    # Helm
    print_status "Instalando Helm"
    if curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; then
        print_success "Helm instalado com sucesso"
    else
        print_error "Falha ao instalar Helm"
    fi
    
    # k9s
    print_status "Instalando k9s"
    if {
        K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') &&
        wget -O k9s.tar.gz "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz" &&
        tar -xzf k9s.tar.gz &&
        sudo mv k9s /usr/local/bin/ &&
        rm k9s.tar.gz
    }; then
        print_success "k9s instalado com sucesso"
    else
        print_error "Falha ao instalar k9s"
    fi
    
    # Minikube
    print_status "Instalando Minikube"
    if {
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 &&
        sudo install minikube-linux-amd64 /usr/local/bin/minikube &&
        rm minikube-linux-amd64
    }; then
        print_success "Minikube instalado com sucesso"
    else
        print_error "Falha ao instalar Minikube"
    fi

    # ============================================
    # CLOUD CLIs
    # ============================================
    print_status "Instalando Cloud CLIs"
    
    # AWS CLI
    print_status "Instalando AWS CLI"
    if {
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&
        unzip -q awscliv2.zip &&
        sudo ./aws/install &&
        rm -rf aws awscliv2.zip
    }; then
        print_success "AWS CLI instalado com sucesso"
    else
        print_error "Falha ao instalar AWS CLI"
    fi
    
    # Google Cloud CLI
    print_status "Instalando Google Cloud CLI"
    if {
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg &&
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list &&
        sudo apt-get update &&
        sudo apt-get install -y google-cloud-cli
    }; then
        print_success "Google Cloud CLI instalado com sucesso"
    else
        print_error "Falha ao instalar Google Cloud CLI"
    fi
    
    # Azure CLI
    print_status "Instalando Azure CLI"
    if {
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    }; then
        print_success "Azure CLI instalado com sucesso"
    else
        print_error "Falha ao instalar Azure CLI"
    fi

    # ============================================
    # INFRASTRUCTURE AS CODE
    # ============================================
    print_status "Instalando ferramentas IaC"
    
    # Terraform
    print_status "Instalando Terraform"
    if {
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg &&
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list &&
        sudo apt-get update &&
        sudo apt-get install -y terraform
    }; then
        print_success "Terraform instalado com sucesso"
    else
        print_error "Falha ao instalar Terraform"
    fi
    
    # Ansible
    install_apt_package "ansible"

    # ============================================
    # CI/CD TOOLS
    # ============================================
    print_status "Instalando ferramentas CI/CD"
    
    # GitHub CLI
    print_status "Instalando GitHub CLI"
    if {
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null &&
        sudo apt-get update &&
        sudo apt-get install -y gh
    }; then
        print_success "GitHub CLI instalado com sucesso"
    else
        print_error "Falha ao instalar GitHub CLI"
    fi

    # ============================================
    # CONTAINER & DOCKER TOOLS
    # ============================================
    print_status "Instalando ferramentas para containers"
    
    # Lazydocker
    print_status "Instalando Lazydocker"
    if {
        LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') &&
        curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz" &&
        tar -xzf lazydocker.tar.gz lazydocker &&
        sudo install lazydocker /usr/local/bin &&
        rm lazydocker lazydocker.tar.gz
    }; then
        print_success "Lazydocker instalado com sucesso"
    else
        print_error "Falha ao instalar Lazydocker"
    fi
    
    # ctop
    print_status "Instalando ctop"
    if {
        sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop &&
        sudo chmod +x /usr/local/bin/ctop
    }; then
        print_success "ctop instalado com sucesso"
    else
        print_error "Falha ao instalar ctop"
    fi

    # ============================================
    # ADDITIONAL DEV TOOLS
    # ============================================
    print_status "Instalando ferramentas adicionais de desenvolvimento"
    
    # Postman (via Snap)
    print_status "Instalando Postman"
    if sudo snap install postman; then
        print_success "Postman instalado com sucesso"
    else
        print_error "Falha ao instalar Postman"
    fi
    
    # Insomnia (API client alternativo)
    print_status "Instalando Insomnia"
    if sudo snap install insomnia; then
        print_success "Insomnia instalado com sucesso"
    else
        print_error "Falha ao instalar Insomnia"
    fi

    # GNOME Tweaks
    install_apt_package "gnome-tweak-tool"

    # VSCode
    install_deb_package "vscode" "https://go.microsoft.com/fwlink/?LinkID=760868"

    # Discord
    install_deb_package "discord" "https://discord.com/api/download?platform=linux&format=deb"

    # Mise
    print_status "Instalando Mise"
    if curl https://mise.run | sh; then
        echo 'eval "$(~/.local/bin/mise activate fish | source)"' >> ~/.config/fish/config.fish
        print_success "Mise instalado com sucesso"
    else
        print_error "Falha na instalação do Mise"
    fi

    # Brave Browser
    print_status "Instalando Brave Browser"
    if curl -fsS https://dl.brave.com/install.sh | sh; then
        print_success "Brave Browser instalado com sucesso"
    else
        print_error "Falha na instalação do Brave Browser"
    fi
    
    # Intelij
    print_status "Instalando Intellij-community"
    if sudo snap install intellij-idea-community --classic; then
        print_success "Intellij-community instalado com sucesso"
    else
        print_error "Falha na instalação do Intellij-community"
    fi

    # Install FZF
    print_status "Instalando FZF"
    if git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all; then
        print_success "FZF instalado com sucesso"
    else
        print_error "Falha ao instalar FZF"
    fi

    # Configurar StarShip
    print_status "Configurando Starship"
    if curl -sS https://starship.rs/install.sh | sh; then
        mkdir -p ~/.config && touch ~/.config/starship.toml
        cp "assets/config.fish" ~/.config/fish/config.fish
        cp "assets/starship.toml" ~/.config/starship.toml
        print_success "Starship configurado com sucesso"
    else
        print_error "Falha ao configurar Starship"
    fi

    # Imprimir resumo final
    print_summary
    
    # Mensagens finais
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}PRÓXIMOS PASSOS:${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "\n${GREEN}1.${NC} Instale o Fish Shell manualmente:"
    echo -e "   ${BLUE}sudo apt-get install fish${NC}"
    echo -e "   ${BLUE}chsh -s /usr/bin/fish${NC}"
    echo -e "\n${GREEN}2.${NC} Reinicie o sistema para aplicar todas as configurações"
    echo -e "\n${GREEN}3.${NC} Após reiniciar, execute o script de configuração do Mise:"
    echo -e "   ${BLUE}./mise_install.sh${NC}"
    echo -e "\n${BLUE}========================================${NC}\n"
}

# Executa o script
main
