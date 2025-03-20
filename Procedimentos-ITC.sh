#Script de segurança que cria usuario e ativa envio de e-mail so logr com root

###############################################################
# verifica se o usuário itconnectadm existe. Se o usuário não existir, ele será 
# criado, terá uma senha definida e será adicionado ao grupo sudo.

#!/bin/bash
# Nome do usuário
USERNAME="itconnectadm"
# Senha do usuário
PASSWORD="96PO08as@!!(&(4132"
# Verifica se o usuário já existe
if id "$USERNAME" &>/dev/null; then
    echo "O usuário $USERNAME já existe."
else
    # Adiciona o usuário
    adduser --gecos "" --disabled-password "$USERNAME"
    # Define a senha para o usuário
    echo "$USERNAME:$PASSWORD" | chpasswd
    # Adiciona o usuário ao grupo sudo
    usermod -aG sudo "$USERNAME"
    echo "Usuário $USERNAME criado, senha definida e adicionado ao grupo sudo."
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
#echo 'echo '\''ALERT - Root Shell Access on:'\'' `hostname` `date` `who` | mail -s "Alert: Root Access from `who | cut -d'\''('\'' -f2 | cut -d'\''('\'' -f1`" infra.dc@itconnect.com.br' >> /root/.bashrc
#echo "Arquivo /root/.bashrc modificado..." 

# Envia  email quando o ROOT loga no SRV
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