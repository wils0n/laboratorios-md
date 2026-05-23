# Laboratorio: CI/CD en GitLab - Despliegue a AWS Lambda con Serverless Framework v4

**Duración estimada:** 120–150 min  
**Nivel:** Intermedio–Avanzado  
**Contexto:** Este laboratorio es la versión GitLab del flujo de CI/CD visto en la intro_gitlab.md. Aprenderás a desplegar automáticamente una función Python a AWS Lambda usando Serverless Framework v4 desde un pipeline GitLab CI/CD con lint, tests, cache y aprobación manual.

---

## Objetivos de aprendizaje

- Crear un pipeline CI/CD en GitLab para aplicaciones Python
- Crear una API REST con FastAPI
- Adaptar una app FastAPI para correr en AWS Lambda con Mangum
- Escribir un handler Lambda compatible con API Gateway v2
- Configurar Serverless Framework v4 con `serverless.yml`
- Desplegar una función Python a AWS Lambda desde el pipeline
- Configurar variables seguras (credenciales AWS) en GitLab CI/CD
- Usar cache de pipeline (pip y npm) para acelerar ejecuciones
- Pasar artifacts entre jobs
- Ejecutar jobs en paralelo (lint y test)
- Usar `rules:` para controlar cuándo corre cada job
- Implementar deploy con aprobación manual (`when: manual`)

---

## Requisitos previos

✅ Cuenta en GitLab ([https://gitlab.com/](https://gitlab.com/))  
✅ Cuenta en AWS con permisos para Lambda, API Gateway, IAM y CloudFormation  
✅ Cuenta en Serverless Framework ([https://app.serverless.com/](https://app.serverless.com/)) — requerida por v4  
✅ Proyecto en GitLab con código Python (`hello.py`, `requirements.txt`, `tests/`)  
✅ Node.js 20+ instalado localmente (para probar Serverless CLI)

---

## Estructura del proyecto

```
gitlab_lambda_demo/
├── .gitlab-ci.yml              # Pipeline principal de CI/CD
├── handler.py                  # Handler para AWS Lambda
├── hello.py                    # Aplicación Python (ejecución local)
├── serverless.yml              # Configuración de Serverless Framework
├── package.json                # Dependencias Node.js (serverless plugins)
├── tests/
│   └── test_hello.py          # Tests unitarios
├── requirements.txt            # Dependencias Python (producción / Lambda)
├── requirements-dev.txt        # Dependencias de desarrollo (lint, test)
└── README.md
```

---

## Parte 1: Archivos de dependencias

Separar dependencias de producción y desarrollo asegura que el ZIP que sube a Lambda sea lo más pequeño posible y no incluya herramientas de CI.

**Archivo: `requirements.txt`** (va incluido en el ZIP de Lambda)

```
fastapi==0.111.0
mangum==0.17.0
```

- `fastapi`: framework web para construir APIs con Python
- `mangum`: adaptador que traduce eventos Lambda/API Gateway al protocolo ASGI que FastAPI entiende

**Archivo: `requirements-dev.txt`** (solo usado en el runner de CI/CD)

```
-r requirements.txt
uvicorn==0.29.0
httpx==0.27.0
pytest==8.1.1
pytest-cov==5.0.0
flake8==7.0.0
```

- `uvicorn`: servidor ASGI para correr FastAPI localmente
- `httpx`: cliente HTTP requerido por `TestClient` de FastAPI para los tests

> `serverless-python-requirements` empaqueta solo `requirements.txt` dentro del ZIP de Lambda. `requirements-dev.txt` se instala únicamente en el job `test` del pipeline y nunca llega a producción.

---

## Parte 2: API con FastAPI y adaptador Mangum

### 2.1 Aplicación FastAPI

FastAPI define las rutas como funciones Python con type hints. Genera documentación automática en `/docs` y valida parámetros de entrada.

**Archivo: `hello.py`**

```python
from fastapi import FastAPI

app = FastAPI()


@app.get("/hello")
def greet(name: str = "World"):
    return {"message": f"Hello, {name}!", "source": "FastAPI"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

**Archivo: `test_hello.py`**

```pythonfrom fastapi.testclient import TestClient
from hello import app

client = TestClient(app)


def test_greet_default():
    response = client.get("/hello")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello, World!", "source": "FastAPI"}


def test_greet_with_name():
    response = client.get("/hello?name=UTEC")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello, UTEC!", "source": "FastAPI"}


def test_greet_unknown_param_ignored():
    response = client.get("/hello?name=Alice&foo=bar")
    assert response.status_code == 200
    assert response.json()["message"] == "Hello, Alice!"
```

Correr localmente:
```bash
pip install -r requirements-dev.txt
python hello.py
# GET http://localhost:8000/hello?name=UTEC
# GET http://localhost:8000/docs  ← Swagger UI automático
```

### 2.2 Handler Lambda con Mangum

Lambda no habla ASGI directamente. **Mangum** es el puente: recibe el evento de API Gateway, lo convierte a una petición ASGI, se lo pasa a FastAPI, y devuelve la respuesta en el formato que Lambda espera.

**Archivo: `handler.py`**

```python
from mangum import Mangum
from hello import app

# Mangum adapta el evento Lambda/API Gateway al protocolo ASGI de FastAPI
handler = Mangum(app)
```

```
API Gateway → evento Lambda → Mangum → FastAPI → respuesta → Lambda → API Gateway
```

> `handler.handler` es lo que referencia `serverless.yml`. `handler` (módulo) `.handler` (objeto Mangum) — el objeto Mangum es callable y actúa como la función Lambda.

---

## Parte 3: Configuración de Serverless Framework v4

### 3.1 `serverless.yml`

Serverless Framework lee este archivo para saber qué infraestructura crear en AWS (Lambda, API Gateway, IAM roles, CloudFormation stack).

**Archivo: `serverless.yml`**

```yaml
service: gitlab-lambda-demo
frameworkVersion: '4'

provider:
  name: aws
  runtime: python3.11
  region: ${env:AWS_DEFAULT_REGION, "us-east-1"}
  stage: ${opt:stage, "dev"}
  environment:
    STAGE: ${sls:stage}

plugins:
  - serverless-offline   # solo para desarrollo local; no afecta el deploy

custom:
  pythonRequirements:
    dockerizePip: false   # instala dependencias nativas directamente en el runner
    slim: false           # true elimina .dist-info y rompe paquetes que leen su propia metadata (ej. email-validator de FastAPI)
    pythonBin: python3    # usa "python3" en lugar de "python3.11" (Debian/Alpine no registran el binario versionado)

functions:
  hello:
    handler: handler.handler   # módulo handler.py → objeto Mangum llamado handler
    description: "API FastAPI desplegada desde GitLab CI"
    events:
      - httpApi:           # API Gateway v2 (HTTP API) — más barato que REST API
          path: /hello
          method: GET
```

**Campos clave de `serverless.yml` v3:**

| Campo | Descripción |
|-------|-------------|
| `service` | Nombre del stack en CloudFormation |
| `frameworkVersion: '4'` | Fija la versión mayor para evitar breaking changes |
| `provider.stage` | Entorno (`dev`, `staging`, `production`) — se pasa con `--stage` |
| `provider.region` | Región AWS — se lee de variable de entorno |
| `${opt:stage, "dev"}` | Valor del flag `--stage`, con `"dev"` como fallback |
| `${env:VAR, "default"}` | Lee variable de entorno con fallback |
| `httpApi` | Crea un endpoint en API Gateway v2 |
| `custom.pythonRequirements` | Activa el empaquetado de `requirements.txt` integrado en v4 |

### 3.2 `package.json`

**Archivo: `package.json`**

```json
{
  "name": "gitlab-lambda-demo",
  "version": "1.0.0",
  "devDependencies": {
    "serverless": "^4.0.0",
    "serverless-offline": "^14.7.0"
  }
}
```

> En Serverless Framework v4, el soporte para `requirements.txt` está integrado — ya no se necesita el plugin `serverless-python-requirements`. El empaquetado se activa automáticamente cuando existe el bloque `custom.pythonRequirements` en `serverless.yml`. Incluye soporte nativo para `uv` como instalador rápido.

### 3.3 Validación local con `serverless offline`

`serverless-offline` levanta un servidor HTTP local que simula API Gateway + Lambda, pasando los eventos por Mangum igual que en producción.

**Preparar el entorno:**
```bash
conda create -n gitlab-lambda-demo python=3.11
conda activate gitlab-lambda-demo
pip install -r requirements-dev.txt
npm install
```

**Correr:**
```bash
npx serverless offline
# GET | http://localhost:3000/hello
```

```bash
curl "http://localhost:3000/hello?name=UTEC"
# {"message": "Hello, UTEC!", "source": "FastAPI"}
```

> El entorno conda debe estar activado antes de correr `serverless offline`. El runner de Python de `serverless-offline` usa el `python3` del PATH — con el entorno activo apunta al Python del proyecto donde están instalados `fastapi` y `mangum`.

---

## Parte 4: Configuración de credenciales

Necesitas tres tipos de credenciales: una para Serverless Framework, dos para AWS.

### 4.1 Obtener `SERVERLESS_ACCESS_KEY`

Serverless Framework v4 requiere autenticación con una cuenta Serverless. En CI/CD se usa una Access Key en lugar del login interactivo.

1. Ve a [app.serverless.com](https://app.serverless.com/) y crea una cuenta (plan gratuito disponible)
2. Clic en tu perfil (esquina superior derecha) → **Settings**
3. Sección **Access Keys → Create**
4. Nómbrala `gitlab-ci` → clic en **Create**
5. Copia el token generado — **solo se muestra una vez**

> Sin esta key, Serverless v4 intenta un login interactivo en el pipeline y el job falla.

### 4.2 Obtener `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`

Las credenciales AWS se generan creando un usuario IAM dedicado para el pipeline.

**Crear el usuario IAM:**

1. Ve a AWS Console → **IAM → Users → Create user**
2. Nómbralo `gitlab-ci-deployer` → clic en **Next**
3. Selecciona **Attach policies directly** y agrega:
   - `AWSLambda_FullAccess`
   - `AmazonAPIGatewayAdministrator`
   - `AWSCloudFormationFullAccess`
   - `IAMFullAccess`
   - `AmazonS3FullAccess`
4. Clic en **Create user**

**Generar las credenciales:**

1. Abre el usuario `gitlab-ci-deployer` → pestaña **Security credentials**
2. Sección **Access keys → Create access key**
3. Selecciona **Command Line Interface (CLI)** como caso de uso
4. Clic en **Create access key**
5. Copia `Access key ID` y `Secret access key` — **solo se muestran una vez**

> En producción, reemplaza estas políticas administradas por una política IAM con permisos mínimos.

### 4.3 Agregar las variables en GitLab CI/CD

GitLab inyecta estas variables como variables de entorno en cada job del pipeline. El AWS SDK y Serverless Framework las leen automáticamente sin configuración adicional en el YAML.

1. Ve a tu proyecto en GitLab → **Settings → CI/CD**
2. Expande la sección **Variables → Add variable**
3. Agrega cada variable con la siguiente configuración:

| Variable                | Valor                              | Protected | Masked |
|-------------------------|------------------------------------|-----------|--------|
| `SERVERLESS_ACCESS_KEY` | token de app.serverless.com        | Sí        | Sí     |
| `AWS_ACCESS_KEY_ID`     | Access key del usuario IAM         | Sí        | Sí     |
| `AWS_SECRET_ACCESS_KEY` | Secret access key del usuario IAM  | Sí        | Sí     |
| `AWS_DEFAULT_REGION`    | ej. `us-east-1`                    | Sí        | No     |

**Para cada variable:**
- Pega el valor en el campo **Value**
- Activa **Mask variable** → oculta el valor en los logs del pipeline
- Activa **Protect variable** → solo disponible en ramas y tags protegidos
- Clic en **Add variable**

**¿Cómo llegan al pipeline?**

```
GitLab Variables → entorno del runner → AWS SDK credential chain
                                        └─ lee AWS_ACCESS_KEY_ID
                                        └─ lee AWS_SECRET_ACCESS_KEY
                                        └─ lee AWS_DEFAULT_REGION

                                       Serverless Framework
                                        └─ lee SERVERLESS_ACCESS_KEY
```

No necesitas declarar las variables explícitamente en `.gitlab-ci.yml` — GitLab las inyecta automáticamente en el entorno de cada job.

---

## Parte 5: Pipeline completo `.gitlab-ci.yml`

El pipeline tiene 2 stages. Dentro de `validate` dos jobs corren en paralelo. El deploy a AWS requiere aprobación manual.

```
validate (lint + test en paralelo) → deploy (deploy_aws - manual)
```

**Archivo: `.gitlab-ci.yml`**

```yaml
stages:
  - validate
  - deploy

# ── Variables globales ────────────────────────────────────────────
variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

# ── Cache de pip ──────────────────────────────────────────────────
.pip_cache: &pip_cache
  cache:
    key: "$CI_COMMIT_REF_SLUG-pip"
    paths:
      - .cache/pip
    policy: pull-push

# ── Cache de npm ──────────────────────────────────────────────────
.npm_cache: &npm_cache
  cache:
    key: "$CI_COMMIT_REF_SLUG-npm"
    paths:
      - node_modules/
    policy: pull-push

# ══════════════════════════════════════════════════════════════════
# STAGE: validate
# ══════════════════════════════════════════════════════════════════

lint:
  stage: validate
  image: python:3.11-slim
  <<: *pip_cache
  script:
    - pip install flake8
    - flake8 handler.py hello.py --max-line-length=100 --statistics
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

test:
  stage: validate
  image: python:3.11-slim
  <<: *pip_cache
  script:
    - pip install -r requirements-dev.txt
    - PYTHONPATH="$CI_PROJECT_DIR" pytest tests/ -v
        --junitxml=report.xml
        --cov=.
        --cov-report=xml:coverage.xml
        --cov-report=term-missing
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    when: always
    reports:
      junit: report.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    paths:
      - coverage.xml
      - report.xml
    expire_in: 7 days
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

# ══════════════════════════════════════════════════════════════════
# STAGE: deploy
# ══════════════════════════════════════════════════════════════════

deploy_aws:
  stage: deploy
  image: node:20         # Debian/glibc — compatible con Amazon Linux (Lambda)
  <<: *npm_cache
  before_script:
    # node:20 (Debian/glibc) es compatible con Lambda (Amazon Linux/glibc)
    # Alpine (musl) genera binarios incompatibles con Lambda — no usar node:20-alpine
    - apt-get update -qq && apt-get install -y -qq python3 python3-pip
    - npm ci
  script:
    - npx serverless deploy --stage production --verbose
  environment:
    name: aws-lambda
  needs:
    - job: lint
    - job: test
  when: manual
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
```

---

## Parte 6: Conceptos clave del pipeline

### 6.1 `rules:` vs `only:`

`only:` es sintaxis antigua. `rules:` es más expresivo y soporta condiciones complejas:

```yaml
rules:
  - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
  - if: '$CI_COMMIT_BRANCH == "main"'
```

Variables predefinidas útiles de GitLab CI:

| Variable                   | Descripción                              |
|----------------------------|------------------------------------------|
| `$CI_COMMIT_REF_SLUG`      | Nombre de rama normalizado (sin `/`, minúsculas) |
| `$CI_COMMIT_SHORT_SHA`     | Hash corto del commit (ej. `abc1234`)    |
| `$CI_PIPELINE_SOURCE`      | Origen: `push`, `merge_request_event`, `schedule` |
| `$CI_COMMIT_BRANCH`        | Nombre de rama actual                    |
| `$CI_PROJECT_DIR`          | Ruta raíz del proyecto en el runner      |

### 6.2 Cache de pip y npm

```yaml
variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

cache:
  key: "$CI_COMMIT_REF_SLUG-pip"
  paths:
    - .cache/pip
  policy: pull-push
```

- `key`: identifica el cache. Mismo branch = mismo cache reutilizado.
- `policy: pull-push`: descarga el cache al inicio y lo sube al final.
- `policy: pull`: solo descarga (útil en jobs de solo lectura).

El job `deploy_aws` usa un cache separado para `node_modules/` con la clave `$CI_COMMIT_REF_SLUG-npm`, evitando reinstalar `serverless` y sus plugins en cada ejecución.

### 6.3 Artifacts y reportes de test

El job `test` genera artifacts que GitLab integra en la UI:

```yaml
artifacts:
  reports:
    junit: report.xml           # GitLab muestra resultados por test en el MR
    coverage_report:
      coverage_format: cobertura
      path: coverage.xml        # GitLab muestra qué líneas nuevas tienen cobertura
```

Con `coverage: '/TOTAL.*\s+(\d+%)$/'`, GitLab parsea el porcentaje del stdout de pytest y lo muestra como badge en el pipeline.

### 6.4 `needs:` vs dependencia por stage

`deploy_aws` usa `needs:` para declarar dependencias explícitas en lugar de depender implícitamente del stage anterior:

```yaml
deploy_aws:
  needs:
    - job: lint
    - job: test
```

Esto garantiza que el deploy solo corre si ambos jobs pasaron, y además permite que GitLab inicie `deploy_aws` tan pronto como `lint` y `test` terminen, sin esperar otros jobs del mismo stage.

### 6.5 Jobs en paralelo

`lint` y `test` están en el mismo stage y no tienen `needs:` entre sí, por lo tanto corren en paralelo si hay runners disponibles:

```
validate:
  ┌──────────┐  ┌──────────┐
  │   lint   │  │   test   │   ← corren al mismo tiempo
  └──────────┘  └──────────┘
```

### 6.6 `when: manual`

```yaml
deploy_aws:
  when: manual
```

El job aparece en la UI de GitLab pero no corre automáticamente. Un humano debe hacer clic en ▶ para ejecutarlo. Útil para:
- Aprobar deploys a producción
- Acciones destructivas (migraciones, rollbacks)
- Releases que requieren revisión

### 6.7 Serverless Framework v4: flujo de despliegue

Cuando `npx serverless deploy` corre en el pipeline, ejecuta estos pasos internamente:

```
1. Lee serverless.yml
2. serverless-python-requirements → pip install → empaqueta deps en .serverless/
3. Genera template CloudFormation
4. Sube el ZIP del código a un bucket S3 (creado automáticamente)
5. Crea/actualiza el stack CloudFormation en AWS:
   ├── AWS::Lambda::Function       (la función)
   ├── AWS::ApiGatewayV2::Api      (el endpoint HTTP)
   └── AWS::IAM::Role              (permisos de ejecución de Lambda)
6. Imprime el endpoint URL generado
```

**Flags importantes:**

| Flag | Descripción |
|------|-------------|
| `--stage production` | Despliega al entorno `production` (afecta nombres de recursos) |
| `--verbose` | Muestra progreso del stack CloudFormation en tiempo real |
| `--function hello` | Re-despliega solo una función (sin recrear el stack completo) |

**Variables de entorno que Serverless v4 lee automáticamente:**

```
SERVERLESS_ACCESS_KEY   → autenticación con app.serverless.com (nuevo en v4)
AWS_ACCESS_KEY_ID       → credencial IAM
AWS_SECRET_ACCESS_KEY   → credencial IAM
AWS_DEFAULT_REGION      → región de despliegue
```

GitLab CI inyecta estas variables desde Settings → CI/CD → Variables al entorno del job. Serverless las consume sin configuración adicional. Sin `SERVERLESS_ACCESS_KEY`, v4 intenta un login interactivo y el job falla en CI.

---

## Parte 7: Probar el pipeline

### 7.1 Push inicial

```bash
git add .gitlab-ci.yml handler.py hello.py serverless.yml \
        package.json requirements.txt requirements-dev.txt tests/
git commit -m "feat: pipeline GitLab CI con despliegue a AWS Lambda via Serverless"
git push origin main
```

### 7.2 Observar la ejecución

1. Ve a **CI/CD → Pipelines** en GitLab.
2. Observa el grafo — `lint` y `test` corren en paralelo.
3. El job `deploy_aws` aparece en estado "manual" — haz clic en ▶ para ejecutarlo.
4. En los logs verás el stack CloudFormation creándose y al final el endpoint:

```
endpoints:
  GET - https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/hello
```

5. Prueba el endpoint:

```bash
curl "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/hello?name=UTEC"
# {"message": "Hello, UTEC!", "source": "FastAPI"}
```

### 7.3 Probar localmente antes del pipeline

**Opción A — uvicorn (solo FastAPI, sin Lambda):**
```bash
conda activate gitlab-lambda-demo
pip install -r requirements-dev.txt
python hello.py
curl "http://localhost:8000/hello?name=local"
# También: http://localhost:8000/docs  (Swagger UI)
```

**Opción B — serverless offline (FastAPI + Mangum + API Gateway simulado):**
```bash
conda activate gitlab-lambda-demo
npm install
npx serverless offline
curl "http://localhost:3000/hello?name=local"
```

**Opción C — invocación one-shot:**
```bash
conda activate gitlab-lambda-demo
npx serverless invoke local --function hello \
  --data '{"queryStringParameters": {"name": "local"}, "requestContext": {"http": {"method": "GET", "path": "/hello"}}}'
```

### 7.4 Crear un Merge Request para ver artifacts en acción

```bash
git checkout -b feature/nueva-funcionalidad
# modifica handler.py o hello.py
git add .
git commit -m "feat: nueva funcionalidad"
git push origin feature/nueva-funcionalidad
```

Crea un MR en GitLab. En el MR verás:
- **Test summary**: resultados de pytest (pasó/falló cada test)
- **Coverage diff**: líneas nuevas con/sin cobertura

---

## Parte 8: Buenas prácticas y troubleshooting

| Problema | Causa probable | Solución |
|----------|---------------|----------|
| Cache no se aplica | `key:` diferente entre runs | Usa variables estables como `$CI_COMMIT_REF_SLUG` |
| `deploy_aws` falla con `AccessDenied` | Permisos IAM insuficientes | Verifica las políticas del usuario `gitlab-ci-deployer` |
| `deploy_aws` falla con `Invalid credentials` | Variables AWS no configuradas | Agrega `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION` en Settings → CI/CD → Variables |
| `deploy_aws` falla con `You must be logged in` | Falta `SERVERLESS_ACCESS_KEY` | Crea una Access Key en app.serverless.com y agrégala como variable Protected + Masked |
| `serverless offline` → `No module named 'mangum'` | Entorno conda no activado | Corre `conda activate gitlab-lambda-demo` antes de `serverless offline` |
| `python3` no encontrado en `deploy_aws` | Imagen sin Python | Verifica que `apt-get install python3 python3-pip` esté en `before_script` |
| `spawn python3.11 ENOENT` | Imagen no tiene binario `python3.11` | Agrega `pythonBin: python3` en `custom.pythonRequirements` del `serverless.yml` |
| `No module named 'pydantic_core._pydantic_core'` | Deps compiladas en Alpine (musl) son incompatibles con Lambda (glibc) | Usar `image: node:20` (Debian) en lugar de `node:20-alpine` en el job `deploy_aws` |
| `No package metadata was found for email-validator` | `slim: true` elimina `.dist-info` que algunos paquetes necesitan en runtime | Cambiar a `slim: false` en `custom.pythonRequirements` |
| Stack CloudFormation queda en `ROLLBACK` | Error al crear recursos AWS | Ve a AWS Console → CloudFormation → ver eventos del stack para el error |
| `npm ci` falla | No existe `package-lock.json` | Corre `npm install` localmente y commitea `package-lock.json` |
| Tests fallan con `ImportError: httpx` | Falta `httpx` en `requirements-dev.txt` | Agrega `httpx==0.27.0` a `requirements-dev.txt` |
| Mangum devuelve 500 en Lambda | Handler mal referenciado en `serverless.yml` | Verifica que sea `handler: handler.handler` (módulo.objeto) |
| Job manual no aparece | `rules:` bloquea el pipeline | Verifica que la rama sea `main` |

**Reglas de seguridad:**
- Marca `SERVERLESS_ACCESS_KEY`, `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` como **Protected** y **Masked**
- Usa un usuario IAM dedicado para CI/CD, nunca las credenciales root de AWS
- Usa `policy: pull` en jobs de solo lectura para no corromper el cache compartido
- Usa `when: manual` para deploys a producción
- Al finalizar el laboratorio, elimina los recursos de AWS: `npx serverless remove --stage production`

---

## Checklist de Éxito

- [ ] `lint` y `test` corren en paralelo en el stage `validate`
- [ ] Pipeline usa cache de pip y npm, más rápido en la segunda ejecución
- [ ] Artifacts de test (`report.xml`, `coverage.xml`) visibles en el MR
- [ ] `deploy_aws` requiere aprobación manual antes de ejecutar
- [ ] `deploy_aws` despliega correctamente a AWS Lambda via Serverless Framework v4
- [ ] Endpoint Lambda responde: `{"message": "Hello, World!", "source": "FastAPI"}`
- [ ] Swagger UI accesible en `/docs` localmente
- [ ] Recursos visibles en AWS CloudFormation Console y Lambda Console
- [ ] Credenciales AWS nunca se exponen en logs

---

## Entregables

1. **Repositorio GitLab** con:
   - `.gitlab-ci.yml` con los 2 stages (`validate`, `deploy`)
   - `handler.py` funcional como Lambda handler
   - `serverless.yml` con configuración de Serverless Framework v4
   - `package.json` con dependencias de Serverless
   - `requirements.txt` y `requirements-dev.txt` separados
2. **Capturas de pantalla:**
   - Pipeline completo con grafo de ejecución (lint+test en paralelo)
   - Test summary en un Merge Request
   - Logs del job `deploy_aws` mostrando el endpoint generado
   - Respuesta del endpoint Lambda desde `curl` o el navegador
   - Stack en AWS CloudFormation Console mostrando los recursos creados
3. **Reflexión:**
   - ¿Cuánto tiempo ahorró el cache de pip/npm en la segunda ejecución?
   - ¿Qué recursos creó Serverless Framework en AWS? ¿Para qué sirve cada uno?
   - ¿Qué diferencias notaste respecto a GitHub Actions en los Laboratorios 9.x?

---

📘 **Autor:**  
Wilson Julca Mejía  
Curso: *DevOps y GitLab CI/CD – Python y AWS Lambda*  
Universidad de Ingeniería y Tecnología (UTEC)
