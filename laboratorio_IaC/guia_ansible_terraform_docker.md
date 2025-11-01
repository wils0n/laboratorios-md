# Guía: Terraform + Ansible + Docker 

## Objetivos del laboratorio

Al terminar este laboratorio serás capaz de:

- Provisionar infraestructura local (contenedor Docker) con Terraform.
- Configurar y provisionar servicios dentro del contenedor usando Ansible (sin archivos adicionales, 100% YAML).
- Usar la colección `community.docker` para conectar Ansible a contenedores Docker.
- Entender y solucionar problemas comunes de Ansible en contenedores (falta de sudo, ausencia de Python, become, interpreter_python).
- Empaquetar y probar recursos localmente (reconstruir imágenes, instalar dependencias, ejecutar playbooks) y comprobar la aplicación en http://localhost:8080.

Versión simplificada y 100% YAML de Ansible sin archivos extra. Todo funciona localmente, sin AWS.

## Estructura
```
ansible-docker-terraform-v3/
├─ README.md
├─ terraform/
│  └─ main.tf
└─ ansible/
   ├─ ansible.cfg
   ├─ inventory.yml
   ├─ requirements.yml
   └─ playbook.yml
```

## Ejecución
```bash
cd terraform
terraform init && terraform apply -auto-approve

cd ../ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook playbook.yml
```

Abrir en navegador: http://localhost:8080

## Explicación línea a línea: Ansible + Docker

Esta sección explica cada parte relevante del flujo Ansible + Docker usado en este repo. Incluye por qué existen ciertos ajustes en `ansible.cfg`, qué hace `requirements.yml`, y una explicación detallada del `playbook.yml` y los comandos que se usan en la sección "Ejecución".

### Objetivo

Configurar, desde Ansible, un contenedor Docker creado previamente por Terraform para que sirva una página estática en nginx. Usamos la conexión `community.docker.docker` para ejecutar comandos dentro del contenedor.

### Archivos importantes en `ansible/`

- `ansible.cfg` — configuración de Ansible para este proyecto.
- `inventory.yml` — inventario Ansible que apunta al contenedor Docker (host `web1`).
- `requirements.yml` — lista de collections de Ansible necesarias (por ejemplo `community.docker`).
- `playbook.yml` — playbook que realiza la instalación de nginx, crea el `index.html` y arranca nginx.

### Contenido de `ansible/ansible.cfg` (línea a línea)

El archivo contiene:

```properties
[defaults]
inventory = ./inventory.yml             # Usa el inventario local `inventory.yml`.
host_key_checking = False               # Evita preguntar por fingerprints SSH (útil en contenedores efímeros).
retry_files_enabled = False             # No crear archivos de reintento (.retry).
stdout_callback = yaml                  # Formato de salida en YAML (más legible).
interpreter_python = auto_silent        # Dejar que Ansible detecte el intérprete Python automáticamente.

```

- `inventory`: indica qué inventario usar por defecto cuando ejecutas `ansible-playbook` sin `-i`.
- `host_key_checking=False`: evita interrupciones en entornos locales o contenedores donde no se quiere verificar claves.
- `interpreter_python=auto_silent`: permite que Ansible busque un intérprete Python disponible en el contenedor/host sin mostrar advertencias; útil porque algunos contenedores no tienen `python` en `/usr/bin` y Ansible intentará detectar `python3` si está instalado.

### Contenido de `ansible/requirements.yml`

```yaml
collections:
   - name: community.docker    # Collection que contiene el plugin de conexión y módulos para Docker

```

- `community.docker` incluye el plugin `community.docker.docker` que permite a Ansible ejecutar tareas dentro de contenedores Docker usando `docker exec`.

### Comandos en la guía

- `ansible-galaxy collection install -r requirements.yml`
   - Qué hace: descarga e instala las collections indicadas en `requirements.yml` (a `~/.ansible/collections/` por defecto, o en las rutas definidas en `ansible.cfg`).
   - Por qué: necesitamos `community.docker` para la conexión y los módulos relacionados con Docker.

- `ansible-playbook playbook.yml`
   - Qué hace: ejecuta el playbook en los hosts indicados por `ansible.cfg`/`inventory.yml`.
   - Importante: cuando Ansible ejecuta un módulo (por ejemplo `copy`, `stat`), transfiere un pequeño script Python y lo ejecuta en el host objetivo. Por eso el host debe disponer de un intérprete Python (normalmente `python3`), o Ansible fallará con errores como `/usr/bin/python3: not found`.

### Explicación del `playbook.yml` (anotado)

Playbook (resumido y comentado):

```yaml
---
- name: Configurar contenedor Docker con Ansible (sin AWS)
   hosts: all
   gather_facts: false                  # No recopilar facts (más rápido; en contenedores a veces innecesario)
   connection: community.docker.docker  # Usa el plugin de conexión Docker -> ejecuta comandos dentro del contenedor

   vars:
      index_title: "Hola desde Ansible + Docker + Terraform"
      index_message: "Configurado 100% con YAML 🚀"

   tasks:
      - name: Actualizar apt e instalar nginx
         raw: |                             # raw ejecuta el bloque tal cual en el shell del contenedor
            apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx curl python3
         # NOTA: instalamos `python3` porque Ansible necesita un intérprete en el contenedor para ejecutar módulos

      - name: Crear archivo index.html con mensaje
         copy:
            dest: /var/www/html/index.html
            content: |                         # Usa el módulo `copy` (requiere Python en el contenedor)
               <!doctype html>
               <html lang="es">
               <head><meta charset="utf-8"><title>{{ index_title }}</title></head>
               <body style="font-family: system-ui, sans-serif;">
                  <h1>{{ index_title }}</h1>
                  <p>{{ index_message }}</p>
                  <p><strong>Generado por Ansible</strong></p>
               </body>
               </html>

      - name: Iniciar o reiniciar nginx
         shell: |                            # shell ejecuta un comando; comprobamos si ya existe nginx y lo reiniciamos
            if pgrep -x nginx >/dev/null; then
               pkill -HUP nginx
            else
               nginx
            fi

```

Puntos clave:
- `connection: community.docker.docker` hace que Ansible use `docker exec` para ejecutar comandos dentro del contenedor `web1` definido en `inventory.yml`.
- `raw` es útil para ejecutar comandos simples antes de que Python y los módulos estén disponibles (por ejemplo apt-get para instalar `python3`).
- `copy` y otros módulos requieren Python en el host objetivo. Si el contenedor no tiene Python, fallarán hasta que instales Python o uses sólo `raw`/`shell`.
- Evitar `become: true` en contenedores sin `sudo`. En contenedores muchos comandos se ejecutan como root; en este repo quitamos `become` para evitar el error `sudo: not found`.

### Por qué aparecieron los errores y cómo se resolvieron

- Error `sudo: not found`: ocurrió porque las tareas usaban `become: true` y Ansible intentó usar `sudo`. Solución aplicada: quitar `become: true` del playbook para ejecutar comandos directamente como el usuario que `docker exec` usa (habitualmente root en contenedores).
- Error `/usr/bin/python3: not found`: ocurrió al intentar ejecutar módulos (p. ej. `copy`) sin Python instalado. Solución aplicada: en la tarea de apt se añadió `python3` a la lista de paquetes instalados (o alternativamente se puede modificar la imagen Docker para incluir Python por defecto).

### Rutas de instalación y comandos útiles

- Las collections se instalan por defecto en `~/.ansible/collections/collections/`.
- Para listar collections instaladas:

```bash
ansible-galaxy collection list
```

- Para probar conectividad y ver con qué usuario se ejecutan los comandos dentro del contenedor:

```bash
ansible -i inventory.yml all -c community.docker.docker -m raw -a "whoami; command -v python3 || echo no-python" -vvvv
```

- Para ejecutar el playbook con salida detallada:

```bash
ansible-playbook -i inventory.yml playbook.yml -vvvv
```

### Alternativas y buenas prácticas

- Si vas a usar Ansible frecuentemente contra contenedores, considera construir imágenes base que ya incluyan `python3` y `sudo` si realmente necesitas `become`.
- Para tareas simples en contenedores efímeros, usar `raw`/`shell` evita la dependencia de Python, pero pierdes idempotencia y la mayoría de las ventajas de los módulos Ansible.
- Mantén `requirements.yml` con las collections necesarias y versionadas cuando tengas un proyecto más grande.

---

Si quieres, puedo añadir comentarios inline directamente dentro de `ansible/playbook.yml` (como comentarios YAML) para que el archivo tenga documentación embebida. También puedo crear una pequeña sección de troubleshooting con comandos y ejemplos de salida si lo prefieres.

## Cómo instalar Ansible (macOS, Windows y Linux)

Aquí tienes instrucciones prácticas para instalar Ansible en los sistemas más comunes. Estas instrucciones cubren instalación rápida con el gestor del sistema o mediante un entorno virtual Python (recomendado si quieres aislar dependencias).

Nota importante sobre Windows: Ansible como "control node" (donde ejecutas `ansible-playbook`) no está oficialmente soportado en Windows nativo. La recomendación es usar WSL2 (Windows Subsystem for Linux) y seguir las instrucciones de Linux dentro de WSL. Alternativamente, usa una máquina Linux, una VM o contenedor para correr Ansible.

macOS (Homebrew) — la forma más sencilla

```bash
# Actualiza Homebrew
brew update

# Instala Ansible
brew install ansible

# Verifica
ansible --version
```

macOS (pip en virtualenv) — alternativa reproducible

```bash
python3 -m venv ~/.venvs/ansible
source ~/.venvs/ansible/bin/activate
pip install --upgrade pip
pip install ansible
ansible --version
```

Linux Debian / Ubuntu

Opción rápida (repositorios distro — puede ser una versión más antigua):

```bash
sudo apt update
sudo apt install -y ansible
ansible --version
```

Opción recomendada (entorno virtual para control node):

```bash
sudo apt update
sudo apt install -y python3-venv python3-pip
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate
pip install --upgrade pip
pip install ansible
ansible --version
```

RHEL / CentOS / Fedora

Fedora:
```bash
sudo dnf install -y ansible
ansible --version
```

CentOS / RHEL (puede necesitar EPEL):
```bash
sudo yum install -y epel-release
sudo yum install -y ansible
ansible --version
```

Windows (recomendado: WSL2)

1. Habilita WSL2 y instala una distribución Linux (ej. Ubuntu) desde Microsoft Store.
2. Abre la terminal de Ubuntu en WSL2 y sigue las instrucciones de "Linux Debian/Ubuntu" anteriores (recomendado usar virtualenv).

Si no puedes usar WSL2 y quieres probar en Windows nativo, puedes instalar Python 3, crear un virtualenv y `pip install ansible`, pero ten en cuenta que algunas funcionalidades y dependencias pueden no comportarse igual que en Linux.

Instalar collections necesarias (ej. `community.docker`)

Después de instalar Ansible, instala las collections requeridas desde `ansible/requirements.yml`:

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

Comprobaciones y diagnóstico

- Ver la versión instalada:
   ```bash
   ansible --version
   ```
- Ver que `ansible-galaxy` funciona y listar collections:
   ```bash
   ansible-galaxy collection list
   ```
- Si usas un virtualenv, asegúrate de activarlo antes de ejecutar `ansible-playbook`.
- Si `ansible` no se encuentra en tu PATH tras la instalación con pip, asegúrate de que `~/.local/bin` (Linux/macOS) esté en `PATH`, o ejecuta desde el virtualenv.

Notas finales

- Para entornos de CI/CD y despliegues reproducibles es buena idea usar un virtualenv o contenedor (Docker) para el control node de Ansible.
- Si trabajas en Windows, WSL2 proporciona casi la misma experiencia que Linux y evita problemas de compatibilidad.

