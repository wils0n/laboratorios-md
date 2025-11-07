# Laboratorio 11.2: Análisis de Dependencias y Secret Scanning con Trivy, Snyk, Gitleaks y TruffleHog

**Duración estimada:** 120–150 min  
**Nivel:** Intermedio / Avanzado  
**Contexto:** Este laboratorio amplía el flujo DevSecOps aplicado al proyecto `juice-shop-devsecops`. Aquí aprenderás a ejecutar análisis manuales de vulnerabilidades y exposición de secretos utilizando contenedores Docker con herramientas SCA (Software Composition Analysis) y secret scanning, para luego automatizar todo el proceso en GitLab CI/CD.

---

## 🎯 Objetivos de aprendizaje

- Ejecutar análisis de vulnerabilidades con **Trivy** y **Snyk**  
- Detectar secretos y credenciales expuestas con **Gitleaks** y **TruffleHog**  
- Comparar resultados y aplicar correcciones manuales  
- Validar mitigaciones con re-análisis  
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
git clone https://gitlab.com/pytuxi/juice-shop-devsecops.git
cd juice-shop-devsecops
mkdir -p reports sbom
```

### 1.2 Validar entorno Docker

```bash
docker version
docker images
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
docker run --rm -v $(pwd):/src aquasec/trivy:latest fs /src   --format cyclonedx --output /src/sbom/sbom.json
```

---

## Parte 3: Detección de secretos

### 3.1 Escaneo con Gitleaks

```bash
docker run --rm -it -v $(pwd):/src zricethezav/gitleaks detect --source /src
```

### 3.2 Escaneo con TruffleHog

```bash
docker run --rm -it -v $(pwd):/src trufflesecurity/trufflehog:latest filesystem /src
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

## ✅ Checklist de Éxito

- [ ] Trivy, Snyk, Gitleaks y TruffleHog ejecutan correctamente desde Docker  
- [ ] Reportes generados en `/reports` y `/sbom`  
- [ ] Se aplicaron correcciones en dependencias vulnerables  
- [ ] Pipeline de GitLab CI ejecuta los escaneos automáticamente  
- [ ] Artefactos JSON/TXT visibles en GitLab  
- [ ] Comprensión de diferencias entre análisis manual y automatizado  

---

## 📘 Entregables

1. Carpeta del proyecto `juice-shop-devsecops` con reportes (`reports/*.json`)  
2. Capturas de pantalla de:
   - Ejecuciones Docker (Trivy, Snyk, Gitleaks, TruffleHog)
   - Reportes generados en GitLab CI  
3. Documento de reflexión:  
   - ¿Qué diferencias observas entre los análisis manuales y automatizados?  
   - ¿Qué ventajas aporta integrar SCA y Secret Scanning al pipeline DevSecOps?  

---

**Autor:** Wilson Julca Mejía  
Curso: *DevSecOps y Seguridad en CI/CD – UTEC*  
Universidad de Ingeniería y Tecnología (UTEC)  
