#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para imprimir mensagens de status
print_status() {
    echo -e "\n${BLUE}[INFO] $1${NC}"
}

# Função para imprimir mensagens de sucesso
print_success() {
    echo -e "${GREEN}[SUCESSO] $1${NC}"
}

# Função para imprimir mensagens de erro
print_error() {
    echo -e "${RED}[ERRO] $1${NC}"
}

main() {
    print_status "Configurando Mise para gerenciamento de versões..."
    
    # Verifica se o Mise está instalado
    if ! command -v mise &> /dev/null; then
        print_error "Mise não está instalado. Execute o script install.sh primeiro."
        exit 1
    fi
    
    print_success "Mise encontrado!"
    
    # Node.js
    print_status "Instalando Node.js LTS via Mise"
    if mise use --global node@lts; then
        print_success "Node.js LTS instalado com sucesso"
    else
        print_error "Falha ao instalar Node.js"
    fi
    
    # Python
    print_status "Instalando Python 3.12 via Mise"
    if mise use --global python@3.12; then
        print_success "Python 3.12 instalado com sucesso"
    else
        print_error "Falha ao instalar Python"
    fi
    
    # Go
    print_status "Instalando Go latest via Mise"
    if mise use --global go@latest; then
        print_success "Go instalado com sucesso"
    else
        print_error "Falha ao instalar Go"
    fi
    
    # Rust
    print_status "Instalando Rust latest via Mise"
    if mise use --global rust@latest; then
        print_success "Rust instalado com sucesso"
    else
        print_error "Falha ao instalar Rust"
    fi
    
    # Bun (runtime JavaScript alternativo)
    print_status "Instalando Bun latest via Mise"
    if mise use --global bun@latest; then
        print_success "Bun instalado com sucesso"
    else
        print_error "Falha ao instalar Bun"
    fi
    
    # Deno (runtime JavaScript/TypeScript)
    print_status "Instalando Deno latest via Mise"
    if mise use --global deno@latest; then
        print_success "Deno instalado com sucesso"
    else
        print_error "Falha ao instalar Deno"
    fi
    
    # Verificar instalações
    print_status "Verificando versões instaladas..."
    echo ""
    
    if command -v node &> /dev/null; then
        echo -e "${GREEN}Node.js:${NC} $(node --version)"
        echo -e "${GREEN}npm:${NC} $(npm --version)"
    fi
    
    if command -v python &> /dev/null; then
        echo -e "${GREEN}Python:${NC} $(python --version)"
    fi
    
    if command -v go &> /dev/null; then
        echo -e "${GREEN}Go:${NC} $(go version)"
    fi
    
    if command -v rustc &> /dev/null; then
        echo -e "${GREEN}Rust:${NC} $(rustc --version)"
    fi
    
    if command -v bun &> /dev/null; then
        echo -e "${GREEN}Bun:${NC} $(bun --version)"
    fi
    
    if command -v deno &> /dev/null; then
        echo -e "${GREEN}Deno:${NC} $(deno --version | head -n 1)"
    fi
    
    echo ""
    print_success "Configuração do Mise concluída!"
    print_status "Reinicie seu terminal ou execute: source ~/.config/fish/config.fish"
}

# Executa o script
main
