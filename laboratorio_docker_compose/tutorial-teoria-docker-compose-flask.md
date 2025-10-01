# Tutorial: Docker & Docker Compose con Flask y PostgreSQL

En este tutorial aprenderás a:
- Crear una aplicación simple en Python con Flask.
- Containerizar la app usando **Docker**.
- Crear y administrar contenedores con **Docker Compose**.
- Usar **variables de entorno, secretos, configuraciones y volúmenes**.
- Integrar **PostgreSQL**

---


## Crear aplicación Flask
```bash
mkdir flask-docker-compose
cd flask-docker-compose
```

## Crear entorno virtual
```bash
conda create -n lab7 python=3.9
conda activate lab7
```

O con venv de python3

```bash
python3 -m venv lab7
#python -m venv lab7
source venv/bin/activate
```

### Crear archivo de dependencias (requirements.txt)

```bash
vim requirements.txt
```

Contenido:

```
Flask==2.3.3
gunicorn==21.2.0
```


### Instalar Requisitos
```bash
pip install -r requirements.txt
```

### Crear app.py
```bash
vim app.py
```

```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/about", methods=["GET"])
def about():
    version = "0.1.0"
    return jsonify({"version": version}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
```


### Correr la aplicación localmente
```bash
Flask --app app run
```

### Probar el endpoint
```bash
curl http://127.0.0.1:5000/about
# {"version":"0.1.0"}
```

### Actualizar para leer variables de entorno
```bash
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/about", methods=["GET"])
def about():
    version = os.getenv("APP_VERSION")
    return jsonify({"version": version}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
```

### Probar el endpoint
```bash
curl http://127.0.0.1:5000/about
# {"version":null}
```

### Setear la variable de entorno en la sesión bash donde estás corriendo el servidor
```bash
export APP_VERSION=0.1.0
env | grep APP_VERSION      
#APP_VERSION=0.1.0
```

---

## 2. Containerizar con Docker

### Dockerfile
```dockerfile
FROM python:3.12-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . . #no se recomienda copiar todo, solo lo necesario
EXPOSE 8080
CMD ["python", "app.py"]
```

### Construir y correr
```bash
docker build -t flask-app:v1 .
docker run -p 7070:8080 -e APP_VERSION=1.0 flask-app:v1
```
> El parámetro -e en el comando docker run se utiliza para establecer una variable de entorno dentro del contenedor. En este caso, -e APP_VERSION=1.0 define la variable de entorno APP_VERSION con el valor 1.0, que estará disponible para la aplicación Flask que se ejecuta dentro del contenedor.

---

## 3. Introducción a Docker Compose

### compose.yaml
```yaml
services:
  flask:
    image: flask-app:v1
    ports:
      - "7070:8080"
    environment:
      - APP_VERSION=0.1.0
```

Correr:
```bash
docker compose up
```

### Cambiemos app_version en lugar de version en app.py
```python
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/about", methods=["GET"])
def about():
    version = os.getenv("APP_VERSION")
    return jsonify({"app_version": version}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
```

---

### Construir imagen desde Dockerfile
```bash
# Ubicarse dentro de flask-docker-compose
# cd flask-docker-compose
docker build -t flask-app:latest .
```


### Actualizar compose.yaml
```yaml
services:
  flask:
    image: flask-app:latest
    ports:
      - "7070:8080"
    environment:
      - APP_VERSION=0.1.0
```

### Correr contenedor de la imagen creada
```bash
# Ubicarse a la altura del archivo compose.yml
# cd ..
docker compose up
```

> Necesitamos 2 pasos, construir imagen y correr docker compose

### Una forma más simple (actualizar compose.yaml)
```yaml
services:
  flask:
    image: flask-app:latest
    build: 
      context: flask-docker-compose # nombre de la carpeta del proyecto
      dockerfile: Dockerfile

    ports:
      - "7070:8080"
    environment:
      - APP_VERSION=0.1.0
```

### Actualizar cambios localmente automáticamente
```bash
docker compose up --build
```
> Se reconstruye la imagen y se levanta el contenedor en 1 solo comando

### Probar el endpoint
```bash
curl http://127.0.0.1:7070/about
# {"version":"0.1.0"}
```

## 4. Leer variables de entorno

### Crear archivo  `.env.dev`

Archivo `.env.dev`:
```env
DB_PASSWORD = supersecretpassword
```

### Leer variable de entorno (actualizar compose.yaml)
```yaml
services:
  flask:
    image: flask-app:latest
    build: 
      context: flask-docker-compose
      dockerfile: Dockerfile

    ports:
      - "7070:8080"
    env_file:
       - ./flask-docker-compose/.env.dev # path del archivo de configuración
    environment:
      - APP_VERSION=0.1.0
```

---

## 5. Secretos en Docker Compose

Archivo `api_key.txt`:
```
my_secret_key
```

compose.yaml:
```yaml
services:
  flask:
    image: flask-app:latest
    build: 
      context: flask-docker-compose
      dockerfile: Dockerfile

    ports:
      - "7070:8080"
    env_file:
       - ./flask-docker-compose/.env.dev
    secrets:
      - api_key # referenciamos al secreto declado en la parte inferior
    environment:
      - APP_VERSION=0.1.0

secrets:
  api_key:
    file: ./flask-docker-compose/api_key.txt # path del archivo secreto
```

En app.py:
```python
@app.route("/secrets", methods=["GET"])
def secrets():
    creds = dict()
    creds["DB_PASSWORD"] = os.getenv("DB_PASSWORD")
    creds["api_key"] = open("/run/secrets/api_key", "r").read()
    return jsonify(creds), 200
```
### Otra forma:

compose.yaml:
```yaml
services:
  flask:
    image: flask-app:latest
    build: 
      context: flask-docker-compose
      dockerfile: Dockerfile

    ports:
      - "7070:8080"
    env_file:
       - ./flask-docker-compose/.env.dev
    secrets:
      - api_key 
      - source: api_key # source file
        target: /api_key # target path
    environment:
      - APP_VERSION=0.1.0

secrets:
  api_key:
    file: ./flask-docker-compose/api_key.txt # path del archivo secreto
```

```python
@app.route("/secrets", methods=["GET"])
def secrets():
    creds = dict()
    creds["DB_PASSWORD"] = os.getenv("DB_PASSWORD")
    creds["api_key"] = open("/run/secrets/api_key", "r").read()
    creds["api_key_v2"] = open("/api_key", "r").read()
    return jsonify(creds), 200
```

# Resumen: leer **secretos** en Docker Compose

## ¿Qué es un “secreto”?
Un **secreto** es un dato sensible (contraseñas, tokens, API keys). En Docker Compose se montan como **archivos de solo lectura dentro del contenedor** (no como variables de entorno).

---

## Dos formas de montar secretos en un servicio

### 1) **Forma corta (simple)**
- Solo indicas el **nombre** del secreto.
- Docker lo monta **automáticamente** en: `/run/secrets/<nombre>`.

```yaml
services:
  flask:
    image: flask-app:latest
    secrets:
      - api_key

secrets:
  api_key:
    file: ./flask-docker-compose/api_key.txt
```

**Leer en la app (Python/Flask):**
```python
from pathlib import Path
api_key = Path("/run/secrets/api_key").read_text().strip()
```

**Cuándo usarla:** cuando tu app puede leer desde la ruta por defecto `/run/secrets/...`.

---

### 2) **Forma larga (flexible)**
- Permite **elegir la ruta/archivo destino** dentro del contenedor (`target`).
- Útil si la app **espera el secreto en un path específico** o si quieres **montarlo en varias rutas**.

```yaml
services:
  flask:
    image: flask-app:latest
    secrets:
      - source: api_key
        target: /app/secure/api_key.txt   # ruta personalizada

secrets:
  api_key:
    file: ./flask-docker-compose/api_key.txt
```

**Leer en la app:**
```python
from pathlib import Path
api_key = Path("/app/secure/api_key.txt").read_text().strip()
```

**Cuándo usarla:** cuando necesites un **path personalizado**, varios montajes del mismo secreto, o ajustar permisos (`mode`, `uid`, `gid`).

---

## Tabla rápida de diferencias

| Aspecto | Forma corta | Forma larga |
|---|---|---|
| Declaración en servicio | `- api_key` | `- source: api_key; target: /ruta/archivo` |
| Ruta dentro del contenedor | Fija: `/run/secrets/api_key` | Personalizable |
| Montar en varias rutas | No | Sí |
| Complejidad | Muy simple | Más explícita y flexible |
| Uso típico | Apps que aceptan `/run/secrets/...` | Apps/imagenes que exigen rutas específicas |

---

## Buenas prácticas
- **No** pongas secretos en `environment` ni en `env_file` (se pueden filtrar en logs).
- Agrega los archivos de secretos al **`.gitignore`**.
- Si usas imágenes que soportan sufijo **`_FILE`** (p. ej., `POSTGRES_PASSWORD_FILE`), apunta esa variable al **`target`** del secreto.
- Asegúrate de que el **directorio del `target` exista** en la imagen (créalo en el `Dockerfile` si hace falta).
- Usa **la forma corta** por defecto y **la larga** cuando necesites un path concreto o varias ubicaciones.

---

- **Corta** = rápida y suficiente → el secreto queda en `/run/secrets/<nombre>`.
- **Larga** = control total → tú eliges dónde se monta el archivo del secreto.


## Comandos útiles
```bash
docker compose logs flask
```