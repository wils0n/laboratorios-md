# Laboratorio 10.1: CI/CD en GitLab - Publicación de Imágenes Docker a Docker Hub

**Duración estimada:** 60–90 min  
**Nivel:** Intermedio  
**Contexto:** Este laboratorio es la versión GitLab del flujo de CI/CD visto en el Laboratorio 9.1 (GitHub Actions). Aprenderás a construir y publicar imágenes Docker automáticamente en Docker Hub usando GitLab CI/CD.

---

## Objetivos de aprendizaje

- Crear un pipeline CI/CD en GitLab para aplicaciones Python
- Construir imágenes Docker dentro del pipeline
- Automatizar la publicación de imágenes en Docker Hub
- Configurar variables seguras en GitLab CI/CD
- Aplicar tagging semántico a las imágenes Docker
- Entender la integración entre jobs (test → docker)

---

## Requisitos previos

✅ Cuenta en GitLab ([https://gitlab.com/](https://gitlab.com/))  
✅ Cuenta en Docker Hub ([https://hub.docker.com/](https://hub.docker.com/))  
✅ Proyecto en GitLab con código Python (`hello.py`, `requirements.txt`, `tests/`) 

✅ Familiaridad con Docker y contenedores

---

## Estructura del proyecto

```
gitlab_ci_demo/
├── .gitlab-ci.yml              # Pipeline principal de CI/CD
├── hello.py                    # Aplicación Python
├── tests/
│   └── test_hello.py          # Tests unitarios
├── requirements.txt            # Dependencias Python
├── Dockerfile                  # Dockerfile para la app
└── README.md
```

---

## Parte 1: Preparación del Dockerfile

**Archivo: `Dockerfile`**

```dockerfile
FROM python:3.11-slim

# Establecer directorio de trabajo
WORKDIR /app

# Copiar requirements.txt primero (para aprovechar cache de Docker)
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código fuente
COPY hello.py .

# Variables de entorno
ENV PYTHONUNBUFFERED=1

# Comando por defecto (puedes cambiarlo según tu app)
CMD ["python", "hello.py"]
```

---

## Parte 2: Configuración de Docker Hub y Variables en GitLab

### 2.1 Crear un Access Token en Docker Hub

1. Ve a [Docker Hub](https://hub.docker.com/)
2. Account Settings → Security → New Access Token
3. Nómbralo `gitlab-ci` y copia el token

### 2.2 Configurar Variables en GitLab CI/CD

1. Ve a tu proyecto en GitLab
2. Settings → CI/CD → Variables
3. Agrega:
   - `DOCKERHUB_USERNAME`: tu usuario de Docker Hub
   - `DOCKERHUB_TOKEN`: el token generado

**Importante:** Marca `DOCKERHUB_TOKEN` como **Protected** y **Masked**.

---

## Parte 3: Crear el pipeline `.gitlab-ci.yml`

**Archivo: `.gitlab-ci.yml`**

```yaml
stages:
  - test
  - docker

test:
  stage: test
  image: python:3.11-slim
  script:
    - pip install -r requirements.txt
    - PYTHONPATH="$CI_PROJECT_DIR" pytest tests/ -v --junitxml=test-results.xml --cov=. --cov-report=xml --cov-report=html

build_and_push:
  stage: docker
  image: docker:24.0.5
  services:
    - docker:24.0.5-dind
  variables:
    DOCKER_HOST: tcp://docker:2375/
    DOCKER_TLS_CERTDIR: ""
    IMAGE_NAME: "$DOCKERHUB_USERNAME/gitlab-ci-demo"
    TAG: "$CI_COMMIT_REF_NAME-$CI_COMMIT_SHORT_SHA"
  before_script:
    - echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
  script:
    - docker build -t $IMAGE_NAME:$TAG .
    - docker tag $IMAGE_NAME:$TAG $IMAGE_NAME:latest
    - docker push $IMAGE_NAME:$TAG
    - docker push $IMAGE_NAME:latest
  only:
    - main
```

---

## Parte 4: Explicación del pipeline

- **stages:** Define el orden: primero test, luego docker
- **test:** Instala dependencias y ejecuta tests con pytest
- **build_and_push:**
  - Usa Docker-in-Docker para poder construir y pushear imágenes
  - Login seguro a Docker Hub usando variables
  - Tagging: usa rama y hash corto (`main-abc1234`) y `latest`
  - Solo se ejecuta en la rama `main`

---

## Parte 5: Probar el pipeline

1. Haz commit y push de `.gitlab-ci.yml`, `Dockerfile`, y el código Python:

```bash
git add .gitlab-ci.yml Dockerfile hello.py requirements.txt tests/
git commit -m "feat: pipeline GitLab CI para Docker Hub"
git push origin main
```

2. Ve a **CI/CD → Pipelines** en GitLab y observa la ejecución.
3. Verifica en Docker Hub que se haya publicado la imagen:
   - `tu-usuario/gitlab-ci-demo:main-abc1234`
   - `tu-usuario/gitlab-ci-demo:latest`

---

## Parte 6: Buenas prácticas y troubleshooting

- Usa tokens, nunca contraseñas, para Docker Hub
- Marca los secrets como **Protected** y **Masked**
- No hagas push en ramas que no sean `main` (usa `only: - main`)
- Si falla el login, revisa los nombres de las variables y el token
- Si el build es lento, revisa el uso de cache en Docker

---

## Checklist de Éxito

- [ ] Pipeline ejecuta tests y publica imagen en Docker Hub
- [ ] Imagen tiene tags correctos (`main-xxxxxxx`, `latest`)
- [ ] Secrets nunca se exponen en logs
- [ ] Solo se publica en rama main

---

## Entregables

1. **Repositorio GitLab** con:
   - `.gitlab-ci.yml` funcional
   - Dockerfile y código Python
2. **Capturas de pantalla:**
   - Pipeline exitoso
   - Imagen publicada en Docker Hub
3. **Reflexión:**
   - ¿Qué diferencias notaste respecto a GitHub Actions?
   - ¿Qué ventajas/desventajas ves en GitLab CI?

---

📘 **Autor:**  
Wilson Julca Mejía  
Curso: *DevOps y GitLab CI/CD – Python y Docker*  
Universidad de Ingeniería y Tecnología (UTEC)
