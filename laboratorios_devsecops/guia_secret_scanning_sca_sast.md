# Laboratorio: Análisis de Dependencias y Secret Scanning con Trivy, Semgrep, Gitleaks y TruffleHog

**Duración estimada:** 120–150 min  
**Nivel:** Intermedio / Avanzado  
**Contexto:** Este laboratorio amplía el flujo DevSecOps aplicado al proyecto `juice-shop-devsecops`. Aquí aprenderás a ejecutar análisis manuales de vulnerabilidades y exposición de secretos utilizando contenedores Docker con herramientas SCA (Software Composition Analysis) y secret scanning, para luego automatizar todo el proceso en GitLab CI/CD.

---

## 🎯 Objetivos de aprendizaje

- Detectar vulnerabilidades en dependencias con **Trivy** (SCA)
- Identificar vulnerabilidades en código fuente con **Semgrep** (SAST)
- Detectar secretos y credenciales expuestas con **Gitleaks** y **TruffleHog**
- Prevenir secretos en commits futuros con **pre-commit hooks**
- Automatizar todos los escaneos en **GitLab CI/CD**

---

## 🧩 Requisitos previos

✅ Docker Desktop instalado  
✅ GitLab y acceso al proyecto `juice-shop-devsecops`  
✅ Conocimientos básicos de Node.js y dependencias  
✅ Conectividad a Internet para descargar imágenes Docker  

---

## 📁 Estructura base del proyecto

```
juice-shop-devsecops/
├── Dockerfile
├── package.json
├── src/
├── k8s/
├── terraform/
└── reports/
```

---

## Parte 1: Configuración del entorno

### 1.1 Clonar el proyecto

```bash
git clone https://github.com/wils0n/juice-shop-devsecops
cd juice-shop-devsecops
mkdir -p reports sbom
```

### 1.2 Apuntar remote a GitLab

El repo se clona desde GitHub, pero el pipeline corre en GitLab. Redirige el origin:

```bash
git remote set-url origin git@gitlab.com:<tu-usuario>/juice-shop-devsecops-test-20261.git

# Verificar
git remote -v
```

> Reemplaza `<tu-usuario>` por tu nombre de usuario en GitLab (ej. `pytuxi`).

### 1.3 Validar entorno Docker

```bash
docker version
docker images
```

### 1.4 Levantar app

```bash
docker-compose up -d
```

---

## Parte 2: Análisis con Trivy (SCA)

### 2.1 Ejecutar Trivy desde Docker

```bash
docker run --rm -v $(pwd):/src aquasec/trivy:latest fs /src   --format json --output /src/reports/trivy-report.json   --severity HIGH,CRITICAL
```

### 2.2 Reporte en formato tabla

```bash
docker run --rm -v $(pwd):/src aquasec/trivy:latest fs /src \D
  --format table --severity HIGH,CRITICAL
```

### 2.3 Generar SBOM (CycloneDX)

```bash
docker run --rm -v $(pwd):/src aquasec/trivy:latest fs /src \
  --format cyclonedx --output /src/sbom/sbom.json
```

> **¿Qué es un SBOM?** Un *Software Bill of Materials* es un inventario exhaustivo de todos los componentes de software incluidos en un proyecto: librerías, versiones, licencias y dependencias transitivas.

> **¿Cuándo se usa en DevSecOps?**
>
> | Momento | Uso |
> |---|---|
> | **CI/CD — stage SCA** | El pipeline genera el SBOM como artefacto del build. Si hay un CVE crítico en alguna dependencia, el pipeline falla antes de llegar a producción. |
> | **Release / deploy** | El `sbom.json` se adjunta al release tag o se almacena junto a la imagen Docker en el registry. Queda trazabilidad de qué versión de qué librería estaba en cada deploy. |
> | **Nuevo CVE publicado (reactivo)** | Sale Log4Shell o similar → buscas el componente en el SBOM → sabes en segundos qué servicios son vulnerables sin re-escanear todo. |
> | **Incident response** | Durante un ataque, el equipo de seguridad consulta el SBOM para mapear la superficie de exposición y priorizar el parcheo. |
> | **Auditoría de licencias** | Legal revisa el SBOM antes de distribuir el software comercialmente para detectar licencias incompatibles (GPL, AGPL). |
> | **Cumplimiento normativo** | Requerido por NIST SSDF, EO 14028 (EE.UU.) y regulaciones de la UE. Se entrega el SBOM al auditor como evidencia. |

---

## Parte 3: Detección de secretos

### 3.1 Escaneo con Gitleaks

```bash
docker run --rm -it -v $(pwd):/src zricethezav/gitleaks detect \
  --source /src \
  --report-path /src/reports/gitleaks-report.json
```

### 3.2 Escaneo con TruffleHog

```bash
docker run --rm -it -v $(pwd):/src trufflesecurity/trufflehog:latest filesystem /src \
  --results=verified,unknown \
  --json > reports/trufflehog-report.json
```

> Ambas herramientas buscarán API keys, tokens, passwords o certificados mal protegidos dentro del código o el historial Git.


---

## Parte 4: Automatización en GitLab CI/CD

Una vez validados los análisis manuales, automatiza todo el proceso creando el siguiente pipeline en la raíz del proyecto:

**Archivo:** `.gitlab-ci.yml`

```yaml
stages:
  - prepare
  - secret_scanning
  - sca
  - sast

# Preparación
prepare:
  image: node:20
  stage: prepare
  script:
    - node --version
    - npm ci --ignore-scripts || true
  artifacts:
    paths:
      - node_modules/
    expire_in: 1h
  rules:
    - when: always

# Secret Scanning con Gitleaks
gitleaks-scan:
  image: alpine:3.18
  stage: secret_scanning
  before_script:
    - apk add --no-cache git curl tar gzip
  script:
    - GITLEAKS_VERSION=8.27.2
    - curl -sSL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" -o gitleaks.tar.gz
    - tar -xzf gitleaks.tar.gz
    - chmod +x gitleaks
    - ./gitleaks detect --source . --report-path gitleaks-report.json || true
  artifacts:
    paths:
      - gitleaks-report.json
    expire_in: 1 week
  allow_failure: true
  rules:
    - when: always

# Secret Scanning con TruffleHog
trufflehog-scan:
  image: ubuntu:22.04
  stage: secret_scanning
  before_script:
    - apt-get update -y && apt-get install -y git curl jq python3 python3-pip --no-install-recommends
  script:
    - curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b .
    - ./trufflehog filesystem . --results=verified,unknown --json > trufflehog-report.json || true
  artifacts:
    paths:
      - trufflehog-report.json
    expire_in: 1 week
  allow_failure: true
  rules:
    - when: always

# SCA con Trivy
trivy-scan:
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  stage: sca
  variables:
    REPORTS_DIR: security-reports
  before_script:
    - mkdir -p $REPORTS_DIR
  script:
    - echo "🔍 Ejecutando Trivy (SCA)..."
    - trivy filesystem . --format json --severity HIGH,CRITICAL --output $REPORTS_DIR/trivy-report.json || true
    - trivy filesystem . --format template --template '@contrib/gitlab.tpl' --output $REPORTS_DIR/gl-dependency-scanning-report.json --severity HIGH,CRITICAL || true
    - trivy filesystem . --format table --output $REPORTS_DIR/trivy-table.txt --severity HIGH,CRITICAL || true
    - trivy filesystem . --format cyclonedx --output $REPORTS_DIR/sbom.json || true
  artifacts:
    paths:
      - $REPORTS_DIR/
    reports:
      dependency_scanning: $REPORTS_DIR/gl-dependency-scanning-report.json
    expire_in: 1 week
  allow_failure: true
  rules:
    - when: always

# SAST con Semgrep
semgrep-scan:
  image: returntocorp/semgrep:latest
  stage: sast
  needs:
    - gitleaks-scan
    - trufflehog-scan
  variables:
    SEMGREP_CONFIG: "p/ci,p/security-audit,p/docker,p/kubernetes,p/terraform"
    SEMGREP_SRC: "$CI_PROJECT_DIR"
  script:
    - echo "🔍 Ejecutando Semgrep (SAST)..."
    - semgrep --version
    - semgrep --config "$SEMGREP_CONFIG" --json --output semgrep-report.json "$SEMGREP_SRC" || true
    - semgrep --config "$SEMGREP_CONFIG" "$SEMGREP_SRC" > semgrep-report.txt || true
  artifacts:
    paths:
      - semgrep-report.json
      - semgrep-report.txt
    expire_in: 1 week
  allow_failure: true
  rules:
    - when: always
```

---

## Parte 5: Secret Scanning con Pre-commit Hooks

Bloquea secretos **antes** de que lleguen al repositorio usando `pre-commit` como capa de defensa local.

### 5.1 Instalar pre-commit

```bash
# Con pip
pip install pre-commit

# Verificar
pre-commit --version
```

### 5.2 Crear `.pre-commit-config.yaml`

En la raíz del proyecto `juice-shop-devsecops`:

```yaml
repos:
  # Gitleaks: detecta secretos y credenciales
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.27.2
    hooks:
      - id: gitleaks

  # TruffleHog: verifica secretos con entropía y patrones
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.88.28
    hooks:
      - id: trufflehog
        name: TruffleHog Secret Scanner
        entry: trufflehog filesystem --results=verified,unknown
        language: golang
        pass_filenames: false

  # Detecta archivos con posibles credenciales por nombre
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: detect-private-key
      - id: check-added-large-files
        args: ['--maxkb=500']
```

### 5.3 Instalar hooks en el repositorio

```bash
# Instala los hooks en .git/hooks/pre-commit
pre-commit install

# Verificar instalación
cat .git/hooks/pre-commit
```

### 5.4 Probar manualmente

```bash
# Ejecutar sobre todos los archivos
pre-commit run --all-files

# Ejecutar solo gitleaks
pre-commit run gitleaks --all-files
```

### 5.5 Simular detección de secreto

Agrega un secreto falso para validar que el hook bloquea el commit:

```bash
echo 'AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' >> src/config.js
git add src/config.js
git commit -m "test: secret scan hook"
# ❌ El commit debe ser BLOQUEADO por gitleaks
```

Elimina el secreto y verifica que el commit pasa:

```bash
# Revertir el cambio
git checkout src/config.js
git commit -m "chore: verify pre-commit hooks work"
# ✅ Commit debe pasar
```

### 5.6 Actualizar hooks

```bash
pre-commit autoupdate
```

### 5.7 Configuración para CI (opcional)

Para que GitLab CI también valide los hooks en pipeline:

```yaml
# Agregar al .gitlab-ci.yml existente
pre-commit-check:
  image: python:3.12-slim
  stage: secret_scanning
  before_script:
    - pip install pre-commit
    - apt-get update -y && apt-get install -y git --no-install-recommends
  script:
    - pre-commit run --all-files
  allow_failure: false
  rules:
    - when: always
```

> **Flujo recomendado:** pre-commit bloquea en local → GitLab CI valida en pipeline → doble barrera contra secretos expuestos.

---

## ✅ Checklist de Éxito

- [ ] Trivy, Semgrep, Gitleaks y TruffleHog ejecutan correctamente desde Docker  
- [ ] Reportes generados en `/reports` y `/sbom`  
- [ ] Se aplicaron correcciones en dependencias vulnerables  
- [ ] Pipeline de GitLab CI ejecuta los escaneos automáticamente  
- [ ] Artefactos JSON/TXT visibles en GitLab  
- [ ] `.pre-commit-config.yaml` creado con hooks de Gitleaks y TruffleHog  
- [ ] `pre-commit install` ejecutado y hooks activos en `.git/hooks/`  
- [ ] Commit con secreto falso bloqueado correctamente por pre-commit  
- [ ] Comprensión de diferencias entre análisis manual y automatizado  

---

## 📘 Entregables

1. Carpeta del proyecto `juice-shop-devsecops` con reportes (`reports/*.json`)  
2. Capturas de pantalla de:
   - Ejecuciones Docker (Trivy, Semgrep, Gitleaks, TruffleHog)
   - Reportes generados en GitLab CI  
3. Documento de reflexión:  
   - ¿Qué diferencias observas entre los análisis manuales y automatizados?  
   - ¿Qué ventajas aporta integrar SCA y Secret Scanning al pipeline DevSecOps?  

---

**Autor:** Wilson Julca Mejía  
Curso: *DevSecOps y Seguridad en CI/CD – UTEC*  
Universidad de Ingeniería y Tecnología (UTEC)  
