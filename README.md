# 🚀 Shell Install Initial - Ambiente de Desenvolvimento Completo

Script automatizado para configuração de ambiente de desenvolvimento **Fullstack e DevOps** no Ubuntu/Debian.

## 📋 Índice

- [Ferramentas Instaladas](#-ferramentas-instaladas)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação](#-instalação)
- [Pós-Instalação](#-pós-instalação)
- [Estrutura do Projeto](#-estrutura-do-projeto)

---

## 🛠️ Ferramentas Instaladas

### **Desenvolvimento Base**

- ✅ **Build Essential** - Compiladores e ferramentas de build
- ✅ **OpenJDK 21** - Java Development Kit
- ✅ **Git** - Controle de versão
- ✅ **Curl & Wget** - Download de arquivos

### **Editores & IDEs**

- ✅ **Visual Studio Code** - Editor de código
- ✅ **IntelliJ IDEA Community** - IDE Java
- ✅ **Neovim** - Editor de texto moderno

### **Containers & Orquestração**

- ✅ **Docker** - Containerização
- ✅ **Docker Compose** - Orquestração de containers
- ✅ **Lazydocker** - Terminal UI para Docker
- ✅ **ctop** - Monitor de containers
- ✅ **Kubernetes (kubectl)** - CLI do Kubernetes
- ✅ **Helm** - Package manager para Kubernetes
- ✅ **k9s** - Terminal UI para Kubernetes
- ✅ **Minikube** - Kubernetes local

### **Bancos de Dados**

- ✅ **PostgreSQL** - Banco relacional
- ✅ **Redis Tools** - Cliente Redis
- ✅ **MySQL Client** - Cliente MySQL
- ✅ **MongoDB Shell** - Cliente MongoDB
- ✅ **DBeaver** - GUI universal para bancos de dados

### **Cloud CLIs**

- ✅ **AWS CLI** - Amazon Web Services
- ✅ **Google Cloud CLI** - Google Cloud Platform
- ✅ **Azure CLI** - Microsoft Azure

### **Infrastructure as Code**

- ✅ **Terraform** - Provisionamento de infraestrutura
- ✅ **Ansible** - Automação e configuração

### **CI/CD & Version Control**

- ✅ **GitHub CLI (gh)** - Interface CLI do GitHub
- ✅ **FZF** - Fuzzy finder para terminal

### **API Testing & Development**

- ✅ **Postman** - Cliente API
- ✅ **Insomnia** - Cliente API alternativo
- ✅ **HTTPie** - Cliente HTTP melhorado

### **Ferramentas de Produtividade**

- ✅ **Tmux** - Multiplexador de terminal
- ✅ **Ripgrep** - Busca rápida em arquivos
- ✅ **fd-find** - Find melhorado
- ✅ **jq** - Processador JSON
- ✅ **bat** - Cat melhorado
- ✅ **eza** - ls moderno
- ✅ **zoxide** - cd inteligente
- ✅ **htop** - Monitor de processos
- ✅ **ncdu** - Analisador de disco
- ✅ **tree** - Visualizador de árvore de diretórios

### **Network Tools**

- ✅ **net-tools** - Ferramentas de rede
- ✅ **nmap** - Scanner de rede
- ✅ **traceroute** - Rastreamento de rota
- ✅ **dnsutils** - Utilitários DNS
- ✅ **tcpdump** - Captura de pacotes

### **Security**

- ✅ **GnuPG** - Criptografia
- ✅ **pass** - Gerenciador de senhas
- ✅ **OpenSSH Server** - Servidor SSH

### **Terminal & Shell**

- ✅ **Starship** - Prompt moderno
- ✅ **Mise** - Gerenciador de versões de linguagens
- ✅ **Fish Shell** - Shell moderno (instalação manual)

### **Aplicativos Desktop**

- ✅ **Brave Browser** - Navegador web
- ✅ **Discord** - Comunicação
- ✅ **Flameshot** - Captura de tela
- ✅ **GNOME Tweaks** - Personalização do GNOME
- ✅ **Extension Manager** - Gerenciador de extensões GNOME

### **Fontes**

- ✅ **Fira Code** - Fonte com ligaduras para código

---

## 📦 Pré-requisitos

- Ubuntu 20.04+ ou Debian 11+
- Conexão com internet
- Permissões de sudo
- **NÃO execute como root**

---

## 🚀 Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/John-Mota/shell-instal-initial.git
cd shell-instal-initial
```

### 2. Torne o script executável

```bash
chmod +x install.sh
chmod +x mise_install.sh
```

### 3. Execute o script principal

```bash
./install.sh
```

⏱️ **Tempo estimado**: 30-60 minutos (dependendo da velocidade da internet)

---

## 🔧 Pós-Instalação

### 1. Instale o Fish Shell

```bash
sudo apt-get install fish
chsh -s /usr/bin/fish
```

### 2. Reinicie o sistema

```bash
sudo reboot
```

### 3. Configure o Mise (após reiniciar)

```bash
./mise_install.sh
```

Este script instalará via Mise:

- **Node.js LTS**
- **Python 3.12**
- **Go (latest)**
- **Rust (latest)**
- **Bun (latest)**
- **Deno (latest)**

### 4. Verifique as instalações

```bash
# Docker
docker --version
docker compose version

# Kubernetes
kubectl version --client
helm version
k9s version

# Cloud CLIs
aws --version
gcloud --version
az --version

# IaC
terraform --version
ansible --version

# Linguagens (após mise_install.sh)
node --version
python --version
go version
rustc --version
```

---

## 📁 Estrutura do Projeto

```
shell-instal-initial/
├── install.sh              # Script principal de instalação
├── mise_install.sh         # Script de configuração do Mise
├── README.md              # Este arquivo
├── install_log.txt        # Log gerado após instalação
└── assets/
    ├── config.fish        # Configuração do Fish Shell
    └── starship.toml      # Configuração do Starship
```

---

## 📊 Logs

Após a execução, um arquivo `install_log.txt` será gerado com:

- ✅ Lista de instalações bem-sucedidas
- ❌ Lista de falhas (se houver)
- 📅 Data e hora da execução

---

## 🔍 Troubleshooting

### Erro de permissão

```bash
# Certifique-se de NÃO usar sudo para executar o script
./install.sh  # ✅ Correto
sudo ./install.sh  # ❌ Errado
```

### Docker não funciona após instalação

```bash
# Reinicie o sistema ou faça logout/login
sudo reboot
```

### Fish Shell não é o padrão

```bash
# Defina como shell padrão
chsh -s /usr/bin/fish
# Faça logout e login novamente
```

---

## 🤝 Contribuindo

Sinta-se à vontade para abrir issues ou pull requests!

---

## 📝 Licença

MIT License - Sinta-se livre para usar e modificar.

---

## 👨‍💻 Autor

**John Mota**

---

## 🎯 Roadmap

- [ ] Adicionar suporte para Arch Linux
- [ ] Criar versão para macOS
- [ ] Adicionar opção de instalação seletiva
- [ ] Criar interface interativa
- [ ] Adicionar testes automatizados

---

**Feito com ❤️ para desenvolvedores Fullstack e DevOps**
