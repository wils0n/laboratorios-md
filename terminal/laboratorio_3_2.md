# Lab: Automatización con alias de Git y despliegue de Django

**Duración estimada:** 45–60 min  
**Nivel:** Intermedio  
**Contexto:** Aprenderás a crear alias útiles para Git, clonar un repositorio usando esos alias, crear un entorno virtual de Python, instalar dependencias y levantar un servidor Django de forma automatizada con Bash.

---

## Objetivos de aprendizaje

- Crear y usar alias personalizados para Git.
- Automatizar el flujo de trabajo de clonado y despliegue de una app Django.
- Crear y activar entornos virtuales de Python.
- Instalar dependencias desde un archivo `requirements.txt`.
- Levantar el servidor de desarrollo de Django.

---

## Ejercicio 1: Configura alias para Git

1. Abre tu terminal y agrega los siguientes alias a tu archivo `~/.bashrc` o `~/.zshrc`:

```bash
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gcl='git clone'
```

2. Recarga tu configuración de shell:

   ```bash
   source ~/.bashrc   # o source ~/.zshrc si usas zsh
   ```

3. Prueba tus alias:

   ```bash
   gcl https://github.com/wils0n/django-notes-app.git
   gs
   ```

---

## Ejercicio 2: Clona el repositorio usando tu alias

1. Clona el repositorio con tu alias:

   ```bash
   gcl https://github.com/wils0n/django-notes-app.git
   cd django-notes-app
   ```

---

## Ejercicio 3: Crea un entorno virtual de Python 3

1. Crea el entorno virtual:

   ```bash
   python3 -m venv venv
   ```

2. Activa el entorno virtual:

   ```bash
   source venv/bin/activate
   ```

3. Verifica que el entorno está activo (el prompt debe mostrar `(venv)`).

---

## Ejercicio 4: Instala las dependencias

1. Instala las dependencias del proyecto:

   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

---

## Ejercicio 5: Levanta el servidor de desarrollo de Django

1. Ejecuta las migraciones iniciales:

   ```bash
   python manage.py migrate
   ```

2. Levanta el servidor:

   ```bash
   python manage.py runserver
   ```

3. Abre tu navegador y accede a [http://127.0.0.1:8000](http://127.0.0.1:8000) para ver la aplicación funcionando.

---

## Ejercicio 6: Automatiza todo con un script Bash

1. Crea un archivo llamado `deploy_django.sh` con el siguiente contenido:

```bash
#!/bin/bash


# Clonar el repositorio si no existe
if [ ! -d "django-notes-app" ]; then
    git clone https://github.com/wils0n/django-notes-app.git
fi

cd django-notes-app

# Crear entorno virtual si no existe
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activar entorno virtual
source venv/bin/activate

# Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt

# Migraciones y levantar servidor
python manage.py migrate
python manage.py runserver
```

2. Brindando permisos de ejecución

   ```bash
   chmod +x deploy_django.sh
   ```

3. Ejecutando script

   ```bash
   ./deploy_django.sh
   ```

### PowerShell script to deploy Django app on Windows

```bash
# Clonar el repositorio si no existe
if (-not (Test-Path "django-notes-app")) {
    git clone https://github.com/wils0n/django-notes-app.git
}

Set-Location django-notes-app

# Crear entorno virtual si no existe
if (-not (Test-Path "venv")) {
    python -m venv venv
}

# Activar entorno virtual
& .\venv\Scripts\Activate.ps1

# Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt

# Migraciones y levantar servidor
python manage.py migrate
python manage.py runserver
```
