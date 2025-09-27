# Laboratorio 6.2 — Volúmenes Docker para `.env` (continuación de la guía Flask + Docker Hub + ECR)

**Duración estimada:** 60–90 min  
**Nivel:** Intermedio  
**Contexto:** En el laboratorio previo creaste y publicaste una imagen de una app Flask en Docker Hub y AWS ECR. En este laboratorio aprenderás a **inyectar configuración con archivos `.env`** **sin** hornearla dentro de la imagen, usando **volúmenes** (bind mounts) y scripts bash para múltiples entornos.

---

## Objetivos de aprendizaje

- Comprender los tipos de volúmenes en Docker y saber cuándo usar un bind mount (para archivos de configuración como .env) 
- Montar un archivo `.env` en tiempo de ejecución usando volúmenes.
- Cargar variables de entorno en Flask con `python-dotenv` (sin incluir secretos en la imagen).
- Ejecutar la app con:
  - `docker run` + `-v` (bind mount del `.env`).
  - Scripts bash para simular entornos `dev`/`prod` sin Docker Compose.
- Comprobar que el contenedor **no** contiene secretos en la imagen y que el `.env` vive fuera, en el host.

---

## Requisitos

- Haber completado la guía **"Contenedores Docker con Flask - Dockerfile, Docker Hub y ECR"** y contar con el proyecto `flask-docker-app`.
- Docker (sin necesidad de Docker Compose).
- Python 3.x.
- (Opcional) Cuenta en Docker Hub y acceso a AWS ECR para publicar la nueva versión.

---

## 0) Estructura sugerida del proyecto

Trabajaremos **sobre el mismo repo** del laboratorio anterior. Crea una carpeta para este lab:

```
flask-docker-app/
├─ app.py
├─ requirements.txt
├─ Dockerfile
├─ .dockerignore
├─ env/
│  ├─ .env.example
│  ├─ .env.dev
│  └─ .env.prod
├─ scripts/
│  ├─ run-dev.sh
│  └─ run-prod.sh
└─ lab6.2/   <-- evidencias/capturas de este laboratorio
```

> **Importante:** Nunca subas el `.env` real al repo. Solo versiona `.env.example`.

---

## 1) Preparar archivos `.env`

Dentro de `env/` crea un **.env.example** con variables de muestra:

```bash
mkdir -p env
vim env/.env.example
```

Contenido sugerido:

```
# Variables de ejemplo (NO usar para producción)
APP_NAME=Flask Docker Demo
APP_ENV=development
SECRET_MESSAGE=Esto-es-un-ejemplo-no-un-secreto-real
FEATURE_FLAG_SHOW_INFO=true
PORT=5000
```

Ahora **copia** el ejemplo para crear tu `.env` local (no versionado):

```bash
cp env/.env.example env/.env
# Edita valores reales solo en env/.env
```

Añade a tu `.gitignore`:

```
env/.env
```

---

## 2) Cargar `.env` en la app Flask con `python-dotenv`

### 2.1 Actualiza dependencias

Agrega `python-dotenv` en `requirements.txt`:

```
Flask==2.3.3
gunicorn==21.2.0
python-dotenv==1.0.1
```

### 2.2 Modifica `app.py` para leer variables

Reemplaza el contenido (o agrega lo necesario) para cargar el `.env` y exponer un endpoint de verificación:

```python
import os
from flask import Flask, jsonify, render_template_string
from dotenv import load_dotenv

# Carga .env si existe en el working dir (/app dentro del contenedor)
# Nota: load_dotenv() no falla si el archivo no existe
load_dotenv()

app = Flask(__name__)

@app.route('/')
def home():
    html = '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>{{ app_name }}</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 50px; }
            .container { max-width: 600px; margin: 0 auto; }
            h1 { color: #2196F3; }
            code { background: #f4f4f4; padding: 2px 6px; border-radius: 4px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🐳 {{ app_name }}</h1>
            <p>Entorno: <code>{{ app_env }}</code></p>
            <p><a href="/api/health">/api/health</a> | <a href="/api/info">/api/info</a> | <a href="/api/app-config">/api/app-config</a></p>
        </div>
    </body>
    </html>
    '''
    return render_template_string(html,
                                  app_name=os.getenv("APP_NAME", "Flask Docker App"),
                                  app_env=os.getenv("APP_ENV", "unknown"))

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/api/info')
def info():
    import platform, socket
    return jsonify({
        "app": os.getenv("APP_NAME", "Flask Docker Demo"),
        "version": "1.1.0",
        "python_version": platform.python_version(),
        "hostname": socket.gethostname()
    })

@app.route('/api/app-config')
def app_config():
    # Devuelve una vista segura (no expongas secretos reales)
    safe = {
        "APP_NAME": os.getenv("APP_NAME"),
        "APP_ENV": os.getenv("APP_ENV"),
        "FEATURE_FLAG_SHOW_INFO": os.getenv("FEATURE_FLAG_SHOW_INFO"),
        # Nunca retornes variables sensibles (ej: DB_PASSWORD, API_KEYS, etc.)
        "SECRET_MESSAGE_present": "SECRET_MESSAGE" in os.environ
    }
    return jsonify(safe)

if __name__ == '__main__':
    port = int(os.getenv("PORT", "5000"))
    app.run(host='0.0.0.0', port=port, debug=True)
```

> **Nota:** `load_dotenv()` leerá `/app/.env` dentro del contenedor — ahí montaremos el archivo desde el host.

---

## 3) Ajustar Dockerfile (sin hornear `.env`)

No copies `.env` a la imagen. Tu `Dockerfile` puede quedarse igual; solo reconstruiremos la imagen por el cambio en `requirements.txt`/`app.py`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

RUN adduser --disabled-password --gecos '' appuser \
 && chown -R appuser:appuser /app
USER appuser

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

---

## 4) Construir nueva imagen (v1.1) y ejecutar montando `.env` con volumen

```bash
# Construye nueva versión
docker build -t flask-docker-app:1.1 .

# Ejecuta montando el .env como archivo de solo lectura dentro del contenedor
docker run -d \
  --name flask-env \
  -p 8080:5000 \
  -v "$(pwd)/env/.env:/app/.env:ro" \
  flask-docker-app:1.1
```

Prueba:

```bash
curl http://localhost:8080/api/app-config
# Debe mostrar tus variables (sin exponer contenido de SECRET_MESSAGE)
```

**Verifica el montaje**:

```bash
docker inspect flask-env --format='{{json .Mounts}}' | jq
```

Reinicia para aplicar cambios en `.env` (las variables se cargan al iniciar el proceso):

```bash
docker restart flask-env
```

Para limpiar:

```bash
docker rm -f flask-env
```

> **Windows (PowerShell):**
> ```powershell
> docker run -d --name flask-env -p 8080:5000 `
>   -v "${PWD}\env\.env:/app/.env:ro" `
>   flask-docker-app:1.1
> ```

---

## 5) Scripts para múltiples entornos con **volúmenes** (`dev` / `prod`)

Crea la carpeta de scripts y archivos de configuración:

```bash
mkdir -p scripts env
```

### Crear archivos de configuración por entorno

Crea `env/.env.dev`:

```bash
APP_NAME=Flask Docker Demo
APP_ENV=development
FEATURE_FLAG_SHOW_INFO=true
SECRET_MESSAGE=esto-es-un-secreto
PORT=5000
```

Crea `env/.env.prod`:

```bash
APP_NAME=Flask Docker Demo
APP_ENV=production
FEATURE_FLAG_SHOW_INFO=false
SECRET_MESSAGE=esto-es-un-secreto
PORT=5000
```

### Script para entorno de desarrollo

Crea `scripts/run-dev.sh`:

```bash
#!/bin/bash
echo "🚀 Iniciando Flask en modo DESARROLLO..."

# Detener contenedor si existe
docker stop flask-env 2>/dev/null || true
docker rm flask-env 2>/dev/null || true

# Ejecutar en modo development
docker run -d \
  --name flask-dev \
  -p 8080:5000 \
  -v "$(pwd)/env/.env.dev:/app/.env:ro" \
  --restart unless-stopped \
  flask-docker-app:1.1
```
### Validación: ¿El archivo `.env` está en la imagen o solo en el volumen?

**1. Verifica que la imagen NO contiene el archivo `.env` ni secretos:**

```bash
docker run --rm -it flask-docker-app:1.1 /bin/sh
# Dentro del contenedor, ejecuta:
ls /app/.env
# Resultado esperado: "No such file or directory"
exit
```

**2. Verifica que el archivo `.env` SÍ aparece en el contenedor con el volumen montado:**

```bash
docker exec -it flask-dev cat /app/.env
# Resultado esperado: ves el contenido de tu archivo .env.dev
```

Esto demuestra que los secretos y la configuración viven fuera de la imagen y solo se inyectan al contenedor en tiempo de ejecución usando el volumen.

### ¿Cómo ingresar a un contenedor en ejecución y explorar archivos?

Para abrir una terminal interactiva dentro de un contenedor ya corriendo (por ejemplo, para inspeccionar archivos o ejecutar comandos):

```bash
docker exec -it flask-dev /bin/sh
# Ahora puedes usar comandos como ls, cat, etc.
ls /app
cat /app/.env
exit  # Para salir de la sesión interactiva
```

También puedes ejecutar un solo comando directamente (sin entrar en modo interactivo):

```bash
docker exec -it flask-dev cat /app/.env
```

Esto te permite validar el contenido del archivo `.env` dentro del contenedor y comprobar que está siendo montado correctamente desde tu máquina local.

### ¿Qué hace el parámetro `-v`?

El parámetro `-v "$(pwd)/env/.env.dev:/app/.env:ro"` monta el archivo `.env.dev` de tu máquina local dentro del contenedor, en la ruta `/app/.env`.

- **`-v`**: Indica que vas a montar un volumen (archivo o carpeta).
- **`$(pwd)/env/.env.dev`**: Ruta absoluta al archivo en tu máquina.
- **`:/app/.env`**: Ruta donde aparecerá el archivo dentro del contenedor.
- **`:ro`**: Solo lectura, el contenedor puede leer pero no modificar el archivo.

Esto permite que la app Flask lea las variables de entorno desde ese archivo usando `python-dotenv`, sin que el archivo se copie ni se hornee en la imagen. Si editas `.env.dev` en tu máquina, solo necesitas reiniciar el contenedor para que Flask use los nuevos valores.

### ¿Cómo reiniciar el contenedor para aplicar cambios en `.env`?

Si modificas el archivo `.env.dev`, ejecuta:

```bash
docker restart flask-dev
```

Esto detiene y vuelve a iniciar el contenedor, aplicando los nuevos valores del archivo `.env.dev`.

No necesitas reconstruir la imagen ni eliminar el contenedor, solo reiniciarlo.

```bash
echo "✅ Flask DEV ejecutándose en http://localhost:8080"
echo "📋 Para ver logs: docker logs -f flask-dev"
echo "🛑 Para detener: docker stop flask-dev"
```

```bash
chmod +x scripts/run-dev.sh
```

### Script para entorno de producción

Crea `scripts/run-prod.sh`:

```bash
#!/bin/bash
echo "🚀 Iniciando Flask en modo PRODUCCIÓN..."

# Detener contenedor si existe
docker stop flask-prod 2>/dev/null || true
docker rm flask-prod 2>/dev/null || true

# Ejecutar en modo production
docker run -d \
  --name flask-prod \
  -p 8081:5000 \
  -v "$(pwd)/env/.env.prod:/app/.env:ro" \
  --restart unless-stopped \
  flask-docker-app:1.1

echo "✅ Flask PROD ejecutándose en http://localhost:8081"
echo "📋 Para ver logs: docker logs -f flask-prod"
echo "🛑 Para detener: docker stop flask-prod"
```
Brindar permisos de ejecución: 
```bash
chmod +x scripts/run-prod.sh
```

### Script para gestión general

Crea `scripts/manage.sh`:

```bash
cat > scripts/manage.sh << 'EOF'
#!/bin/bash

case "$1" in
  "dev")
    echo "🔧 Iniciando entorno de desarrollo..."
    ./scripts/run-dev.sh
    ;;
  "prod")
    echo "🏭 Iniciando entorno de producción..."
    ./scripts/run-prod.sh
    ;;
  "status")
    echo "📊 Estado de contenedores Flask:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter name=flask
    ;;
  "stop")
    echo "🛑 Deteniendo todos los contenedores Flask..."
    docker stop flask-dev flask-prod 2>/dev/null || true
    docker rm flask-dev flask-prod 2>/dev/null || true
    echo "✅ Contenedores detenidos"
    ;;
  "logs")
    if [ "$2" = "dev" ]; then
      docker logs -f flask-dev
    elif [ "$2" = "prod" ]; then
      docker logs -f flask-prod
    else
      echo "Uso: $0 logs [dev|prod]"
    fi
    ;;
  *)
    echo "Uso: $0 {dev|prod|status|stop|logs [dev|prod]}"
    echo ""
    echo "Comandos:"
    echo "  dev     - Iniciar entorno de desarrollo (puerto 8080)"
    echo "  prod    - Iniciar entorno de producción (puerto 8081)"
    echo "  status  - Ver estado de contenedores"
    echo "  stop    - Detener todos los contenedores"
    echo "  logs    - Ver logs (especificar dev o prod)"
    exit 1
    ;;
esac
EOF

chmod +x scripts/manage.sh
```

### Uso de los scripts

```bash
# Iniciar entorno de desarrollo
./scripts/manage.sh dev
curl http://localhost:8080/api/app-config

# Iniciar entorno de producción
./scripts/manage.sh prod
curl http://localhost:8081/api/app-config

# Ver estado de ambos entornos
./scripts/manage.sh status

# Ver logs de desarrollo
./scripts/manage.sh logs dev

# Detener todos los entornos
./scripts/manage.sh stop
```

> **Alternativa:** Podrías usar `env_file:` en Compose, pero aquí **forzamos el uso de volúmenes** para que el `.env` nunca sea leído por el CLI/Compose del host, sino directamente por la app dentro del contenedor.

---

## 6) (Opcional) Publicar `v1.1` en Docker Hub y/o ECR

Reutiliza los pasos del lab anterior, cambiando la etiqueta:

```bash
# Docker Hub
docker tag flask-docker-app:1.1 TU_USUARIO/flask-docker-app:1.1
docker push TU_USUARIO/flask-docker-app:1.1

# AWS ECR (ejemplo)
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/flask-docker-app"
docker tag flask-docker-app:1.1 $ECR_URI:1.1
docker push $ECR_URI:1.1
```

En `docker-compose.yml` puedes apuntar a la imagen del registro remoto en lugar de la local.

---


## 7) Solución de problemas comunes

- **La app no ve mis variables**  
  Asegúrate de:
  - Montar el archivo en `/app/.env` con `:ro`.
  - Haber llamado a `load_dotenv()` antes de leer las variables.
  - Reiniciar el contenedor tras cambios en `.env`.

- **No quiero que `SECRET_MESSAGE` salga por ningún endpoint**  
  En `/api/app-config` devolvemos solo una bandera `SECRET_MESSAGE_present`. Nunca expongas su valor.

- **Mi `.env` se filtró al repo**  
  Verifica `.gitignore` y elimina el archivo del historial si fue subido por error.

- **Quiero recargar sin reiniciar el contenedor**  
  Las env vars se leen al arrancar. Para cambios dinámicos, deberías mover la lectura a cada request (costo adicional) o usar un sistema de configuración externo (p. ej., AWS SSM/Secrets Manager).

---

## Consideraciones de seguridad

- **Nunca** hornees secretos en la imagen ni los subas al repo.
- Usa permisos `:ro` al montar el `.env`.
- Para producción, considera **Docker secrets** o gestores como **AWS Secrets Manager**.
- Minimiza el número de variables realmente sensibles en `.env`.

---

## Checklist de éxito

- [ ] `python-dotenv` agregado y `app.py` lee variables con `load_dotenv()`.
- [ ] Imagen `flask-docker-app:1.1` construida.
- [ ] Contenedor corre con `-v $(pwd)/env/.env:/app/.env:ro`.
- [ ] Endpoint `/api/app-config` refleja variables sin exponer secretos.
- [ ] Scripts bash funcionan para entornos `dev` y `prod` montando diferentes `.env`.
- [ ] Capturas que evidencian el **volumen montado** y la app leyendo config.

---

## Entregables

- **URL de repositorio** (GitHub/GitLab).
- Carpeta **`lab6.2/`** con:
  1. `env/.env.example`, `.env.dev`, `.env.prod`
  2. Scripts en `scripts/` (`run-dev.sh`, `run-prod.sh`, `manage.sh`)
  3. `app.py` y `requirements.txt` actualizados
  4. **Capturas obligatorias**:
     - `docker inspect` de `Mounts` mostrando el bind mount del `.env`.
     - Respuesta de `GET /api/app-config` en `dev` y `prod`.
     - `./scripts/manage.sh status` mostrando ambos entornos.
- (Opcional) Enlace a la imagen `v1.1` en Docker Hub / ECR.

---

¡Listo! Con este lab demuestras un flujo profesional: **imagen inmutable** + **configuración externa** vía volúmenes, manteniendo los secretos **fuera** de la imagen y del repositorio.
