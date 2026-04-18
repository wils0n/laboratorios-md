# Lab: Automatización e interacción básica con AWS CLI usando Bash

**Duración estimada:** 45–60 min  
**Nivel:** Principiante–Intermedio  
**Contexto:** Aprenderás a interactuar con AWS desde la terminal usando AWS CLI y scripts Bash. Practicarás validando la instalación, autenticación, listando buckets S3 y subiendo archivos de manera automatizada.

---

## Objetivos de aprendizaje

- Validar la instalación y autenticación de AWS CLI (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Listar buckets S3 desde Bash
- Subir archivos a un bucket S3 usando scripts
- Automatizar tareas básicas de AWS con Bash

---

## Requisitos del laboratorio

- Cuenta de AWS activa
- AWS CLI instalado y configurado (o acceso para instalarlo)
- Permisos para listar y escribir en S3
- Terminal (bash, zsh o compatible)
- Editor de texto (vim recomendado)

---

## Configuración previa: Clave de acceso y AWS CLI

Antes de ejecutar cualquier script, asegúrate de tener una clave de acceso configurada en AWS CLI:

1. Ingresa a la consola de AWS y ve a **IAM > Usuarios**.
2. Selecciona tu usuario o crea uno nuevo.
3. Ve a la pestaña **Credenciales de seguridad** y haz clic en **Crear clave de acceso**.
4. Guarda el **Access Key ID** y el **Secret Access Key** en un lugar seguro.
5. En tu terminal, ejecuta:

   ```bash
   aws configure
   ```

   Ingresa los valores solicitados:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Región por defecto (ejemplo: us-east-1)
   - Formato de salida (ejemplo: json)
  
> Nota: Validar que su archivo .aws/config tenga el contenido similar a
```bash
<path to>/.aws/config:
[default]
region = us-east-1
output = json
```

---

## Ejercicio 1: Validar AWS CLI y autenticación

### Tarea 1: Verificar e instalar AWS CLI si es necesario

1. Crea un script llamado `check_aws.sh`:

```bash
vim check_aws.sh
```

2. Agrega el siguiente contenido:

```bash
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
```

3. Haz ejecutable y prueba:

```bash
chmod +x check_aws.sh
./check_aws.sh
```

---

## Ejercicio 2: Listar recursos AWS (S3, IAM)

### Tarea 1: Script para listar buckets, usuarios y roles

1. Crea un script llamado `listar_recursos_aws.sh`:

```bash
vim listar_recursos_aws.sh
```

2. Agrega el siguiente contenido:

```bash
#!/bin/bash
# Lista buckets S3, usuarios y roles IAM

if ! command -v aws &> /dev/null; then
    echo "AWS CLI no está instalado."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "No estás autenticado en AWS CLI."
    exit 2
fi

echo "\n=== Buckets S3 ==="
aws s3 ls

echo "\n=== Usuarios IAM ==="
aws iam list-users --output table

echo "\n=== Roles IAM ==="
aws iam list-roles --output table | head -30
```

3. Haz ejecutable y prueba:

```bash
chmod +x listar_recursos_aws.sh
./listar_recursos_aws.sh
```

---

## Ejercicio 3: Subir un archivo a un bucket S3

### Tarea 1: Script para subir archivos

1. Crea un script llamado `subir_archivo_s3.sh`:

```bash
vim subir_archivo_s3.sh
```

2. Agrega el siguiente contenido:

```bash
#!/bin/bash
# Sube un archivo local a un bucket S3

if [ $# -lt 2 ]; then
    echo "Uso: $0 <archivo_local> <bucket_s3>"
    exit 1
fi

ARCHIVO="$1"
BUCKET="$2"

if ! command -v aws &> /dev/null; then
    echo "AWS CLI no está instalado."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "No estás autenticado en AWS CLI."
    exit 2
fi

if [ ! -f "$ARCHIVO" ]; then
    echo "El archivo '$ARCHIVO' no existe."
    exit 3
fi

echo "Subiendo $ARCHIVO a s3://$BUCKET/ ..."
if aws s3 cp "$ARCHIVO" "s3://$BUCKET/"; then
    echo "✅ Archivo subido correctamente."
else
    echo "❌ Error al subir el archivo."
    exit 4
fi
```

3. Haz ejecutable y prueba:

```bash
chmod +x subir_archivo_s3.sh
./subir_archivo_s3.sh archivo.txt mi-bucket-s3
```

---

## Criterios de éxito (Checklist)

- [ ] Validaste la instalación y autenticación de AWS CLI
- [ ] Listaste los buckets S3 de tu cuenta
- [ ] Subiste un archivo a un bucket S3 usando Bash

---

## Comandos útiles de AWS CLI

```bash
aws configure                # Configurar credenciales
aws s3 ls                    # Listar buckets S3
aws s3 cp archivo s3://bucket/   # Subir archivo a bucket
aws sts get-caller-identity  # Verificar autenticación
```

---

¡Felicidades! Ahora puedes automatizar tareas básicas de AWS desde Bash.
