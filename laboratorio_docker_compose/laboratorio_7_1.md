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

---

## 6. Configuraciones en Compose
Archivo `config-dev.yaml`:
```yaml
env: dev
```

### 1ra forma 
Archivo `compose.yaml`:
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
      - source: api_key
        target: /api_key
    environment:
      - APP_VERSION=0.1.0
    volumes:
      - ./flask-docker-compose/config-dev.yml:/config-dev.yml
    

secrets:
  api_key:
    file: ./flask-docker-compose/api_key.txt
```

app.py:
```python
@app.route("/config", methods=["GET"])
def config():
    creds = dict()
    creds["config_dev"] = open("/config-dev.yml", "r").read()
    return jsonify(creds), 200
```

### 2da forma 
Archivo `compose.yaml`:
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
      - source: api_key
        target: /api_key

    configs: # 2da forma
      - source: my_config
        target: /config-dev-v2.yml
    environment:
      - APP_VERSION=0.1.0
    volumes:
      - ./flask-docker-compose/config-dev.yml:/config-dev.yml
    

secrets:
  api_key:
    file: ./flask-docker-compose/api_key.txt

configs: # 2da forma
  my_config:
    file: ./flask-docker-compose/config-dev.yml
    
```

app.py:
```python
@app.route("/config", methods=["GET"])
def config():
    creds = dict()
    creds["config_dev"] = open("/config-dev.yml", "r").read()
    creds["config_dev_v2"] = open("/config-dev-v2.yml", "r").read()
    return jsonify(creds), 200
```

### Resumen de diferencias entre la 1ra y 2da forma de configuración

| Aspecto                | 1ra forma (volumes)                                 | 2da forma (configs)                                 |
|------------------------|-----------------------------------------------------|-----------------------------------------------------|
| Cómo se monta el archivo | Usando volumes: se monta el archivo local directamente en el contenedor. | Usando configs: se define una configuración en Compose y se monta en el contenedor. |
| Declaración en compose | `volumes:` con la ruta local y destino.             | `configs:` con nombre y archivo fuente, luego se referencia en el servicio. |
| Propósito principal    | Compartir archivos locales, útil para desarrollo y archivos que pueden cambiar. | Gestionar archivos de configuración, ideal para producción y archivos inmutables. |
| Acceso en el contenedor| Ruta definida en volumes (ej: `/config-dev.yml`).   | Ruta definida en configs (ej: `/config-dev-v2.yml`). |
| Ejemplo de uso en Flask| `open("/config-dev.yml", "r")`                      | `open("/config-dev-v2.yml", "r")`                   |
| Ventajas               | Simple, directo, útil para desarrollo local.        | Más seguro, controlado, permite gestión centralizada de configs. |

En resumen:
- La 1ra forma (volumes) es más simple y directa, ideal para desarrollo.
- La 2da forma (configs) es más robusta y flexible, recomendada para producción y para manejar archivos de configuración de manera centralizada en Docker Compose.
---

## 7. Integrar PostgreSQL

compose.yaml:
```yaml
services:
  flask:
    # existing code
    environment:
      # existing code
      - DB_HOST=postgres
      - DB_DATABASE=mydb
      - DB_USER=myuser
    networks:
      - private
      - public
    depends_on:
      - postgres

  postgres:
    image: postgres:16.3
    restart: always
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=myuser
      - POSTGRES_DB=mydb
      - POSTGRES_PASSWORD_FILE=/run/secrets/pg_password
    secrets:
      - pg_password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - private

secrets:
  pg_password:
    file: ./pg_password.txt

volumes:
  postgres-data:

networks:
  public:
  private:
    internal: true 
```

pg_password.txt:
```yaml
devops123
```
Creamos los contenedores

```bash
docker compose up -d
docker ps
```

## 1) Entrar a `psql` dentro del contenedor

Si ya tienes los contenedores corriendo (`docker ps`), ejecuta:

```bash
docker exec -it sesion7-postgres-1 psql -h localhost -p 5432 -U myuser -d mydb
```

> Ajusta el nombre del contenedor (`199-postgres-1`) si el tuyo es diferente.  
> Alternativa con Compose: `docker compose exec postgres psql -U myuser -d mydb`

---

## 2) Crear la tabla de ejemplo

Dentro de `psql` (prompt `mydb=#`), crea la tabla **item**:

```sql
CREATE TABLE item (
  item_id serial PRIMARY KEY,
  priority varchar(256),
  task varchar(256)
);
```

---

## 3) Crear usuario de aplicación y otorgar permisos

Aún dentro de `psql`, crea el usuario y los grants (ajusta la contraseña si deseas):

```sql
CREATE USER myapp WITH PASSWORD 'devops123';
GRANT ALL PRIVILEGES ON DATABASE mydb TO myapp;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO myapp;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO myapp;
```

> Si tu app se conectará como `myapp`, recuerda usar esas credenciales en las variables de entorno (`DB_USER`, `DB_PASSWORD`).

---

## 4) Instalar el driver en la app Flask

En tu entorno de desarrollo Python, instala **psycopg 3** con el binario y el pool:

```bash
pip install "psycopg[binary,pool]"
```
requirements.txt
```bash
Flask==2.3.3
gunicorn==21.2.0
psycopg[binary,pool]
```

app.py:
```python
#existing code
from flask import Flask, jsonify, request

from psycopg_pool import ConnectionPool

def dbConnect():
    """Create a connection pool to connect to Postgres."""

    db_host = os.environ.get('DB_HOST')
    db_database = os.environ.get('DB_DATABASE')
    db_user = os.environ.get('DB_USER')
    db_password = os.environ.get('DB_PASSWORD')

    # Create a connection URL for the database.
    url = f'host = {db_host} dbname = {db_database} user = {db_user} password = {db_password}'

    # Connect to the Postgres database.
    pool = ConnectionPool(url)
    pool.wait()

    return pool

# Create a connection pool for Postgres.
pool = dbConnect()

app = Flask(__name__)

# existing code
@app.route('/volumes', methods=['GET', 'POST'])
def volumes():
    filename = '/data/test.txt'

    if request.method == 'POST':
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        with open(filename, 'w') as f:
            f.write('Customer record')

        return 'Saved!', 201
    else:
        f = open(filename, 'r')

        return f.read(), 200


def save_item(priority, task, table, pool):
    """Inserts a new task into the Postgres database."""

    # Connect to an existing database
    with pool.connection() as conn:

        # Open a cursor to perform database operations
        with conn.cursor() as cur:

            # Prepare the database query.
            query = f'INSERT INTO {table} (priority, task) VALUES (%s, %s)'

            # Send the query to PostgreSQL.
            cur.execute(query, (priority, task))

            # Make the changes to the database persistent
            conn.commit()


def get_items(table, pool):
    """Get all the items from the Postgres database."""

    # Connect to an existing database
    with pool.connection() as conn:

        # Open a cursor to perform database operations
        with conn.cursor() as cur:

            # Prepare the database query.
            query = f'SELECT item_id, priority, task FROM {table}'

            # Send the query to PostgreSQL.
            cur.execute(query)

            items = []

            for rec in cur:
                item = {'id': rec[0], 'priority': rec[1], 'task':  rec[2]}
                items.append(item)

            # Return a list of items.
            return items


@app.route('/items', methods=['GET', 'POST'])
def items():
    match request.method:
        case 'POST':
            req = request.get_json()
            save_item(req['priority'], req['task'], 'item', pool)

            return {'message': 'item saved!'}, 201
        case 'GET':
            items = get_items('item', pool)

            return items, 200
        case _:
            return {'message': 'method not allowed'}, 405

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
```


> Recomendado: agrega también a `requirements.txt` con `pip freeze > requirements.txt`.
```bash
docker compose up --build -d
```

## Probando conexión con la BD (Insertar datos a la BD)
```bash
curl -H "Content-Type: application/json" -d '{"priority":"high","task":"doctor appointment"}' localhost:7070/items
```

```bash
curl -H "Content-Type: application/json" -d '{"priority":"low","task":"buy dinner"}' localhost:7070/items
```

```bash
curl localhost:7070/items
```