# Laboratorio 11: Bitbucket Pipelines - CI/CD con Python

**Duración estimada:** 90–120 min  
**Nivel:** Intermedio  
**Contexto:** En este laboratorio aprenderás a implementar CI/CD con Bitbucket Pipelines, desde conceptos básicos hasta pipelines con stages, steps paralelos, artefactos y buenas prácticas.

---

## Objetivos de aprendizaje

- Entender la arquitectura y componentes de Bitbucket Pipelines (Pipelines, Steps, Stages, Artifacts, Variables)
- Crear pipelines de CI/CD para aplicaciones Python
- Implementar steps paralelos y secuenciales usando stages
- Gestionar artefactos entre steps
- Configurar cache para optimizar tiempos de ejecución
- Aplicar buenas prácticas de seguridad y organización

---

## Requisitos

- Cuenta en Bitbucket ([https://bitbucket.org/](https://bitbucket.org/))
- Workspace y repositorio en Bitbucket
- Conocimientos básicos de Git y control de versiones
- Familiaridad con Python y pytest
- Editor de texto o IDE configurado

---

## Estructura del proyecto

```
bitbucket_pipelines_demo/
├── bitbucket-pipelines.yml    # Pipeline principal de CI/CD
├── hello.py                   # Aplicación Python simple
├── tests/
│   └── test_hello.py         # Tests unitarios
├── requirements.txt           # Dependencias Python
└── README.md                  # Documentación del proyecto
```

---

## Parte 1: Conceptos Fundamentales de Bitbucket Pipelines

### 1.1 ¿Qué es Bitbucket Pipelines?

**Bitbucket Pipelines** es el servicio de CI/CD integrado en Bitbucket Cloud que permite automatizar la construcción, prueba y despliegue de código. Forma parte del ecosistema Atlassian (junto con Jira y Confluence).

**Ventajas principales:**
- ✅ **Integración nativa**: Directamente en Bitbucket, sin configuración externa
- ✅ **Docker-first**: Cada step corre en un contenedor Docker aislado
- ✅ **Gratuito**: 50 minutos/mes en el plan gratuito, más en planes pagos
- ✅ **Ecosistema Atlassian**: Integración nativa con Jira, Confluence y Trello
- ✅ **Soporte YAML**: Pipelines como código en `bitbucket-pipelines.yml`

### 1.2 Componentes de Bitbucket Pipelines

#### **Pipeline (Flujo de trabajo)**
El proceso completo de CI/CD definido en `bitbucket-pipelines.yml`. Se dispara por push, PR, etiquetas o manualmente.

```yaml
# Estructura general
image: python:3.11

pipelines:
  default:
    - step:
        name: Mi primer step
        script:
          - echo "Hola desde Bitbucket Pipelines"
```

#### **Step (Paso)**
La unidad principal de trabajo. Cada step corre en su propio contenedor Docker limpio. Los steps se ejecutan **secuencialmente** por defecto.

```yaml
- step:
    name: Test
    image: python:3.11      # imagen Docker para este step
    caches:
      - pip
    script:
      - pip install -r requirements.txt
      - pytest tests/
    artifacts:
      - test-results.xml
```

#### **Stage (Etapa)**
Agrupa steps lógicamente. Dentro de un stage, los steps marcados como `parallel` corren al mismo tiempo.

```yaml
- stage:
    name: Verificación
    steps:
      - step:
          name: Tests
          script: [...]
      - step:
          name: Lint
          script: [...]
```

#### **Parallel (Paralelo)**
Ejecuta múltiples steps al mismo tiempo dentro de un stage.

```yaml
- parallel:
    - step:
        name: Test unitarios
        script: [pytest tests/]
    - step:
        name: Lint
        script: [flake8 hello.py]
```

#### **Artifact (Artefacto)**
Archivos generados en un step y disponibles para steps posteriores. Sin artifacts, cada step parte de cero.

```yaml
artifacts:
  - test-results.xml
  - htmlcov/**
  - dist/**
```

#### **Cache (Caché)**
Almacena directorios entre ejecuciones del pipeline para evitar re-descargar dependencias.

```yaml
caches:
  - pip        # caché predefinido para pip
  - node       # caché predefinido para npm
```

#### **Runner (Agente)**
La máquina que ejecuta los steps. Opciones:
- **Atlassian Cloud Runners**: Gestionados por Atlassian (por defecto)
- **Self-hosted Runners**: Servidores propios registrados en Bitbucket

---

## Parte 2: Crear tu primer Pipeline

### 2.1 Crear repositorio en Bitbucket

1. Ve a [https://bitbucket.org/](https://bitbucket.org/)
2. Haz clic en **Create repository**
3. Selecciona tu workspace
4. Nombra el repositorio: **bitbucket-pipelines-demo**
5. Elige visibilidad: **Private** o **Public**
6. Haz clic en **Create repository**

### 2.2 Habilitar Pipelines en el repositorio

1. En tu repositorio, ve a **Repository settings**
2. En el menú lateral, selecciona **Pipelines → Settings**
3. Activa el toggle **Enable Pipelines**

### 2.3 Crear archivos del proyecto

#### **Archivo: `hello.py`**

```python
"""
Aplicación Python simple para demostración de CI/CD
"""

def greet(name: str = "World") -> str:
    """Retorna un saludo personalizado"""
    return f"Hello, {name}!"

def add(a: int, b: int) -> int:
    """Suma dos números"""
    return a + b

def main():
    """Función principal"""
    print(greet())
    print(f"2 + 3 = {add(2, 3)}")

if __name__ == "__main__":
    main()
```

#### **Archivo: `tests/test_hello.py`**

```python
"""
Tests unitarios para hello.py
"""
import pytest
from hello import greet, add

def test_greet_default():
    assert greet() == "Hello, World!"

def test_greet_custom():
    assert greet("DevOps") == "Hello, DevOps!"

def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0
    assert add(0, 0) == 0
```

#### **Archivo: `requirements.txt`**

```txt
pytest==7.4.3
pytest-cov==4.1.0
```

---

## Parte 3: Pipeline Básico

### 3.1 Crear el archivo `bitbucket-pipelines.yml`

```yaml
# Bitbucket Pipelines CI/CD para Python
# Documentación: https://support.atlassian.com/bitbucket-cloud/docs/bitbucket-pipelines-configuration-reference/

image: python:3.11

definitions:
  caches:
    pip-cache: ~/.cache/pip

pipelines:
  default:
    - stage:
        name: Test
        steps:
          - step:
              name: Run Tests
              caches:
                - pip-cache
              script:
                # Mostrar versiones
                - python --version
                - pip --version
                # Instalar dependencias
                - pip install --upgrade pip
                - pip install -r requirements.txt
                # Correr tests con cobertura
                - export PYTHONPATH="${PYTHONPATH}:$(pwd)"
                - pytest tests/ -v --junitxml=test-results.xml --cov=. --cov-report=xml --cov-report=html
                # Generar build tag
                - echo "build_tag=${BITBUCKET_BUILD_NUMBER}-${BITBUCKET_COMMIT:0:7}" >> build.env
              artifacts:
                - test-results.xml
                - coverage.xml
                - htmlcov/**
                - build.env

    - stage:
        name: Package
        steps:
          - step:
              name: Create Package
              script:
                - source build.env
                - mkdir -p dist
                - cp hello.py dist/
                - cp requirements.txt dist/
                - apt-get update -qq && apt-get install -y zip -qq
                - cd dist && zip -r "../app-${build_tag}.zip" .
                - echo "Paquete creado: app-${build_tag}.zip"
              artifacts:
                - "app-*.zip"

  branches:
    main:
      - stage:
          name: Test
          steps:
            - step:
                name: Run Tests (main)
                caches:
                  - pip-cache
                script:
                  - pip install --upgrade pip
                  - pip install -r requirements.txt
                  - export PYTHONPATH="${PYTHONPATH}:$(pwd)"
                  - pytest tests/ -v --junitxml=test-results.xml --cov=. --cov-report=xml
                artifacts:
                  - test-results.xml
                  - coverage.xml
                  - build.env

      - parallel:
          - step:
              name: Create Package
              script:
                - pip install --upgrade pip
                - pip install -r requirements.txt
                - mkdir -p dist
                - cp hello.py dist/
                - cp requirements.txt dist/
                - apt-get update -qq && apt-get install -y zip -qq
                - cd dist && zip -r "../app-${BITBUCKET_BUILD_NUMBER}.zip" .
              artifacts:
                - "app-*.zip"
          - step:
              name: Generate Docs
              script:
                - 'echo "Repository: $BITBUCKET_REPO_SLUG"'
                - 'echo "Branch: $BITBUCKET_BRANCH"'
                - 'echo "Commit: $BITBUCKET_COMMIT"'
                - 'echo "Build Number: $BITBUCKET_BUILD_NUMBER"'
                - 'echo "Workspace: $BITBUCKET_WORKSPACE"'

  pull-requests:
    "**":
      - step:
          name: Test PR
          caches:
            - pip-cache
          script:
            - pip install --upgrade pip
            - pip install -r requirements.txt
            - export PYTHONPATH="${PYTHONPATH}:$(pwd)"
            - pytest tests/ -v --junitxml=test-results.xml
          artifacts:
            - test-results.xml

  custom:
    deploy-manual:
      - step:
          name: Deploy Manual
          deployment: production
          script:
            - echo "Desplegando manualmente al entorno de producción"
            - echo "Build: $BITBUCKET_BUILD_NUMBER"
            - echo "Commit: $BITBUCKET_COMMIT"
```

### 3.2 Explicación Detallada del Pipeline

#### **Image (Imagen Docker)**
```yaml
image: python:3.11
```
- Imagen Docker base usada por todos los steps que no especifiquen su propia imagen
- Cada step arranca un contenedor **limpio y efímero** basado en esta imagen

#### **Definitions (Definiciones)**
```yaml
definitions:
  caches:
    pip-cache: ~/.cache/pip
```
- Define caches reutilizables por nombre en todo el pipeline
- `pip-cache` apunta al directorio de caché de pip en el contenedor

#### **Pipelines (Tipos de trigger)**
```yaml
pipelines:
  default:    # Corre en todas las ramas sin regla específica
  branches:   # Reglas por nombre de rama
    main: [...]
    develop: [...]
  pull-requests:  # Corre en PRs hacia las ramas especificadas
    "**": [...]   # "**" = cualquier PR
  tags:       # Trigger por tags de git
    "v*": [...] 
  custom:     # Pipelines manuales (no se disparan automáticamente)
    mi-pipeline: [...]
```

#### **Stage y Steps**
```yaml
- stage:
    name: Test
    steps:
      - step:
          name: Run Tests
          script: [...]
```
- `stage` agrupa steps lógicamente
- Los steps dentro de un stage corren **secuencialmente** por defecto
- Usa `parallel` para correr steps al mismo tiempo

#### **Artifacts**
```yaml
artifacts:
  - test-results.xml
  - htmlcov/**
  - "app-*.zip"
```
- Archivos que **persisten** entre steps del mismo pipeline
- Sin artifacts, el siguiente step no ve los archivos del anterior
- Soporta globs (`**`, `*`)

#### **Caches**
```yaml
caches:
  - pip-cache
```
- Persisten entre **diferentes ejecuciones** del pipeline (no solo entre steps)
- Bitbucket guarda el directorio configurado y lo restaura en el próximo build
- Claves de caché predefinidas: `pip`, `node`, `maven`, `gradle`, `composer`

#### **Deployment (Entornos)**
```yaml
- step:
    name: Deploy
    deployment: production
```
- Marca el step como un despliegue a un entorno específico
- Visible en **Deployments** en la UI de Bitbucket
- Permite ver historial de despliegues por entorno

---

## Parte 4: Crear el Pipeline en Bitbucket

### 4.1 Método 1: Desde la UI de Bitbucket

1. En tu repositorio, ve a **Pipelines**
2. Haz clic en **Create your first pipeline**
3. Selecciona una plantilla (o **Starter pipeline**)
4. Reemplaza el contenido con tu YAML
5. Haz clic en **Commit file**
6. El pipeline se ejecuta automáticamente

### 4.2 Método 2: Subir el archivo directamente

1. Crea `bitbucket-pipelines.yml` en la raíz de tu repositorio local
2. Haz commit y push:
   ```bash
   git add bitbucket-pipelines.yml
   git commit -m "ci: add Bitbucket Pipelines configuration"
   git push
   ```
3. Ve a **Pipelines** en Bitbucket — el pipeline inicia automáticamente

### 4.3 Ejecutar pipeline manual (custom)

1. Ve a **Pipelines** en tu repositorio
2. Haz clic en **Run pipeline**
3. Selecciona la rama y el pipeline `custom: deploy-manual`
4. Haz clic en **Run**

---

## Parte 5: Diagrama de Arquitectura

```mermaid
graph TB
    subgraph "Bitbucket Repository"
        Repo["📁 Bitbucket Repo<br/>hello.py, tests/"]
        Config["⚙️ bitbucket-pipelines.yml"]
    end

    subgraph "Triggers"
        Push["🚀 git push<br/>(default / branches)"]
        PR["🔀 Pull Request<br/>(pull-requests)"]
        Manual["🖱️ Manual<br/>(custom)"]
    end

    subgraph "Bitbucket Pipelines"
        subgraph "Stage: Test"
            Step1["🧪 Step: Run Tests<br/>- pip install<br/>- pytest + coverage<br/>- genera build.env"]
        end
        subgraph "Parallel: Package + Docs"
            Step2["📦 Step: Create Package<br/>- crea app-N.zip"]
            Step3["📚 Step: Generate Docs<br/>- imprime variables CI"]
        end
    end

    subgraph "Artifacts & Cache"
        Art1["📊 test-results.xml"]
        Art2["📈 coverage.xml / htmlcov/"]
        Art3["🗜️ app-*.zip"]
        Cache1["⚡ pip-cache<br/>(~/.cache/pip)"]
    end

    Repo --> Push
    Config --> Push
    Repo --> PR
    Config --> Manual

    Push --> Step1
    PR --> Step1
    Manual --> Step2

    Step1 -->|artifacts| Step2
    Step1 -->|artifacts| Step3

    Step1 --> Art1
    Step1 --> Art2
    Step2 --> Art3
    Step1 <-->|cache restore/save| Cache1

    style Step1 fill:#e8f5e9,stroke:#66bb6a
    style Step2 fill:#fff3e0,stroke:#ffa726
    style Step3 fill:#f3e5f5,stroke:#ab47bc
    style Cache1 fill:#e3f2fd,stroke:#42a5f5
```

---

## Parte 6: Variables Predefinidas de Bitbucket Pipelines

### 6.1 Variables Comunes

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `$BITBUCKET_BUILD_NUMBER` | Número incremental del build | `42` |
| `$BITBUCKET_COMMIT` | SHA completo del commit | `abc123def456...` |
| `$BITBUCKET_BRANCH` | Nombre de la rama | `main` |
| `$BITBUCKET_TAG` | Tag de git (si aplica) | `v1.0.0` |
| `$BITBUCKET_REPO_SLUG` | Slug del repositorio | `bitbucket-pipelines-demo` |
| `$BITBUCKET_REPO_OWNER` | Usuario/equipo dueño del repo | `mi-workspace` |
| `$BITBUCKET_WORKSPACE` | Slug del workspace | `mi-workspace` |
| `$BITBUCKET_PIPELINE_UUID` | UUID único del pipeline | `{abc-123-...}` |
| `$BITBUCKET_PR_ID` | ID del Pull Request (solo en PR pipelines) | `15` |
| `$BITBUCKET_PR_DESTINATION_BRANCH` | Rama destino del PR | `main` |
| `$BITBUCKET_CLONE_DIR` | Directorio donde se clona el repo | `/opt/atlassian/pipelines/agent/build` |

### 6.2 Uso de Variables

```yaml
- step:
    name: Display Info
    script:
      - echo "Build #$BITBUCKET_BUILD_NUMBER"
      - echo "Commit: ${BITBUCKET_COMMIT:0:7}"
      - echo "Rama: $BITBUCKET_BRANCH"
      - echo "Repo: $BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG"
```

### 6.3 Variables de Repositorio (Secrets)

1. Ve a **Repository settings → Pipelines → Repository variables**
2. Agrega variables como `API_KEY`, `DATABASE_URL`, etc.
3. Márcalas como **Secured** para que no aparezcan en los logs
4. Úsalas en el pipeline:

```yaml
- step:
    name: Deploy
    script:
      - echo "Usando API key configurada en el repo"
      - curl -H "Authorization: Bearer $API_KEY" https://api.example.com/deploy
```

---

## Parte 7: Pipeline Avanzado

### 7.1 Steps Paralelos

Ejecutar tests y lint al mismo tiempo:

```yaml
pipelines:
  default:
    - stage:
        name: Verificación
        steps:
          - parallel:
              - step:
                  name: Tests
                  caches:
                    - pip-cache
                  script:
                    - pip install -r requirements.txt
                    - pytest tests/ -v
              - step:
                  name: Lint
                  script:
                    - pip install flake8
                    - flake8 hello.py --max-line-length=100
```

### 7.2 Pipeline con Matrices (múltiples versiones de Python)

```yaml
pipelines:
  default:
    - parallel:
        - step:
            name: Test Python 3.9
            image: python:3.9
            script:
              - pip install -r requirements.txt
              - pytest tests/
        - step:
            name: Test Python 3.10
            image: python:3.10
            script:
              - pip install -r requirements.txt
              - pytest tests/
        - step:
            name: Test Python 3.11
            image: python:3.11
            script:
              - pip install -r requirements.txt
              - pytest tests/
```

### 7.3 Condiciones por Rama

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy a Producción
          deployment: production
          script:
            - echo "Deploy a prod solo desde main"
    develop:
      - step:
          name: Deploy a Staging
          deployment: staging
          script:
            - echo "Deploy a staging desde develop"
    "feature/*":
      - step:
          name: Test Feature
          script:
            - pip install -r requirements.txt
            - pytest tests/
```

### 7.4 Services (Contenedores de Servicios)

Levantar una base de datos durante los tests:

```yaml
definitions:
  services:
    postgres:
      image: postgres:15
      environment:
        POSTGRES_DB: testdb
        POSTGRES_USER: testuser
        POSTGRES_PASSWORD: testpass

pipelines:
  default:
    - step:
        name: Test con PostgreSQL
        services:
          - postgres
        script:
          - pip install -r requirements.txt
          - pip install psycopg2-binary
          - export DATABASE_URL=postgresql://testuser:testpass@localhost/testdb
          - pytest tests/ -v
```

### 7.5 After Script

Ejecutar comandos aunque el step falle (útil para limpiar o reportar):

```yaml
- step:
    name: Tests con cleanup
    script:
      - pytest tests/ --junitxml=test-results.xml
    after-script:
      - echo "Step terminó con código: $BITBUCKET_EXIT_CODE"
      - cat test-results.xml
    artifacts:
      - test-results.xml
```

---

## Parte 8: Comparación GitHub Actions vs GitLab CI/CD vs Bitbucket Pipelines

| Característica | GitHub Actions | GitLab CI/CD | Bitbucket Pipelines |
|----------------|----------------|--------------|---------------------|
| **Archivo config** | `.github/workflows/*.yml` | `.gitlab-ci.yml` | `bitbucket-pipelines.yml` |
| **Unidad de trabajo** | `job` | `job` | `step` |
| **Agrupación** | No nativo | `stages:` | `stage:` |
| **Paralelismo** | Jobs paralelos | Jobs en mismo stage | `parallel:` |
| **Runner/Agent** | `runs-on:` | `tags:`/runners | Atlassian Cloud / self-hosted |
| **Checkout** | `actions/checkout@v4` | `git clone` automático | `git clone` automático |
| **Cache** | `actions/cache@v4` | `cache:` | `caches:` |
| **Artifact** | `upload-artifact@v4` | `artifacts:` | `artifacts:` |
| **Variables CI** | `${{ github.sha }}` | `$CI_COMMIT_SHA` | `$BITBUCKET_COMMIT` |
| **Secrets** | Repository Secrets | CI/CD Variables | Repository Variables |
| **PR trigger** | `pull_request:` | `only: merge_requests` | `pull-requests:` |
| **Trigger manual** | `workflow_dispatch:` | `when: manual` | `custom:` |
| **Entornos** | `environment:` | `environment:` | `deployment:` |
| **Docker-first** | Opcional | Opcional | Siempre (cada step) |
| **Ecosistema** | GitHub / Microsoft | GitLab | Atlassian (Jira, Confluence) |

---

## Parte 9: Buenas Prácticas

### 9.1 Seguridad

#### **Variables Protegidas (Secured)**

```yaml
# Las variables SECURED no se imprimen en logs aunque uses echo
- step:
    name: Deploy
    script:
      - curl -H "Authorization: Bearer $API_KEY" $DEPLOY_URL
```

- Nunca hardcodees secrets en `bitbucket-pipelines.yml`
- Usa **Repository variables** para secrets del repo
- Usa **Deployment variables** para secrets específicos por entorno
- Usa **Workspace variables** para secrets compartidos entre repos

#### **Principio de menor privilegio**

Crea tokens de acceso con solo los permisos necesarios:
1. Ve a **Personal settings → App passwords**
2. Crea un password solo con los permisos requeridos (ej. solo `Pipelines: read`)

### 9.2 Performance

#### **Cache Estratégico**

```yaml
definitions:
  caches:
    pip-cache: ~/.cache/pip
    pytest-cache: .pytest_cache

pipelines:
  default:
    - step:
        caches:
          - pip-cache
          - pytest-cache
        script:
          - pip install --cache-dir ~/.cache/pip -r requirements.txt
          - pytest tests/
```

#### **Steps Paralelos para reducir tiempo total**

```yaml
- parallel:
    - step:
        name: Unit Tests
        script: [pytest tests/unit/]
    - step:
        name: Integration Tests
        script: [pytest tests/integration/]
    - step:
        name: Lint
        script: [flake8 hello.py]
```

#### **Size para steps pesados**

```yaml
- step:
    name: Build Docker Image
    size: 2x     # doble de RAM y CPU (consume 2x minutos)
    script:
      - docker build -t myapp .
```

### 9.3 Mantenibilidad

#### **YAML Anchors para reutilizar configuración**

```yaml
definitions:
  steps:
    - step: &install-deps
        name: Install Dependencies
        caches:
          - pip-cache
        script:
          - pip install --upgrade pip
          - pip install -r requirements.txt

pipelines:
  default:
    - step:
        <<: *install-deps
        name: Test
        script:
          - pip install --upgrade pip
          - pip install -r requirements.txt
          - pytest tests/
```

#### **Separar pipelines por entorno**

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy Production
          deployment: production
          trigger: manual    # requiere aprobación manual
          script:
            - echo "Deploying to production"
    develop:
      - step:
          name: Deploy Staging
          deployment: staging
          script:
            - echo "Auto-deploy to staging"
```

---

## Parte 10: Troubleshooting

### 10.1 Problemas Comunes

#### **Error: Pipelines no habilitado**
```
Repository pipelines are disabled
```
**Solución:**
- Ve a **Repository settings → Pipelines → Settings**
- Activa el toggle **Enable Pipelines**

#### **Error: Minutes quota exceeded**
```
Your account has run out of build minutes
```
**Solución:**
- Verifica tu cuota en **Workspace settings → Plan details**
- Actualiza tu plan o añade minutos adicionales
- Optimiza pipelines con cache y steps paralelos para reducir minutos usados

#### **Error: YAML syntax error**
```
Configuration file has syntax errors
```
**Solución:**
- Valida tu YAML con el [Bitbucket Pipelines Validator](https://bitbucket.org/account/settings/) o con [yamllint.com](https://www.yamllint.com/)
- Verifica indentación (2 espacios, no tabs)
- Asegura que los guiones `-` de lista estén bien alineados

#### **Error: Artifact not found**
```
No artifacts found matching the specified pattern
```
**Solución:**
- Verifica que el step anterior declaró el archivo en `artifacts:`
- Comprueba que el script del step anterior realmente generó el archivo
- Usa globs correctamente: `dist/**` no `dist/`

#### **Error: Step timeout**
```
Step exceeded the 2 hour time limit
```
**Solución:**
- Divide el step en steps más pequeños
- Optimiza el proceso (usa cache, paralelismo)
- El límite máximo por step es 2 horas en Bitbucket Cloud

### 10.2 Debugging

#### **Usar `set -x` para tracing**

```yaml
- step:
    name: Debug
    script:
      - set -x    # imprime cada comando antes de ejecutarlo
      - pip install -r requirements.txt
      - pytest tests/ -v
```

#### **Imprimir variables de entorno**

```yaml
- step:
    name: Debug Variables
    script:
      - echo "Build: $BITBUCKET_BUILD_NUMBER"
      - echo "Branch: $BITBUCKET_BRANCH"
      - echo "Commit: $BITBUCKET_COMMIT"
      - env | grep BITBUCKET   # todas las vars de Bitbucket
```

#### **Inspeccionar artifacts**

```yaml
- step:
    name: Inspect
    script:
      - ls -la                          # listar archivos del workspace
      - find . -name "*.xml" -type f    # buscar XMLs generados
      - cat test-results.xml            # ver contenido del artifact
```

---

## Checklist de Éxito

- [ ] Pipelines habilitado en el repositorio
- [ ] Pipeline se ejecuta en push a `main` y en Pull Requests
- [ ] Tests pasan y `test-results.xml` se genera como artifact
- [ ] Code coverage se genera en `coverage.xml` y `htmlcov/`
- [ ] Cache de pip acelera builds subsecuentes
- [ ] Artifacts pasan correctamente entre steps
- [ ] Stage de Package genera el `.zip` con el número de build
- [ ] Stage de Docs imprime variables del pipeline
- [ ] Variables de repositorio configuradas correctamente (sin secrets en el YAML)
- [ ] Logs son claros y útiles para debugging

---

## Entregables

1. **Repositorio Bitbucket** con:
   - Pipeline funcional (`bitbucket-pipelines.yml`)
   - Código Python con tests (`hello.py`, `tests/test_hello.py`)
   - README con instrucciones de uso

2. **Capturas de pantalla:**
   - Ejecución exitosa del pipeline (vista de stages y steps)
   - Logs de cada step
   - Artifacts generados y disponibles para descarga
   - Variables de repositorio configuradas (sin mostrar el valor)

3. **Evidencias de funcionamiento:**
   - Historial de ejecuciones del pipeline en Bitbucket
   - Artifact `app-N.zip` descargable
   - Pipeline de PR ejecutándose al abrir un Pull Request

---

## Recursos Adicionales

- [Documentación oficial de Bitbucket Pipelines](https://support.atlassian.com/bitbucket-cloud/docs/get-started-with-bitbucket-pipelines/)
- [YAML Configuration Reference](https://support.atlassian.com/bitbucket-cloud/docs/bitbucket-pipelines-configuration-reference/)
- [Variables predefinidas](https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/)
- [Atlassian Pipelines Examples](https://bitbucket.org/atlassian/bitbucket-pipelines-examples/)
- [Pipe Marketplace (acciones pre-construidas)](https://bitbucket.org/product/features/pipelines/integrations)

---

📘 **Autor:**  
Wilson Julca Mejía  
Curso: *DevOps y Bitbucket Pipelines – CI/CD con Python*  
Universidad de Ingeniería y Tecnología (UTEC)
