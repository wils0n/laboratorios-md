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