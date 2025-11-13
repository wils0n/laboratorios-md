# Laboratorio: Análisis de seguridad de la Infraestructura como Código

## Capítulo 1: Configuración del Entorno con Docker

**Requisito Previo:** Asegúrate de tener Docker instalado y funcionando.

```bash
docker --version
```

### 1.1 Herramientas de Análisis con Docker

#### 1.1.1 Checkov

*   **Verificar Versión:**
    ```bash
    docker run bridgecrew/checkov --version
    ```
*   **Comando de Ejecución:**
    ```bash
    # Bash (Linux/macOS)
    docker run -v $(pwd):/scan bridgecrew/checkov -d /scan

    # PowerShell (Windows)
    docker run -v ${pwd}:/scan bridgecrew/checkov -d /scan
    ```

#### 1.1.2 Trivy

*   **Verificar Versión:**
    ```bash
    docker run aquasec/trivy --version
    ```
*   **Comando de Ejecución (escanear IaC):**
    ```bash
    # Bash (Linux/macOS)
    docker run -v $(pwd):/workdir aquasec/trivy config /workdir

    # PowerShell (Windows)
    docker run -v ${pwd}:/workdir aquasec/trivy config /workdir
    ```

#### 1.1.3 Terrascan

*   **Verificar Versión:**
    ```bash
    docker run tenable/terrascan version
    ```
*   **Comando de Ejecución:**
    ```bash
    # Bash (Linux/macOS)
    docker run -v $(pwd):/app tenable/terrascan scan -p /app

    # PowerShell (Windows)
    docker run -v ${pwd}:/app tenable/terrascan scan -p /app
    ```

## Capítulo 2: Análisis de Seguridad

### Ejercicio 2.1: Escaneo básico con trivy

#### Bash

```bash
# Escanear configuración insegura de AWS
docker run -v $(pwd):/workdir aquasec/trivy config /workdir/cloud-examples/aws/aws-insecure.tf

# Ver reporte detallado de AWS en JSON
docker run -v $(pwd):/workdir aquasec/trivy config /workdir/cloud-examples/aws/aws-insecure.tf --format json > trivy-aws-report.json

# Escanear configuración insegura de GCP
docker run -v $(pwd):/workdir aquasec/trivy config /workdir/cloud-examples/gcp/gcp-insecure.tf

# Ver reporte detallado de GCP en JSON
docker run -v $(pwd):/workdir aquasec/trivy config /workdir/cloud-examples/gcp/gcp-insecure.tf --format json > trivy-gcp-report.json

# Escanear configuración insegura de Azure
docker run -v $(pwd):/workdir aquasec/trivy config /workdir/cloud-examples/azure/azure-insecure.tf

# Ver reporte detallado de Azure en JSON
docker run -v $(pwd):/workdir aquasec/trivy config /workdir/cloud-examples/azure/azure-insecure.tf --format json > trivy-azure-report.json
```

#### PowerShell

```powershell
# Escanear configuración aws-cloudformation
docker run -v ${pwd}:/workdir aquasec/trivy config /workdir/aws-cloudformation-rekognition/rekognition-template.yml

# Escanear configuración insegura de AWS
docker run -v ${pwd}:/workdir aquasec/trivy config /workdir/cloud-examples/aws/aws-insecure.tf

# Ver reporte detallado de AWS en JSON
docker run -v ${pwd}:/workdir aquasec/trivy config /workdir/cloud-examples/aws/aws-insecure.tf --format json > trivy-aws-report.json

# Escanear configuración insegura de GCP
docker run -v ${pwd}:/workdir aquasec/trivy config /workdir/cloud-examples/gcp/gcp-insecure.tf

# Ver reporte detallado de GCP en JSON
docker run -v ${pwd}:/workdir aquasec/trivy config /workdir/cloud-examples/gcp/gcp-insecure.tf --format json > trivy-gcp-report.json

# Escanear configuración insegura de Azure
docker run -v ${pwd}:/workdir aquasec/trivy config /workdir/cloud-examples/azure/azure-insecure.tf

# Ver reporte detallado de Azure en JSON
docker run -v ${pwd}:/workdir aquasec/trivy config /workdir/cloud-examples/azure/azure-insecure.tf --format json > trivy-azure-report.json
```

### Ejercicio 2.2: Escaneo básico con Checkov

#### Bash

```bash
# Escanear configuración aws-cloudformation
docker run -v $(pwd):/scan bridgecrew/checkov -f /scan/aws-cloudformation-rekognition/rekognition-template.yml

# Escanear configuración insegura de AWS
docker run -v $(pwd):/scan bridgecrew/checkov -f /scan/cloud-examples/aws/aws-insecure.tf

# Escanear AWS con salida JSON
docker run -v $(pwd):/scan bridgecrew/checkov -f /scan/cloud-examples/aws/aws-insecure.tf --output json > checkov-aws-report.json

# Escanear configuración insegura de GCP
docker run -v $(pwd):/scan bridgecrew/checkov -f /scan/cloud-examples/gcp/gcp-insecure.tf

# Escanear GCP con salida JSON
docker run -v $(pwd):/scan bridgecrew/checkov -f /scan/cloud-examples/gcp/gcp-insecure.tf --output json > checkov-gcp-report.json

# Escanear configuración insegura de Azure
docker run -v $(pwd):/scan bridgecrew/checkov -f /scan/cloud-examples/azure/azure-insecure.tf

# Escanear Azure con salida JSON
docker run -v $(pwd):/scan bridgecrew/checkov -f /scan/cloud-examples/azure/azure-insecure.tf --output json > checkov-azure-report.json

# Escanear todo el directorio
docker run -v $(pwd):/scan bridgecrew/checkov -d /scan/cloud-examples --framework terraform
```

#### PowerShell

```powershell
# Escanear configuración insegura de AWS
docker run -v ${pwd}:/scan bridgecrew/checkov -f /scan/cloud-examples/aws/aws-insecure.tf

# Escanear AWS con salida JSON
docker run -v ${pwd}:/scan bridgecrew/checkov -f /scan/cloud-examples/aws/aws-insecure.tf --output json > checkov-aws-report.json

# Escanear configuración insegura de GCP
docker run -v ${pwd}:/scan bridgecrew/checkov -f /scan/cloud-examples/gcp/gcp-insecure.tf

# Escanear GCP con salida JSON
docker run -v ${pwd}:/scan bridgecrew/checkov -f /scan/cloud-examples/gcp/gcp-insecure.tf --output json > checkov-gcp-report.json

# Escanear configuración insegura de Azure
docker run -v ${pwd}:/scan bridgecrew/checkov -f /scan/cloud-examples/azure/azure-insecure.tf

# Escanear Azure con salida JSON
docker run -v ${pwd}:/scan bridgecrew/checkov -f /scan/cloud-examples/azure/azure-insecure.tf --output json > checkov-azure-report.json

# Escanear todo el directorio
docker run -v ${pwd}:/scan bridgecrew/checkov -d /scan/cloud-examples --framework terraform
```

### Ejercicio 2.3: Escaneo básico con terrascan

#### Bash

```bash
# Escanear configuración insegura de AWS
docker run -v $(pwd):/app tenable/terrascan scan -f /app/cloud-examples/aws/aws-insecure.tf

# Ver reporte AWS detallado en JSON
docker run -v $(pwd):/app tenable/terrascan scan -f /app/cloud-examples/aws/aws-insecure.tf  -o json > terrascan-aws-report.json

# Escanear configuración insegura de GCP
docker run -v $(pwd):/app tenable/terrascan scan -f /app/cloud-examples/gcp/gcp-insecure.tf

# Ver reporte GCP detallado en JSON
docker run -v $(pwd):/app tenable/terrascan scan -f /app/cloud-examples/gcp/gcp-insecure.tf  -o json > terrascan-gcp-report.json

# Escanear configuración insegura de Azure
docker run -v $(pwd):/app tenable/terrascan scan -f /app/cloud-examples/azure/azure-insecure.tf

# Ver reporte Azure detallado en JSON
docker run -v $(pwd):/app tenable/terrascan scan -f /app/cloud-examples/azure/azure-insecure.tf -o json > terrascan-azure-report.json
```

#### PowerShell

```powershell
# Escanear configuración insegura de AWS
docker run -v ${pwd}:/app tenable/terrascan scan -f /app/cloud-examples/aws/aws-insecure.tf

# Ver reporte AWS detallado en JSON
docker run -v ${pwd}:/app tenable/terrascan scan -f /app/cloud-examples/aws/aws-insecure.tf  -o json > terrascan-aws-report.json

# Escanear configuración insegura de GCP
docker run -v ${pwd}:/app tenable/terrascan scan -f /app/cloud-examples/gcp/gcp-insecure.tf

# Ver reporte GCP detallado en JSON
docker run -v ${pwd}:/app tenable/terrascan scan -f /app/cloud-examples/gcp/gcp-insecure.tf  -o json > terrascan-gcp-report.json

# Escanear configuración insegura de Azure
docker run -v ${pwd}:/app tenable/terrascan scan -f /app/cloud-examples/azure/azure-insecure.tf

# Ver reporte Azure detallado en JSON
docker run -v ${pwd}:/app tenable/terrascan scan -f /app/cloud-examples/azure/azure-insecure.tf -o json > terrascan-azure-report.json
```