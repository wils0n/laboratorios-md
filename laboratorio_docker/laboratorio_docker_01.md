# Guía: Contenedores Docker con Flask - Dockerfile, Docker Hub

**Duración estimada:** 60–90 min  
**Nivel:** Intermedio  
**Contexto:** Aprenderás a crear un contenedor Docker de una aplicación Flask, construir la imagen, y publicarla en Docker Hub.

---

## Objetivos de aprendizaje

- Crear un Dockerfile para una aplicación Flask
- Construir una imagen Docker personalizada
- Publicar la imagen en Docker Hub
- Ejecutar el contenedor localmente

---

## Requisitos del laboratorio

- Docker instalado y funcionando
- Cuenta en Docker Hub
- Python 3.x instalado
- Editor de texto (vim, VS Code, etc.)

---

## 1. Crear la aplicación Flask

### Crear estructura del proyecto

```bash
mkdir flask-docker-app
cd flask-docker-app
```

### Crear la aplicación Flask (app.py)

```bash
vim app.py
```

Contenido:

```python
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

# Página principal
@app.route('/')
def home():
    html = '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Flask Docker App</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 50px; }
            .container { max-width: 600px; margin: 0 auto; }
            h1 { color: #2196F3; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🐳 Flask Docker App</h1>
            <p>¡Aplicación Flask ejecutándose en Docker!</p>
            <p><a href="/api/health">Verificar estado de la API</a></p>
            <p><a href="/api/info">Información del contenedor</a></p>
        </div>
    </body>
    </html>
    '''
    return render_template_string(html)

# API endpoints
@app.route('/api/health')
def health():
    return jsonify({
        "status": "healthy",
        "message": "Flask app funcionando correctamente"
    })

@app.route('/api/info')
def info():
    import os
    return jsonify({
        "app": "Flask Docker Demo",
        "version": "1.0.0",
        "python_version": os.sys.version,
        "hostname": os.uname().nodename
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
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

---

## 2. Crear el Dockerfile

```bash
vim Dockerfile
```

Contenido:

```dockerfile
# Usar imagen base oficial de Python
FROM python:3.11-slim

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivo de dependencias
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código de la aplicación
COPY app.py .

# Exponer puerto 5000
EXPOSE 5000

# Crear usuario no-root para seguridad
RUN adduser --disabled-password --gecos '' appuser
RUN chown -R appuser:appuser /app
USER appuser

# Comando para ejecutar la aplicación
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

### Crear .dockerignore (opcional)

```bash
vim .dockerignore
```

Contenido:

```
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env/
pip-log.txt
pip-delete-this-directory.txt
.tox
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.log
.git
.mypy_cache
.pytest_cache
.hypothesis
```

---

## 3. Construir la imagen Docker

### Construir la imagen

```bash
# Sintaxis: docker build -t nombre-imagen:tag .
docker build -t flask-docker-app:1.0 .
```

### Verificar que la imagen se creó

```bash
docker images | grep flask-docker-app
```

### Ejecutar el contenedor localmente

```bash
# Ejecutar en modo detached en puerto 8080
docker run -d -p 8080:5000 --name mi-flask-app flask-docker-app:1.0

# Verificar que está ejecutándose
docker ps

# Probar la aplicación
curl http://localhost:8080
curl http://localhost:8080/api/health
```

### Ver logs del contenedor

```bash
docker logs mi-flask-app
```

### Detener el contenedor

```bash
docker stop mi-flask-app
docker rm mi-flask-app
```

---

## 4. Publicar en Docker Hub

### Paso 1: Crear repositorio en Docker Hub

Ve a https://hub.docker.com/

### Paso 2: Login en Docker Hub

```bash
docker login
```

Ingresa tu usuario y contraseña de Docker Hub.

**Importante:** Asegúrate de usar tu usuario real de Docker Hub, no "tu-usuario".

### Paso 3: Etiquetar la imagen

```bash
# Sintaxis: docker tag imagen-local usuario-dockerhub/nombre-repositorio:tag
# ¡IMPORTANTE! Reemplaza "tu-usuario" con tu usuario real de Docker Hub
docker tag flask-docker-app:1.0 tu-usuario/flask-docker-app:1.0
docker tag flask-docker-app:1.0 tu-usuario/flask-docker-app:latest

# Ejemplo con usuario real:
# docker tag flask-docker-app:1.0 wilsonjulca/flask-docker-app:1.0
```

### Paso 4: Publicar en Docker Hub

```bash
# Subir la imagen etiquetada
# ¡IMPORTANTE! Usar tu usuario real de Docker Hub
docker push tu-usuario/flask-docker-app:1.0
docker push tu-usuario/flask-docker-app:latest

# Si obtienes error "repository does not exist", crea el repositorio primero en hub.docker.com
```

### Solución de problemas comunes

**Error: "repository does not exist or may require authorization"**

1. Verifica que estás logueado:
   ```bash
   docker login
   ```

2. Asegúrate de usar tu usuario real (no "tu-usuario"):
   ```bash
   # Verificar tu usuario actual
   docker info | grep Username
   ```

3. Crea el repositorio en Docker Hub manualmente:
   - Ve a https://hub.docker.com/
   - Crea un nuevo repositorio llamado "flask-docker-app"

4. Re-etiquetar con tu usuario correcto:
   ```bash
   docker tag flask-docker-app:1.0 TU_USUARIO_REAL/flask-docker-app:1.0
   docker push TU_USUARIO_REAL/flask-docker-app:1.0
   ```

### Paso 4: Verificar en Docker Hub

1. Ve a https://hub.docker.com/
2. Busca tu repositorio: `tu-usuario/flask-docker-app`
3. Verifica que las imágenes aparezcan

### Paso 5: Probar descarga desde Docker Hub

```bash
# Eliminar imagen local
docker rmi tu-usuario/flask-docker-app:latest

# Descargar y ejecutar desde Docker Hub
docker run -d -p 8080:5000 tu-usuario/flask-docker-app:latest
```

---
## 7. Comandos útiles

### Docker básico

```bash
# Ver imágenes
docker images

# Ver contenedores ejecutándose
docker ps

# Ver todos los contenedores
docker ps -a

# Eliminar contenedor
docker rm nombre-contenedor

# Eliminar imagen
docker rmi nombre-imagen

# Ver uso de espacio de Docker
docker system df

# Limpiar recursos no utilizados
docker system prune
```

### ECR específicos

```bash
# Listar repositorios ECR
aws ecr describe-repositories --region us-east-1

# Eliminar repositorio ECR
aws ecr delete-repository --repository-name flask-docker-app --force --region us-east-1

# Ver políticas de repositorio
aws ecr get-repository-policy --repository-name flask-docker-app --region us-east-1
```

---

## Checklist de éxito

- [ ] Aplicación Flask creada y funcionando localmente
- [ ] Dockerfile creado correctamente
- [ ] Imagen Docker construida exitosamente
- [ ] Contenedor ejecutándose localmente en puerto 8080
- [ ] Imagen publicada en Docker Hub
- [ ] Imagen publicada en AWS ECR
- [ ] Script de automatización funcionando
- [ ] Aplicación accesible desde ambos registros

---

## Consideraciones de seguridad

- Usar imágenes base oficiales y actualizadas
- Crear usuarios no-root en el contenedor
- No incluir secretos en el Dockerfile
- Usar .dockerignore para excluir archivos sensibles
- Mantener imágenes pequeñas para reducir superficie de ataque
- Escanear imágenes en busca de vulnerabilidades

---

¡Felicidades! Has aprendido a contenerizar una aplicación Flask y publicarla en registros públicos y privados.