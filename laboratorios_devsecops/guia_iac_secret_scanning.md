
# Guía Final: Pipeline DevSecOps con GitLab — Secret Scanning + IaC Scanning

**Duración estimada:** 120–150 min  
**Nivel:** Intermedio / Avanzado  

## Introducción
En este laboratorio construiremos un pipeline DevSecOps profesional utilizando GitLab CI/CD, integrando:

- Secret Scanning (detección de credenciales expuestas)
- Análisis de IaC (Terraform) con Checkov
- Artefactos automáticos de seguridad
- Flujo CI/CD seguro

## Objetivos de aprendizaje
- Crear un pipeline CI/CD en GitLab desde cero.
- Ejecutar TruffleHog para detectar secretos.
- Ejecutar Checkov para analizar IaC.
- Generar reportes de seguridad automáticos.
- Implementar un flujo DevSecOps basado en shift-left.

## Requisitos previos
- Cuenta en GitLab
- Docker Desktop o Engine
- Git + CI/CD básicos
- Editor como VSCode

## Estructura del proyecto
```
.
├── .gitlab-ci.yml
└── iac/
    └── cloud-examples/
        ├── aws-insecure.tf
        ├── azure-insecure.tf
        └── gcp-insecure.tf
└── backend/
└── frontend/
```

Los archivos .tf provienen de:
👉 https://github.com/wils0n/iac-lab/tree/main/cloud-examples

## Parte 1: Configuración Inicial
Crear carpetas:

```bash
mkdir -p iac/cloud-examples
cp cloud-examples/*.tf iac/cloud-examples/
```

Subir a GitLab:

```bash
git add .
git commit -m "Add insecure IaC files"
git push origin main
```

## Parte 2: Secret Scanning con TruffleHog

### Job de Secret Scanning

```yaml
stages:
  - secret-scanning-iac
  - iac-scanning

secret_scanning-iac:
  stage: secret-scanning-iac
  image: ubuntu:22.04
  before_script:
    - apt-get update -y && apt-get install -y git curl jq python3 python3-pip --no-install-recommends
  script:
    - curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b .
    - ./trufflehog filesystem ./iac/cloud-examples --results=verified,unknown --json > trufflehog-report.json || true
    - |
      if [ ! -s trufflehog-report.json ]; then
        echo '{"results": [], "verified_secrets": 0, "unverified_secrets": 0}' > trufflehog-report.json
      fi
    - echo "📄 Reporte de secretos:"
    - cat trufflehog-report.json
  artifacts:
    paths:
      - trufflehog-report.json
    expire_in: 1 week
  allow_failure: true
  rules:
    - when: always
```

## Parte 3: IaC Scanning con Checkov

```yaml
iac_security_scan:
  stage: iac-scanning
  needs:
    - secret_scanning-iac
  image:
    name: bridgecrew/checkov:latest
    entrypoint: [""]
  script:
    - checkov -d ./iac/cloud-examples -o json > checkov-report.json || true
  artifacts:
    when: always
    paths:
      - checkov-report.json
    expire_in: 1 week
  allow_failure: true
  rules:
    - when: always
```

## Pipeline completo

```yaml
stages:
  - secret-scanning-iac
  - iac-scanning

# Secret Scanning con TruffleHog
secret_scanning-iac:
  stage: secret-scanning-iac
  image: ubuntu:22.04
  before_script:
    - apt-get update -y && apt-get install -y git curl jq python3 python3-pip --no-install-recommends
  script:
    - curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b .
    - ./trufflehog filesystem ./iac/cloud-examples --results=verified,unknown --json > trufflehog-report.json || true
    - |
      if [ ! -s trufflehog-report.json ]; then
        echo '{"results": [], "verified_secrets": 0, "unverified_secrets": 0}' > trufflehog-report.json
      fi
    - echo "📄 Reporte de secretos:"
    - cat trufflehog-report.json
  artifacts:
    paths:
      - trufflehog-report.json
    expire_in: 1 week
  allow_failure: true
  rules:
    - when: always

# IaC Scanning con Checkov
iac_security_scan:
  stage: iac-scanning
  needs:
    - secret_scanning-iac
  image:
    name: bridgecrew/checkov:latest
    entrypoint: [""]
  script:
    - checkov -d ./iac/cloud-examples -o json > checkov-report.json || true
  artifacts:
    when: always
    paths:
      - checkov-report.json
    expire_in: 1 week
  allow_failure: true
  rules:
    - when: always
```

## Checklist de éxito
- [ ] Pipeline ejecuta automáticamente
- [ ] Reporte de TruffleHog generado
- [ ] Reporte de Checkov generado
- [ ] Ambos jobs en verde
- [ ] Artefactos descargables

## Entregables
1. URL del repositorio
2. Captura del pipeline
3. Captura de artefactos
4. Logs de cada job

---

Autor: **Wilson Julca Mejía**  
Curso: *DevSecOps y Seguridad en CI/CD – UTEC*
