# Guía: Instalación y Configuración de AWS CLI en Mac

**Duración estimada:** 20–30 min  
**Nivel:** Principiante  
**Referencia:** [Install AWS CLI and Configure Credentials on a Mac](https://medium.com/@amiri.mccain/install-aws-cli-and-configure-credentials-and-config-files-on-a-mac-cda81cf64052)

---

## Objetivos

- Instalar AWS CLI v2 en macOS
- Crear un usuario IAM con claves de acceso
- Configurar credenciales con `aws configure`
- Entender los archivos `~/.aws/credentials` y `~/.aws/config`
- Verificar la configuración

---

## Paso 1: Instalar AWS CLI

### Opción A: Homebrew (recomendado)

```bash
# Instalar Homebrew si no lo tienes
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Actualizar Homebrew
brew update

# Instalar AWS CLI
brew install awscli
```

### Opción B: Instalador pkg oficial

```bash
# Descargar el instalador
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"

# Instalar
sudo installer -pkg AWSCLIV2.pkg -target /

# Limpiar
rm AWSCLIV2.pkg
```

### Verificar instalación

```bash
aws --version
# Salida esperada: aws-cli/2.x.x Python/3.x.x Darwin/...
```

---

## Paso 2: Crear usuario IAM y clave de acceso

1. Inicia sesión en la [consola de AWS](https://console.aws.amazon.com)
2. Ve a **IAM > Usuarios**
3. Crea un usuario nuevo o selecciona uno existente
4. Ve a **Credenciales de seguridad** → **Crear clave de acceso**
5. Selecciona el caso de uso **CLI**
6. Guarda el **Access Key ID** y **Secret Access Key** — solo se muestran una vez

> **Importante:** Nunca compartas ni subas estas claves a repositorios públicos.

---

## Paso 3: Configurar AWS CLI

Ejecuta el comando de configuración:

```bash
aws configure
```

Ingresa los valores cuando se soliciten:

```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

Formatos de salida disponibles: `json`, `yaml`, `table`, `text`

Regiones comunes:

| Región | Código |
|--------|--------|
| EE.UU. Este (Virginia) | `us-east-1` |
| EE.UU. Oeste (Oregón) | `us-west-2` |
| Europa (Irlanda) | `eu-west-1` |
| Sudamérica (São Paulo) | `sa-east-1` |

---

## Paso 4: Archivos generados

`aws configure` crea automáticamente dos archivos en `~/.aws/`:

### `~/.aws/credentials`

```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### `~/.aws/config`

```ini
[default]
region = us-east-1
output = json
```

> En macOS, la carpeta `.aws` está en `/Users/[tu-usuario]/`. Es oculta — para verla en Finder presiona `Cmd + Shift + .`

---

## Paso 5: Verificar configuración

```bash
# Ver configuración activa
aws configure list

# Verificar identidad autenticada
aws sts get-caller-identity
```

Salida esperada de `get-caller-identity`:

```json
{
    "UserId": "AIDAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/mi-usuario"
}
```

---

## Paso 6 (Opcional): Múltiples perfiles

Útil para manejar distintas cuentas o entornos (dev, prod, etc.):

```bash
aws configure --profile dev
aws configure --profile prod
```

Esto agrega entradas adicionales en los archivos:

```ini
# ~/.aws/credentials
[default]
aws_access_key_id = ...
aws_secret_access_key = ...

[dev]
aws_access_key_id = AKIADEV...
aws_secret_access_key = ...

[prod]
aws_access_key_id = AKIAPROD...
aws_secret_access_key = ...
```

Usar un perfil específico en comandos:

```bash
aws s3 ls --profile dev
aws iam list-users --profile prod
```

---

## Comandos de referencia rápida

```bash
aws configure                        # Configurar credenciales
aws configure list                   # Ver configuración actual
aws configure list-profiles          # Ver perfiles disponibles
aws sts get-caller-identity          # Verificar autenticación
aws configure --profile nombre       # Configurar perfil adicional
```

---

## Checklist

- [ ] AWS CLI instalado (`aws --version` responde)
- [ ] Usuario IAM con clave de acceso creado en consola
- [ ] `aws configure` ejecutado con las credenciales
- [ ] `~/.aws/credentials` y `~/.aws/config` existen
- [ ] `aws sts get-caller-identity` retorna tu cuenta sin errores
