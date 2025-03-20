#Script de segurança que cria usuario e ativa envio de e-mail so logr com root

###############################################################
# verifica se o usuário itconnectadm existe. Se o usuário não existir, ele será 
# criado, terá uma senha definida e será adicionado ao grupo sudo.

#!/bin/bash

# Nome do usuário
USERNAME="itconnectadm"
# Senha do usuário
PASSWORD="96PO08as@!!(&(4132"
# Diretório .ssh do usuário
USER_SSH_DIR="/home/$USERNAME/.ssh"
# Arquivo de chave SSH
SSH_KEY_FILE="$USER_SSH_DIR/id_rsa"
# Chave compartilhada para adicionar ao arquivo authorized_keys
SHARED_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCgTIvKmBuLmBkTLuy0KnnkJaDtspLkCkkImOmTXn6bQ7M/amL6NJqiqR0XeQ3w23Z5UjU/bzfolle8ins6oqKhkKB30khxVm6EISfLv1R/pc5GgiyjUGsiE40"

# Verifica se o usuário já existe
if id "$USERNAME" &>/dev/null; then
    echo "O usuário $USERNAME já existe."
    # Troca a senha do usuário existente
    echo "$USERNAME:$PASSWORD" | chpasswd
    echo "Senha do usuário $USERNAME atualizada."

    # Verifica se o usuário já está no grupo sudo
    if groups "$USERNAME" | grep -q '\bsudo\b'; then
        echo "O usuário $USERNAME já está no grupo sudo."
    else
        # Adiciona o usuário ao grupo sudo
        usermod -aG sudo "$USERNAME"
        echo "Usuário $USERNAME adicionado ao grupo sudo."
    fi
else
    # Adiciona o usuário
    adduser --gecos "" --disabled-password "$USERNAME"
    # Define a senha para o usuário
    echo "$USERNAME:$PASSWORD" | chpasswd
    # Adiciona o usuário ao grupo sudo
    usermod -aG sudo "$USERNAME"
    echo "Usuário $USERNAME criado, senha definida e adicionado ao grupo sudo."
fi

# Cria o diretório .ssh e define as permissões corretas
if [ ! -d "$USER_SSH_DIR" ]; then
    mkdir -p "$USER_SSH_DIR"
    chown "$USERNAME:$USERNAME" "$USER_SSH_DIR"
    chmod 700 "$USER_SSH_DIR"
    echo "Diretório .ssh criado para o usuário $USERNAME."
fi

# Gera a chave SSH se ela não existir
if [ ! -f "$SSH_KEY_FILE" ]; then
    ssh-keygen -t rsa -b 4096 -C "$USERNAME@$(hostname)" -f "$SSH_KEY_FILE" -N ""
    chown "$USERNAME:$USERNAME" "$SSH_KEY_FILE" "$SSH_KEY_FILE.pub"
    chmod 600 "$SSH_KEY_FILE"
    chmod 644 "$SSH_KEY_FILE.pub"
    echo "Chave SSH gerada para o usuário $USERNAME."
else
    echo "Chave SSH já existe para o usuário $USERNAME."
fi

# Verifica se a chave compartilhada já está no arquivo authorized_keys
if [ ! -f "$USER_SSH_DIR/authorized_keys" ] || ! grep -Fxq "$SHARED_KEY" "$USER_SSH_DIR/authorized_keys"; then
    echo "$SHARED_KEY" >> "$USER_SSH_DIR/authorized_keys"
    chown "$USERNAME:$USERNAME" "$USER_SSH_DIR/authorized_keys"
    chmod 600 "$USER_SSH_DIR/authorized_keys"
    echo "Chave compartilhada adicionada ao arquivo authorized_keys."
else
    echo "Chave compartilhada já existe no arquivo authorized_keys."
fi


###############################################################
#Instala pacotes basicos
apt update && apt install -y curl wget git net-tools sudo htop
echo "Pacotes instalados com sucesso..." 

###############################################################
# Verifica a distribuição do Linux e instala o mailx
# Função para instalar o mailx com base na distribuição
install_mailx() {
    if command -v apt &>/dev/null; then
        echo "Detectado Debian/Ubuntu/Mint. Instalando mailutils..."
        sudo apt update
        sudo apt install -y mailutils
    elif command -v yum &>/dev/null; then
        echo "Detectado RHEL/CentOS/Fedora/Rocky/AlmaLinux. Instalando mailx..."
        sudo yum install -y mailx
    elif command -v dnf &>/dev/null; then
        echo "Detectado Fedora (dnf). Instalando mailx..."
        sudo dnf install -y mailx
    elif command -v emerge &>/dev/null; then
        echo "Detectado Gentoo Linux. Instalando mailx..."
        sudo emerge -a sys-apps/mailx
    elif command -v apk &>/dev/null; then
        echo "Detectado Alpine Linux. Instalando mailx..."
        sudo apk add mailx
    elif command -v pacman &>/dev/null; then
        echo "Detectado Arch Linux. Instalando mailx..."
        sudo pacman -S --noconfirm mailx
    elif command -v zypper &>/dev/null; then
        echo "Detectado OpenSUSE. Instalando mailx..."
        sudo zypper install -y mailx
    elif command -v pkg &>/dev/null; then
        echo "Detectado FreeBSD. Instalando mailx..."
        sudo pkg install -y mailx
    else
        echo "Distribuição não suportada ou gerenciador de pacotes não reconhecido."
        exit 1
    fi
}
# Verifica a distribuição do Linux
echo "Verificando a distribuição do Linux..."
cat /etc/*-release
# Instala o mailx de acordo com a distribuição
install_mailx
echo "Instalação do mailx concluída."

###############################################################
# Adiciona comando para enviar email quando o ROOT loga no SRV
# Verifica se o Conteudo abaixo existe no arquivo, se não ele adiciona
content='echo '\''ALERT - Root Shell Access on:'\'' `hostname` `date` `who` | mail -s "Alert: Root Access from `who | cut -d'\''('\'' -f2 | cut -d'\''('\'' -f1`" infra.dc@itconnect.com.br'
# Verifica se o conteúdo já está no arquivo /root/.bashrc
if ! grep -Fxq "$content" /root/.bashrc; then
    # Se o conteúdo não estiver presente, adiciona ao arquivo
    echo "$content" >> /root/.bashrc
    echo "Arquivo /root/.bashrc modificado..."
else
    echo "O conteúdo já está presente no arquivo /root/.bashrc. Nenhuma modificação necessária."
fi

###############################################################
#Configura o Serviço de SSH para a porta 1979, e nega loguin como root
# Ativa o serviço SSH
systemctl enable ssh
systemctl start ssh
echo "Serviço SSH ativado e iniciado."

# Define as configurações desejadas
SSH_PORT="1979"
PERMIT_ROOT_LOGIN="no"
SSH_CONFIG_FILE="/etc/ssh/sshd_config"

# Verifica e define a porta SSH
if grep -q "^Port " "$SSH_CONFIG_FILE"; then
    # Se a linha Port já existe, verifica se está correta
    CURRENT_PORT=$(grep "^Port " "$SSH_CONFIG_FILE" | awk '{print $2}')
    if [ "$CURRENT_PORT" != "$SSH_PORT" ]; then
        # Altera a porta para 1979
        sed -i "s/^Port .*/Port $SSH_PORT/" "$SSH_CONFIG_FILE"
        echo "Porta SSH alterada para $SSH_PORT."
    else
        echo "Porta SSH já está definida como $SSH_PORT."
    fi
else
    # Se a linha Port não existe, adiciona
    echo "Port $SSH_PORT" >> "$SSH_CONFIG_FILE"
    echo "Porta SSH definida como $SSH_PORT."
fi

# Verifica e define o PermitRootLogin
if grep -q "^PermitRootLogin " "$SSH_CONFIG_FILE"; then
    # Se a linha PermitRootLogin já existe, verifica se está correta
    CURRENT_PERMIT_ROOT=$(grep "^PermitRootLogin " "$SSH_CONFIG_FILE" | awk '{print $2}')
    if [ "$CURRENT_PERMIT_ROOT" != "$PERMIT_ROOT_LOGIN" ]; then
        # Altera o PermitRootLogin para no
        sed -i "s/^PermitRootLogin .*/PermitRootLogin $PERMIT_ROOT_LOGIN/" "$SSH_CONFIG_FILE"
        echo "PermitRootLogin alterado para $PERMIT_ROOT_LOGIN."
    else
        echo "PermitRootLogin já está definido como $PERMIT_ROOT_LOGIN."
    fi
else
    # Se a linha PermitRootLogin não existe, adiciona
    echo "PermitRootLogin $PERMIT_ROOT_LOGIN" >> "$SSH_CONFIG_FILE"
    echo "PermitRootLogin definido como $PERMIT_ROOT_LOGIN."
fi

# Reinicia o serviço SSH para aplicar as alterações
systemctl restart ssh
echo "Serviço SSH reiniciado para aplicar as alterações."


