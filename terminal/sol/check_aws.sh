#!/bin/bash
# Verifica si AWS CLI está instalado, lo instala si es necesario y valida autenticación

install_awscli() {
    echo "Instalando AWS CLI v2..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        sudo apt-get install -y unzip &> /dev/null
        unzip -q awscliv2.zip
        sudo ./aws/install
        rm -rf awscliv2.zip ./aws
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        curl -s "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    else
        echo "Sistema operativo no soportado para instalación automática. Instala AWS CLI manualmente."
        exit 10
    fi
}

if ! command -v aws &> /dev/null; then
    echo "AWS CLI no está instalado."
    read -p "¿Deseas instalar AWS CLI ahora? (Y/n): " inst
    case $inst in
        [Nn]*)
            echo "Instala AWS CLI desde https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
            exit 1
            ;;
        *)
            install_awscli
            ;;
    esac
else
    echo "AWS CLI está instalado: $(aws --version)"
fi

echo "Verificando autenticación..."
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ Usuario autenticado en AWS CLI."
else
    echo "❌ No estás autenticado. Ejecuta 'aws configure' para ingresar tus credenciales."
    exit 2
fi
