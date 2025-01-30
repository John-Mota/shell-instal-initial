# 🚀 Script de Instalação do Ambiente de Desenvolvimento

Este script automatiza a configuração de um ambiente de desenvolvimento completo para Ubuntu, instalando e configurando todas as ferramentas necessárias.

## ✨ Funcionalidades

O script instala e configura:

### 🛠️ Ferramentas de Desenvolvimento

- Docker e Docker Compose
- PostgreSQL (com usuário padrão configurado)
- Visual Studio Code
- Mise (gerenciador de versões)
- Postman
- DBeaver
- IntelliJ IDEA Community

### 🌐 Navegadores

- Braver Browser

### 💻 Utilitários

- Flameshot (capturas de tela)
- Gnome Tweaks
- Fonte Fira Code
- Extension Manager

### 📱 Aplicativos

- WhatsApp Desktop
- Deezer
- OnlyOffice
- SpeechNote
- Sticky Notes
- DevToolbox
- Cohesion

## 📋 Pré-requisitos

- Ubuntu 22.04 LTS ou superior
- Conexão com a internet
- Privilégios de administrador (sudo)

## 🚀 Como Usar

1. Baixe o script:

```bash
wget https://raw.githubusercontent.com/seu-usuario/seu-repo/main/setup.sh
```

2. Dê permissão de execução:

```bash
chmod +x setup.sh
```

3. Execute o script:

```bash
./setup.sh
```

## ⚙️ Configurações Realizadas

O script realiza as seguintes configurações:

- Configura o Docker para executar sem sudo
- Cria usuário no PostgreSQL com nome 'john'
- Configura DNS personalizado
- Aumenta o limite de memória do Node.js
- Instala e configura o Flatpak

## ⚠️ Observações Importantes

1. Faça backup dos seus dados antes de executar
2. O script solicitará sua senha sudo algumas vezes
3. A instalação pode demorar dependendo da sua internet
4. Reinicie o computador após a conclusão

## 🔄 Manutenção

Para manter seu ambiente atualizado:

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Atualizar Flatpak
flatpak update
```

## 🐛 Resolução de Problemas

Se encontrar problemas:

1. Verifique se tem permissões de sudo
2. Confira sua conexão com a internet
3. Verifique se os serviços estão rodando:
   ```bash
   sudo systemctl status docker
   sudo systemctl status postgresql
   ```

## 📝 Licença

Este projeto está sob a licença MIT.
