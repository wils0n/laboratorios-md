# Lab: Introducción a Scripts Bash

**Duración estimada:** 60--90 min\
**Nivel:** Principiante--Intermedio\
**Contexto:** Crearás y ejecutarás scripts bash utilizando conceptos fundamentales como variables, funciones, condicionales. Practicarás la automatización de tareas del sistema operativo.

---

## Objetivos de aprendizaje

Al finalizar, podrás:

- Crear scripts bash ejecutables con shebang correcto
- Utilizar variables y variables de entorno
- Implementar funciones reutilizables
- Usar condicionales para control de flujo
- Manejar argumentos de línea de comandos
- Implementar manejo básico de errores
- Automatizar tareas comunes del sistema

---

## Requisitos del laboratorio

- Terminal (bash, zsh o compatible)
- Editor de texto (vim recomendado)
- Permisos para ejecutar scripts
- Conocimientos básicos de comandos Linux (terminal/3_linux_cheatsheet.md)

---

## Ejercicio 1: Configuración inicial y primer script

### Tarea 1: Crear directorio de trabajo

1. Crea un directorio para tus scripts:

```bash
mkdir -p ~/bash-lab
cd ~/bash-lab
```

2. Verifica tu ubicación:

```bash
pwd
```

### Tarea 2: Tu primer script "Hello World"

1. Crea tu primer script:

```bash
vim hello.sh
```

2. Agrega el siguiente contenido:

```bash
#!/bin/bash
# Mi primer script bash

echo "¡Hola, mundo!"
echo "Script ejecutado en: $(date)"
echo "Usuario actual: $USER"
echo "Directorio actual: $(pwd)"
```

3. Guarda y cierra el archivo (presiona `Esc`, luego escribe `:wq` y presiona `Enter`).

4. Haz el script ejecutable:

```bash
chmod +x hello.sh
```

5. Ejecuta el script:

```bash
./hello.sh
```

**Resultado esperado:**

```
¡Hola, mundo!
Script ejecutado en: [fecha y hora actual]
Usuario actual: [tu usuario]
Directorio actual: /home/[usuario]/bash-lab
```

---

## Ejercicio 2: Variables y entrada del usuario

### Tarea 1: Script con variables

1. Crea un script que use variables:

```bash
vim variables.sh
```

2. Agrega el siguiente contenido:

```bash
#!/bin/bash
# Script para practicar variables

# Variables básicas
nombre="DevOps"
version=1.0
fecha=$(date +%Y-%m-%d)

# Variable de solo lectura
declare -r CURSO="Fundamentos de DevOps"

echo "=== Información del Script ==="
echo "Nombre: $nombre"
echo "Versión: $version"
echo "Fecha: $fecha"
echo "Curso: $CURSO"

# Solicitar entrada del usuario
echo ""
echo "=== Información Personal ==="
read -p "Ingresa tu nombre: " usuario_nombre
read -p "Ingresa tu edad: " usuario_edad

echo ""
echo "Hola $usuario_nombre, tienes $usuario_edad años"
echo "Bienvenido al curso: $CURSO"
```

3. Haz ejecutable y prueba:

```bash
chmod +x variables.sh
./variables.sh
```

### Tarea 2: Variables de entorno

1. Crea un script que explore variables de entorno:

```bash
vim entorno.sh
```

2. Agrega el contenido:

```bash
#!/bin/bash
# Script para explorar variables de entorno

echo "=== Variables de Entorno ==="
echo "Usuario: $USER"
echo "Directorio home: $HOME"
echo "Shell actual: $SHELL"
echo "PATH: $PATH"
echo ""

# Crear variable de entorno personalizada
export MI_VARIABLE="Laboratorio DevOps"
echo "Variable personalizada: $MI_VARIABLE"

# Mostrar todas las variables de entorno
echo ""
echo "=== Primeras 10 variables de entorno ==="
env | head -10
```

3. Ejecuta el script:

```bash
chmod +x entorno.sh
./entorno.sh
```

---

## Ejercicio 3: Funciones y argumentos

### Tarea 1: Script con funciones

1. Crea un script con funciones reutilizables:

```bash
vim funciones.sh
```

2. Agrega el contenido:

```bash
#!/bin/bash
# Script con funciones

# Función para mostrar información del sistema
mostrar_sistema() {
    echo "=== Información del Sistema ==="
    echo "Fecha: $(date)"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "Usuarios conectados: $(who | wc -l)"
    echo "Uso de disco:"
    df -h | head -5
}

# Función con parámetros
saludar() {
    local nombre=$1
    local edad=$2

    if [ -z "$nombre" ]; then
        nombre="Usuario"
    fi

    echo "¡Hola $nombre!"
    if [ ! -z "$edad" ]; then
        echo "Tienes $edad años"
    fi
}

# Función para calcular
calcular() {
    local num1=$1
    local operacion=$2
    local num2=$3

    case $operacion in
        "+")
            resultado=$((num1 + num2))
            ;;
        "-")
            resultado=$((num1 - num2))
            ;;
        "*")
            resultado=$((num1 * num2))
            ;;
        "/")
            if [ $num2 -ne 0 ]; then
                resultado=$((num1 / num2))
            else
                echo "Error: División por cero"
                return 1
            fi
            ;;
        *)
            echo "Operación no válida: $operacion"
            return 1
            ;;
    esac

    echo "Resultado: $num1 $operacion $num2 = $resultado"
}

# Ejecutar funciones
mostrar_sistema
echo ""
saludar "Ana" "25"
echo ""
saludar "Carlos"
echo ""
calcular 10 "+" 5
calcular 20 "*" 3
calcular 15 "/" 3
```

3. Ejecuta el script:

```bash
chmod +x funciones.sh
./funciones.sh
```

### Tarea 2: Script con argumentos de línea de comandos

1. Crea un script que maneje argumentos:

```bash
vim argumentos.sh
```

2. Agrega el contenido:

```bash
#!/bin/bash
# Script que maneja argumentos de línea de comandos

# Función de ayuda
mostrar_ayuda() {
    echo "Uso: $0 [OPCIONES] [ARCHIVOS]"
    echo ""
    echo "OPCIONES:"
    echo "  -h, --help     Mostrar esta ayuda"
    echo "  -v, --version  Mostrar versión"
    echo "  -c, --count    Contar archivos"
    echo "  -l, --list     Listar archivos detalladamente"
    echo ""
    echo "Ejemplos:"
    echo "  $0 -c *.txt"
    echo "  $0 --list /home/user/"
}

# Variables
VERSION="1.0"
CONTAR=false
LISTAR=false

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            mostrar_ayuda
            exit 0
            ;;
        -v|--version)
            echo "Versión: $VERSION"
            exit 0
            ;;
        -c|--count)
            CONTAR=true
            shift
            ;;
        -l|--list)
            LISTAR=true
            shift
            ;;
        *)
            # Archivo o directorio
            ARCHIVOS+=("$1")
            shift
            ;;
    esac
done

# Lógica principal
echo "=== Script de Análisis de Archivos ==="
echo "Argumentos recibidos: $#"
echo "Archivos a procesar: ${ARCHIVOS[@]}"

if [ ${#ARCHIVOS[@]} -eq 0 ]; then
    echo "No se especificaron archivos. Usando directorio actual."
    ARCHIVOS=(".")
fi

for archivo in "${ARCHIVOS[@]}"; do
    echo ""
    echo "Procesando: $archivo"

    if [ -f "$archivo" ]; then
        echo "  Tipo: Archivo regular"
        echo "  Tamaño: $(stat -c%s "$archivo" 2>/dev/null || stat -f%z "$archivo" 2>/dev/null) bytes"
    elif [ -d "$archivo" ]; then
        echo "  Tipo: Directorio"
        archivo_count=$(ls -1 "$archivo" 2>/dev/null | wc -l)
        echo "  Contenido: $archivo_count elementos"

        if [ "$CONTAR" = true ]; then
            echo "  Conteo detallado:"
            echo "    Archivos: $(find "$archivo" -type f 2>/dev/null | wc -l)"
            echo "    Directorios: $(find "$archivo" -type d 2>/dev/null | wc -l)"
        fi

        if [ "$LISTAR" = true ]; then
            echo "  Listado:"
            ls -la "$archivo" 2>/dev/null | head -10
        fi
    else
        echo "  Error: No existe o no es accesible"
    fi
done
```

3. Prueba el script con diferentes argumentos:

```bash
chmod +x argumentos.sh

# Mostrar ayuda
./argumentos.sh --help

# Mostrar versión
./argumentos.sh -v

# Contar archivos en directorio actual
./argumentos.sh -c

# Listar archivos
./argumentos.sh -l

# Combinar opciones
./argumentos.sh -c -l /tmp
```

---

## Ejercicio 4: Condicionales

### Tarea 1: Script con condicionales

1. Crea un script que use diferentes tipos de condicionales:

```bash
vim condicionales.sh
```

2. Agrega el contenido:

```bash
#!/bin/bash
# Script para practicar condicionales

# Función para verificar archivos
verificar_archivo() {
    local archivo=$1

    echo "Verificando: $archivo"

    if [ -e "$archivo" ]; then
        echo "  ✓ El archivo existe"

        if [ -f "$archivo" ]; then
            echo "  ✓ Es un archivo regular"

            if [ -r "$archivo" ]; then
                echo "  ✓ Es legible"
            else
                echo "  ✗ No es legible"
            fi

            if [ -w "$archivo" ]; then
                echo "  ✓ Es escribible"
            else
                echo "  ✗ No es escribible"
            fi

            if [ -x "$archivo" ]; then
                echo "  ✓ Es ejecutable"
            else
                echo "  ✗ No es ejecutable"
            fi

        elif [ -d "$archivo" ]; then
            echo "  ✓ Es un directorio"
        fi

    else
        echo "  ✗ El archivo no existe"
    fi
    echo ""
}

# Función para evaluar números
evaluar_numero() {
    local num=$1

    echo "Evaluando número: $num"

    if [[ ! "$num" =~ ^[0-9]+$ ]]; then
        echo "  ✗ No es un número válido"
        return 1
    fi

    if [ $num -eq 0 ]; then
        echo "  = El número es cero"
    elif [ $num -gt 0 ]; then
        echo "  + El número es positivo"

        if [ $num -gt 100 ]; then
            echo "  ! El número es mayor a 100"
        fi

    else
        echo "  - El número es negativo"
    fi

    # Verificar si es par o impar
    if [ $((num % 2)) -eq 0 ]; then
        echo "  ⚹ El número es par"
    else
        echo "  ⚹ El número es impar"
    fi
    echo ""
}

# Función principal
echo "=== Script de Condicionales ==="
echo ""

# Verificar archivos del sistema
verificar_archivo "/etc/passwd"
verificar_archivo "/tmp"
verificar_archivo "./hello.sh"
verificar_archivo "/archivo_inexistente"

# Evaluar números
evaluar_numero "42"
evaluar_numero "0"
evaluar_numero "101"
evaluar_numero "-5"
evaluar_numero "abc"

# Ejemplo con case
echo "=== Ejemplo con Case ==="
for dia in lunes martes miércoles jueves viernes sábado domingo; do
    case $dia in
        lunes|martes|miércoles|jueves|viernes)
            echo "$dia: Día de trabajo 💼"
            ;;
        sábado|domingo)
            echo "$dia: Fin de semana 🎉"
            ;;
        *)
            echo "$dia: Día desconocido ❓"
            ;;
    esac
done
```

3. Ejecuta el script:

```bash
chmod +x condicionales.sh
./condicionales.sh
```

---

## Ejercicio 5: Script de automatización Galaxy Marketplace

### Tarea 1: Crear un script para automatizar la configuración de Galaxy Marketplace

1. Crea un script que automatice la descarga y configuración:

```bash
vim setup_galaxy.sh
```

2. Agrega el contenido:

```bash
#!/bin/bash
# Script de automatización para Galaxy Marketplace

# Configuración
REPO_URL="https://github.com/launchdarkly-labs/Galaxy-Marketplace-Example-App.git"
PROJECT_NAME="Galaxy-Marketplace-Example-App"
ENV_SOURCE="../environments/.env"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con colores
mostrar_mensaje() {
    local tipo=$1
    local mensaje=$2

    case $tipo in
        "info")
            echo -e "${BLUE}[INFO]${NC} $mensaje"
            ;;
        "success")
            echo -e "${GREEN}[SUCCESS]${NC} $mensaje"
            ;;
        "warning")
            echo -e "${YELLOW}[WARNING]${NC} $mensaje"
            ;;
        "error")
            echo -e "${RED}[ERROR]${NC} $mensaje"
            ;;
    esac
}

# Función para verificar si un comando existe
verificar_comando() {
    local comando=$1
    if ! command -v $comando &> /dev/null; then
        mostrar_mensaje "error" "El comando '$comando' no está instalado"
        return 1
    fi
    return 0
}

# Función para verificar dependencias
verificar_dependencias() {
    mostrar_mensaje "info" "Verificando dependencias..."

    local dependencias=("git" "node" "npm")
    local faltan=()

    for dep in "${dependencias[@]}"; do
        if ! verificar_comando $dep; then
            faltan+=($dep)
        fi
    done

    if [ ${#faltan[@]} -ne 0 ]; then
        mostrar_mensaje "error" "Faltan las siguientes dependencias: ${faltan[*]}"
        mostrar_mensaje "info" "Por favor instala las dependencias faltantes:"
        for dep in "${faltan[@]}"; do
            case $dep in
                "git")
                    echo "  - Git: https://git-scm.com/downloads"
                    ;;
                "node"|"npm")
                    echo "  - Node.js (incluye npm): https://nodejs.org/"
                    ;;
            esac
        done
        return 1
    fi

    mostrar_mensaje "success" "Todas las dependencias están instaladas"
    return 0
}

# Función para clonar el repositorio
clonar_repositorio() {
    mostrar_mensaje "info" "Clonando repositorio Galaxy Marketplace..."

    # Verificar si el directorio ya existe
    if [ -d "$PROJECT_NAME" ]; then
        mostrar_mensaje "warning" "El directorio '$PROJECT_NAME' ya existe"
        read -p "¿Deseas eliminarlo y clonar de nuevo? (y/N): " respuesta
        case $respuesta in
            [Yy]*)
                rm -rf "$PROJECT_NAME"
                mostrar_mensaje "info" "Directorio eliminado"
                ;;
            *)
                mostrar_mensaje "info" "Usando directorio existente"
                return 0
                ;;
        esac
    fi

    # Clonar el repositorio
    if git clone "$REPO_URL"; then
        mostrar_mensaje "success" "Repositorio clonado exitosamente"
        return 0
    else
        mostrar_mensaje "error" "Error al clonar el repositorio"
        return 1
    fi
}

# Función para instalar dependencias npm
instalar_dependencias_npm() {
    mostrar_mensaje "info" "Instalando dependencias de Node.js..."

    if [ ! -d "$PROJECT_NAME" ]; then
        mostrar_mensaje "error" "Directorio del proyecto no encontrado"
        return 1
    fi

    cd "$PROJECT_NAME"

    if [ ! -f "package.json" ]; then
        mostrar_mensaje "error" "archivo package.json no encontrado"
        return 1
    fi

    if npm install; then
        mostrar_mensaje "success" "Dependencias instaladas exitosamente"
        cd ..
        return 0
    else
        mostrar_mensaje "error" "Error al instalar dependencias"
        cd ..
        return 1
    fi
}

# Función para configurar variables de entorno
configurar_env() {
    mostrar_mensaje "info" "Configurando variables de entorno..."

    cd "$PROJECT_NAME"

    # Verificar si existe .env.example
    if [ ! -f ".env.example" ]; then
        mostrar_mensaje "error" "Archivo .env.example no encontrado"
        cd ..
        return 1
    fi

    # Copiar archivo de ejemplo
    if cp .env.example .env; then
        mostrar_mensaje "success" "Archivo .env creado desde .env.example"
    else
        mostrar_mensaje "error" "Error al crear archivo .env"
        cd ..
        return 1
    fi

    # Verificar si existe archivo de entorno en directorio padre
    if [ -f "$ENV_SOURCE" ]; then
        mostrar_mensaje "info" "Encontrado archivo de entorno en $ENV_SOURCE"
        read -p "¿Deseas usar este archivo de entorno? (Y/n): " usar_env
        case $usar_env in
            [Nn]*)
                mostrar_mensaje "info" "Usando archivo .env por defecto"
                ;;
            *)
                if cp "$ENV_SOURCE" .env; then
                    mostrar_mensaje "success" "Variables de entorno copiadas desde $ENV_SOURCE"
                else
                    mostrar_mensaje "warning" "Error al copiar variables de entorno, usando .env por defecto"
                fi
                ;;
        esac
    else
        mostrar_mensaje "warning" "Archivo de entorno no encontrado en $ENV_SOURCE"
        mostrar_mensaje "info" "Necesitarás configurar manualmente las variables en .env:"
        echo "  - LD_SDK_KEY=sdk-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        echo "  - LD_EVENT_KEY=tbd-lab"
    fi

    cd ..
    return 0
}

# Función para mostrar el estado del archivo .env
mostrar_env_status() {
    mostrar_mensaje "info" "Estado del archivo .env:"

    cd "$PROJECT_NAME"

    if [ -f ".env" ]; then
        echo "Contenido actual del archivo .env:"
        echo "=================================="
        cat .env
        echo "=================================="

        # Verificar si las variables críticas están configuradas
        if grep -q "LD_SDK_KEY=sdk-" .env && grep -q "LD_EVENT_KEY=" .env; then
            mostrar_mensaje "success" "Variables de entorno configuradas correctamente"
        else
            mostrar_mensaje "warning" "Algunas variables importantes pueden no estar configuradas"
        fi
    else
        mostrar_mensaje "error" "Archivo .env no encontrado"
    fi

    cd ..
}

# Función para iniciar la aplicación
iniciar_aplicacion() {
    mostrar_mensaje "info" "Iniciando la aplicación Galaxy Marketplace..."

    cd "$PROJECT_NAME"

    # Verificar que package.json tiene el script dev
    if ! grep -q '"dev"' package.json; then
        mostrar_mensaje "error" "Script 'dev' no encontrado en package.json"
        cd ..
        return 1
    fi

    mostrar_mensaje "info" "Ejecutando 'npm run dev'..."
    mostrar_mensaje "warning" "La aplicación se iniciará. Usa Ctrl+C para detenerla."
    mostrar_mensaje "info" "Una vez iniciada, probablemente estará disponible en http://localhost:3000"

    # Dar tiempo al usuario para leer los mensajes
    sleep 3

    # Ejecutar el comando
    npm run dev

    cd ..
}

# Función de ayuda
mostrar_ayuda() {
    echo "Script de automatización para Galaxy Marketplace"
    echo ""
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "OPCIONES:"
    echo "  -h, --help       Mostrar esta ayuda"
    echo "  -c, --clone      Solo clonar repositorio"
    echo "  -i, --install    Solo instalar dependencias"
    echo "  -e, --env        Solo configurar variables de entorno"
    echo "  -s, --start      Solo iniciar aplicación"
    echo "  --status         Mostrar estado del proyecto"
    echo "  --full          Ejecutar configuración completa (por defecto)"
    echo ""
    echo "Ejemplos:"
    echo "  $0               # Configuración completa automática"
    echo "  $0 --clone       # Solo clonar el repositorio"
    echo "  $0 --install     # Solo instalar dependencias"
    echo "  $0 --status      # Mostrar estado actual"
}

# Función principal de configuración completa
configuracion_completa() {
    mostrar_mensaje "info" "Iniciando configuración completa de Galaxy Marketplace"
    echo ""

    # Paso 1: Verificar dependencias
    if ! verificar_dependencias; then
        return 1
    fi
    echo ""

    # Paso 2: Clonar repositorio
    if ! clonar_repositorio; then
        return 1
    fi
    echo ""

    # Paso 3: Instalar dependencias
    if ! instalar_dependencias_npm; then
        return 1
    fi
    echo ""

    # Paso 4: Configurar variables de entorno
    if ! configurar_env; then
        return 1
    fi
    echo ""

    # Paso 5: Mostrar estado
    mostrar_env_status
    echo ""

    mostrar_mensaje "success" "¡Configuración completa exitosa!"
    mostrar_mensaje "info" "Para iniciar la aplicación ejecuta:"
    echo "  cd $PROJECT_NAME"
    echo "  npm run dev"
    echo ""

    read -p "¿Deseas iniciar la aplicación ahora? (Y/n): " iniciar_now
    case $iniciar_now in
        [Nn]*)
            mostrar_mensaje "info" "Aplicación lista para iniciar manualmente"
            ;;
        *)
            iniciar_aplicacion
            ;;
    esac
}

# Función para mostrar estado del proyecto
mostrar_estado() {
    mostrar_mensaje "info" "Estado del proyecto Galaxy Marketplace:"
    echo ""

    # Verificar si existe el directorio
    if [ -d "$PROJECT_NAME" ]; then
        mostrar_mensaje "success" "Directorio del proyecto: ✓ Existe"

        cd "$PROJECT_NAME"

        # Verificar node_modules
        if [ -d "node_modules" ]; then
            mostrar_mensaje "success" "Dependencias: ✓ Instaladas"
        else
            mostrar_mensaje "warning" "Dependencias: ✗ No instaladas"
        fi

        # Verificar .env
        if [ -f ".env" ]; then
            mostrar_mensaje "success" "Archivo .env: ✓ Existe"
            mostrar_env_status
        else
            mostrar_mensaje "warning" "Archivo .env: ✗ No existe"
        fi

        cd ..
    else
        mostrar_mensaje "warning" "Directorio del proyecto: ✗ No existe"
    fi
}

# Variables de control
SOLO_CLONAR=false
SOLO_INSTALAR=false
SOLO_ENV=false
SOLO_INICIAR=false
MOSTRAR_ESTADO=false
CONFIGURACION_COMPLETA=true

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            mostrar_ayuda
            exit 0
            ;;
        -c|--clone)
            CONFIGURACION_COMPLETA=false
            SOLO_CLONAR=true
            shift
            ;;
        -i|--install)
            CONFIGURACION_COMPLETA=false
            SOLO_INSTALAR=true
            shift
            ;;
        -e|--env)
            CONFIGURACION_COMPLETA=false
            SOLO_ENV=true
            shift
            ;;
        -s|--start)
            CONFIGURACION_COMPLETA=false
            SOLO_INICIAR=true
            shift
            ;;
        --status)
            CONFIGURACION_COMPLETA=false
            MOSTRAR_ESTADO=true
            shift
            ;;
        --full)
            CONFIGURACION_COMPLETA=true
            shift
            ;;
        *)
            mostrar_mensaje "error" "Opción desconocida: $1"
            mostrar_ayuda
            exit 1
            ;;
    esac
done

# Ejecutar según parámetros
if [ "$MOSTRAR_ESTADO" = true ]; then
    mostrar_estado
elif [ "$SOLO_CLONAR" = true ]; then
    verificar_dependencias && clonar_repositorio
elif [ "$SOLO_INSTALAR" = true ]; then
    instalar_dependencias_npm
elif [ "$SOLO_ENV" = true ]; then
    configurar_env
elif [ "$SOLO_INICIAR" = true ]; then
    iniciar_aplicacion
elif [ "$CONFIGURACION_COMPLETA" = true ]; then
    configuracion_completa
fi
```

3. Haz el script ejecutable y pruébalo:

```bash
chmod +x setup_galaxy.sh

# Configuración completa automática
./setup_galaxy.sh

# Mostrar ayuda
./setup_galaxy.sh --help

# Solo clonar repositorio
./setup_galaxy.sh --clone

# Solo instalar dependencias (después de clonar)
./setup_galaxy.sh --install

# Solo configurar variables de entorno
./setup_galaxy.sh --env

# Mostrar estado del proyecto
./setup_galaxy.sh --status

# Solo iniciar la aplicación
./setup_galaxy.sh --start
```

### Características del script:

- **Verificación de dependencias**: Comprueba que git, node y npm estén instalados
- **Clonado inteligente**: Maneja directorios existentes
- **Instalación automática**: Ejecuta `npm install` automáticamente
- **Configuración de entorno**: Copia `.env.example` a `.env` y opcionalmente usa archivo de `../environments/.env`
- **Validación**: Verifica que las variables críticas estén configuradas
- **Modo interactivo**: Pregunta antes de sobrescribir archivos
- **Opciones modulares**: Permite ejecutar solo partes específicas del proceso
- **Colores y logging**: Interfaz clara con mensajes informativos

---

## Comandos útiles de Bash (referencia rápida)

Basado en [`terminal/4_bash_cheatsheet.md`](terminal/4_bash_cheatsheet.md):

```bash
# Ejecutar scripts
chmod +x script.sh          # Hacer ejecutable
./script.sh                 # Ejecutar script local
bash script.sh              # Ejecutar con bash explícito

# Variables
nombre="valor"              # Asignar variable
echo "$nombre"              # Usar variable
export VARIABLE="valor"     # Variable de entorno

# Condicionales básicos
[ -f archivo ]              # ¿Es archivo?
[ -d directorio ]           # ¿Es directorio?
[ $num -eq 5 ]              # ¿Número igual a 5?
[ "$str" = "texto" ]        # ¿String igual?

# Funciones
mifuncion() { echo "Hola $1"; }    # Definir función
mifuncion "mundo"                  # Llamar función
```

---

## Criterios de éxito (Checklist)

- [ ] **Ejercicio 1**: Primer script ejecutable creado y funcionando
- [ ] **Ejercicio 2**: Scripts con variables y entrada de usuario
- [ ] **Ejercicio 3**: Funciones implementadas correctamente
- [ ] **Ejercicio 4**: Condicionales
- [ ] **Ejercicio 5**: Script de monitoreo avanzado completado

---

## Extensiones y extras (opcional)

### Mejores prácticas implementadas:

- **Shebang**: Todos los scripts usan `#!/bin/bash`
- **Variables locales**: Uso de `local` en funciones
- **Manejo de errores**: Verificaciones con `if` y códigos de salida
- **Logging**: Archivos de log para seguimiento
- **Documentación**: Comentarios explicativos en el código
- **Validación**: Verificación de entrada del usuario
- **Portabilidad**: Comandos que funcionan en diferentes sistemas

### Características avanzadas:

- **Colores en terminal**: Uso de códigos ANSI
- **Argumentos de línea de comandos**: Procesamiento con `case`
- **Funciones reutilizables**: Modularización del código
- **Interfaces de usuario**: Menús interactivos

---

## Comandos básicos de Vim

Para los estudiantes que no estén familiarizados con Vim, aquí están los comandos esenciales:

### Modos de Vim:

- **Modo Normal**: Para navegar y ejecutar comandos (modo por defecto)
- **Modo Insertar**: Para escribir texto
- **Modo Comando**: Para guardar, salir, etc.

### Comandos básicos:

```bash
vim archivo.sh              # Abrir archivo con Vim
```

**En modo Normal:**

- `i` - Entrar al modo insertar
- `Esc` - Salir del modo insertar (volver a modo normal)
- `:w` - Guardar archivo
- `:q` - Salir de Vim
- `:wq` - Guardar y salir
- `:q!` - Salir sin guardar
- `dd` - Borrar línea completa
- `yy` - Copiar línea
- `p` - Pegar línea copiada
- `u` - Deshacer último cambio
- `/texto` - Buscar "texto" en el archivo
- `n` - Ir a la siguiente coincidencia de búsqueda

**Navegación:**

- `h, j, k, l` - Izquierda, abajo, arriba, derecha
- `0` - Ir al inicio de la línea
- `$` - Ir al final de la línea
- `gg` - Ir al inicio del archivo
- `G` - Ir al final del archivo

### Flujo de trabajo típico:

1. `vim script.sh` - Abrir archivo
2. `i` - Entrar en modo insertar
3. Escribir el código
4. `Esc` - Salir del modo insertar
5. `:wq` - Guardar y salir

---

## Solución de problemas frecuentes

- **"Permission denied"**: Usa `chmod +x script.sh` para hacer ejecutable
- **"Command not found"**: Verifica el shebang y usa `./script.sh`
- **Variables vacías**: Usa comillas dobles: `"$variable"`
- \*\*Errores de sintaxis\*\*: Revisa paréntesis, llaves y corchetes

### Comandos de depuración:

```bash
bash -x script.sh           # Ejecutar con debug
set -e                      # Salir si hay error
set -u                      # Error si variable no definida
set -o pipefail             # Error en pipes
```

---

¡Felicidades! Has completado el laboratorio de scripts bash. Ahora tienes conocimientos sólidos para automatizar tareas del sistema operativo y crear herramientas útiles.
