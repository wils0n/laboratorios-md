# Guía de Laboratorio: Gestión Centralizada de Hallazgos con DefectDojo

**Duración estimada:** 90–120 min

**Nivel:** Intermedio

**Contexto:** Este laboratorio cubre la instalación local de **DefectDojo** mediante Docker Compose, su configuración inicial, la carga manual de hallazgos generados por herramientas SAST/SCA/Secrets y la automatización de esa carga desde un pipeline de **GitLab CI/CD**. DefectDojo actúa como plataforma centralizada de gestión de vulnerabilidades, normalizando resultados de distintas herramientas en un único panel. Se usa el proyecto `juice-shop-devsecops` con reportes de Semgrep, Trivy, Gitleaks y TruffleHog.

---

## 🎯 Objetivos de aprendizaje

- Desplegar DefectDojo localmente con Docker Compose.
- Configurar productos, engagements y pruebas dentro de la plataforma.
- Cargar hallazgos manualmente desde reportes JSON nativos de Semgrep, Trivy, Gitleaks y TruffleHog.
- Automatizar la ingesta de hallazgos desde un job de GitLab CI/CD usando la API REST.
- Interpretar el dashboard de deuda técnica de seguridad.

---

## 🧩 Requisitos previos

✅ Docker Desktop instalado y corriendo.

✅ Docker Compose v2 disponible (`docker compose version`).

✅ Al menos **8 GB RAM** asignados a Docker Desktop.

✅ Proyecto `juice-shop-devsecops` con reportes generados de fases anteriores.

✅ Acceso a GitLab con permisos para editar variables CI/CD.

> **Nota:** DefectDojo requiere varios contenedores corriendo simultáneamente. En máquinas con menos de 8 GB puede ser lento en el arranque inicial (2–5 minutos).

---

## Parte 1: Instalación local con Docker Compose

### 1.1 Clonar el repositorio oficial

```bash
git clone https://github.com/DefectDojo/django-DefectDojo.git
cd django-DefectDojo
```

### 1.2 Variables de entorno

No se requiere copiar ningún archivo `.env`. El `docker-compose.yml` tiene todos los valores por defecto hardcodeados con la sintaxis `${VAR:-default}`, lo que es suficiente para uso local en laboratorio.

> **Para producción:** define un `.env` en la raíz del repo con las variables que quieras sobreescribir, por ejemplo `DD_SECRET_KEY=tu-clave-segura`.

### 1.3 Iniciar DefectDojo

```bash
docker compose up -d
```

> No uses `--profile postgres-redis` — la versión actual no tiene perfiles definidos. Todos los servicios arrancan con el comando base.

Este comando levanta los siguientes servicios:

| Servicio | Rol |
|----------|-----|
| `nginx` | Proxy reverso, expone puerto 8080 |
| `uwsgi` | Aplicación Django |
| `celerybeat` + `celeryworker` | Tareas asíncronas (notificaciones, deduplicación) |
| `postgres` | Base de datos |
| `valkey` | Cola de mensajes (reemplazó a Redis desde 2024) |
| `initializer` | Crea la BD y usuario admin en primer arranque |

El `initializer` puede tardar **2–5 minutos** en el primer arranque mientras crea la base de datos y las migraciones.

### 1.4 Verificar que los contenedores estén corriendo

```bash
docker compose ps
```

Salida esperada (todos en estado `Up`, `initializer` puede mostrar `Exited (0)` — es normal):

```
NAME                           STATUS
django-defectdojo-nginx-1      Up
django-defectdojo-uwsgi-1      Up
django-defectdojo-celerybeat-1 Up
django-defectdojo-celeryworker-1 Up
django-defectdojo-postgres-1   Up
django-defectdojo-valkey-1     Up
django-defectdojo-initializer-1 Exited (0)
```

### 1.5 Obtener la contraseña del admin generada automáticamente

```bash
docker compose logs initializer | grep -i "password\|admin"
```

Guarda esa contraseña. La necesitarás en el siguiente paso.

### 1.6 Acceder a la interfaz web

Abre el navegador en: `http://localhost:8080`

- **Usuario:** `admin`
- **Contraseña:** la obtenida en el paso anterior

---

## Parte 2: Configuración inicial de la plataforma

DefectDojo organiza los hallazgos en una jerarquía: **Product Type → Product → Engagement → Test → Findings**.

### 2.1 Crear un Product Type

1. Ve a **Product Types** en el menú lateral.
2. Clic en **+ Add Product Type**.
3. Ingresa:
   - **Name:** `Aplicaciones Web`
   - **Description:** `Portafolio de aplicaciones web internas`
4. Clic en **Submit**.

### 2.2 Crear un Product

1. Ve a **Products** → **+ Add Product**.
2. Ingresa:
   - **Name:** `Juice Shop`
   - **Description:** `Aplicación de e-commerce vulnerable para laboratorio`
   - **Product Type:** `Aplicaciones Web`
   - **Business Criticality:** `High`
   - **Platform:** `Web`
   - **Lifecycle:** `Production`
3. Clic en **Submit**.

### 2.3 Crear un Engagement

Un Engagement agrupa todas las pruebas de seguridad de un sprint o release.

1. Dentro del producto `Juice Shop`, clic en **+ Add Engagement**.
2. Ingresa:
   - **Name:** `Sprint 1 - Análisis de seguridad`
   - **Engagement Type:** `CI/CD`
   - **Status:** `In Progress`
   - **Target Start / Target End:** fechas del sprint actual
3. Clic en **Submit**.

---

## Parte 3: Carga manual de hallazgos

### 3.1 Reportes del proyecto

El proyecto `juice-shop-devsecops` ya incluye reportes generados en fases anteriores:

```
juice-shop-devsecops/reports/
├── semgrep-report.json      # SAST — formato JSON nativo de Semgrep (26 hallazgos)
├── trivy-report.json        # Secrets en código e IaC detectados por Trivy
├── gitleaks-report.json     # Secret scanning — 93 hallazgos
└── trufflehog-report.json   # Secret scanning — NDJSON con escape sequences
```

> **Nota sobre formatos:** Semgrep genera JSON nativo (no SARIF) con la bandera `--json`. TruffleHog genera NDJSON con secuencias de escape al inicio del archivo — DefectDojo requiere que estas líneas sean filtradas antes de importar.

### 3.2 Importar reporte Semgrep (SAST)

1. Dentro del Engagement creado, clic en **+ Add Tests**.
2. Configura la prueba:
   - **Test Type:** `Semgrep JSON Report`
   - **Environment:** `Development`
   - **Version:** `1.0`
3. Clic en **Submit**.
4. Dentro del test creado, clic en **Import Scan Results**.
5. Selecciona:
   - **Scan Type:** `Semgrep JSON Report`
   - **File:** selecciona `reports/semgrep-report.json`
   - **Active:** habilitado
6. Clic en **Import**.

> **Importante:** El scan type es `Semgrep JSON Report`, no `SARIF`. Usar SARIF con un archivo JSON nativo de Semgrep producirá error 400.

### 3.3 Importar reporte Trivy

1. Crea un nuevo test dentro del mismo Engagement.
   - **Test Type:** `Trivy Scan`
   - **Environment:** `Development`
2. En **Import Scan Results**:
   - **Scan Type:** `Trivy Scan`
   - **File:** selecciona `reports/trivy-report.json`
3. Clic en **Import**.

> El reporte de Trivy en este proyecto contiene hallazgos de clase `secret` (no vulnerabilidades de dependencias), ya que se ejecutó sobre el filesystem sin imagen de contenedor.

### 3.4 Importar reporte Gitleaks (Secrets)

1. Crea un nuevo test:
   - **Test Type:** `Gitleaks Scan`
   - **Environment:** `Development`
2. En **Import Scan Results**:
   - **Scan Type:** `Gitleaks Scan`
   - **File:** selecciona `reports/gitleaks-report.json`
3. Clic en **Import**.

### 3.5 Importar reporte TruffleHog (Secrets)

TruffleHog genera NDJSON con secuencias de escape terminales al inicio. Antes de importar, limpia el archivo:

```bash
# Filtrar solo líneas con hallazgos reales (tienen "SourceMetadata")
grep '"SourceMetadata"' reports/trufflehog-report.json | \
  sed 's/\r//' > /tmp/trufflehog-clean.json

# Verificar que el archivo no esté vacío
wc -l /tmp/trufflehog-clean.json
```

Luego importa:
1. Crea un nuevo test:
   - **Test Type:** `Trufflehog Scan`
   - **Environment:** `Development`
2. En **Import Scan Results**:
   - **Scan Type:** `Trufflehog Scan`
   - **File:** selecciona `/tmp/trufflehog-clean.json`
3. Clic en **Import**.

### 3.6 Verificar hallazgos importados

1. Ve a **Findings** en el menú lateral.
2. Aplica filtros por:
   - **Severity:** `Critical`, `High`
   - **Product:** `Juice Shop`
3. Explora un hallazgo para ver:
   - Descripción del vulnerabilidad
   - Archivo y línea afectados
   - Herramienta de origen
   - CVSS Score (cuando aplica)
   - Referencias CWE / CVE

---

## Parte 4: Obtener el API Key

Para automatizar la ingesta necesitas un token de autenticación.

1. Clic en el usuario `admin` (esquina superior derecha).
2. Ve a **API v2 Key**.
3. Copia el token — lo usarás como variable en GitLab CI/CD.

También puedes obtenerlo vía CLI:

```bash
curl -X POST http://localhost:8080/api/v2/api-token-auth/ \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "TU_PASSWORD"}' | jq '.token'
```

### 4.1 Obtener IDs necesarios para la API

Necesitas el ID del **Product** (el engagement se crea automáticamente en el pipeline):

```bash
export DD_TOKEN="TU_API_TOKEN"
export DD_URL="http://localhost:8080"

# Listar productos — anota el ID de "Juice Shop"
curl -s -H "Authorization: Token $DD_TOKEN" \
  "$DD_URL/api/v2/products/" | jq '.results[] | {id, name}'

# Verificar engagements creados (referencia)
curl -s -H "Authorization: Token $DD_TOKEN" \
  "$DD_URL/api/v2/engagements/?product=1" | jq '.results[] | {id, name, status}'
```

Anota el **product ID** — lo usarás como variable `DEFECTDOJO_PRODUCT_ID` en GitLab.

---

## Parte 5: Automatización desde GitLab CI/CD

### 5.1 Configurar variables en GitLab

En tu proyecto GitLab, ve a **Settings → CI/CD → Variables** y agrega:

| Variable | Valor | Protegida | Enmascarada |
|----------|-------|-----------|-------------|
| `DEFECTDOJO_URL` | URL pública de ngrok (ver abajo) | No | No |
| `DEFECTDOJO_TOKEN` | `tu-api-token` | Sí | Sí |
| `DEFECTDOJO_PRODUCT_ID` | `1` (ID del producto Juice Shop) | No | No |

> **Los runners SaaS de GitLab.com corren en la nube** — no pueden alcanzar `localhost` ni `host.docker.internal`. Necesitas exponer DefectDojo con un túnel público.

**Exponer DefectDojo local con ngrok:**

```bash
brew install ngrok
ngrok config add-authtoken TU_TOKEN_DE_NGROK   # cuenta gratis en ngrok.com
ngrok http 8080
# Copia la URL: https://abc123.ngrok-free.app
```

Usa esa URL como valor de `DEFECTDOJO_URL` en GitLab. La URL cambia cada vez que reinicias ngrok — actualiza la variable en cada sesión.

> El engagement se crea **automáticamente por pipeline** usando `CI_PIPELINE_ID` y `CI_COMMIT_REF_NAME`, lo que permite trazabilidad por build.

### 5.2 Script de importación reutilizable

El archivo `scripts/upload_to_defectdojo.sh` ya está incluido en el repositorio. Maneja:
- Validación de archivo existente y no vacío
- Limpieza automática del NDJSON de TruffleHog (escape sequences)
- Respuesta HTTP con mensaje de error detallado

```bash
# Uso manual
export DEFECTDOJO_URL="http://localhost:8080"
export DEFECTDOJO_TOKEN="tu-token"
export DEFECTDOJO_ENGAGEMENT_ID="1"

bash scripts/upload_to_defectdojo.sh "Semgrep JSON Report" reports/semgrep-report.json
bash scripts/upload_to_defectdojo.sh "Trivy Scan"          reports/trivy-report.json
bash scripts/upload_to_defectdojo.sh "Gitleaks Scan"       reports/gitleaks-report.json
bash scripts/upload_to_defectdojo.sh "Trufflehog Scan"     reports/trufflehog-report.json
```

### 5.3 Stage defectdojo en el pipeline existente

El `.gitlab-ci.yml` ya tiene el stage `defectdojo` añadido al final. El job `upload-defectdojo`:

1. Espera que terminen `gitleaks-scan`, `trufflehog-scan`, `trivy-scan` y `semgrep-scan`.
2. Crea un engagement nuevo por pipeline usando `CI_PIPELINE_ID` y `CI_COMMIT_SHORT_SHA`.
3. Sube los 4 reportes con los scan types correctos.

```yaml
# Fragmento relevante — ya existe en .gitlab-ci.yml
upload-defectdojo:
  image: alpine/curl:latest
  stage: defectdojo
  needs:
    - gitleaks-scan
    - trufflehog-scan
    - trivy-scan
    - semgrep-scan
  dependencies:
    - gitleaks-scan
    - trufflehog-scan
    - trivy-scan
    - semgrep-scan
  variables:
    REPORTS_DIR: security-reports
  before_script:
    - apk add --no-cache bash
    - chmod +x scripts/upload_to_defectdojo.sh
  script:
    # Crear engagement — en script (no before_script) para que errores de conexión
    # muestren mensaje claro y no rompan el job antes de tiempo
    - |
      RESPONSE=$(curl -sf --max-time 15 -X POST "$DEFECTDOJO_URL/api/v2/engagements/" \
        -H "Authorization: Token $DEFECTDOJO_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
          \"name\": \"Pipeline #$CI_PIPELINE_ID - $CI_COMMIT_REF_NAME\",
          \"product\": $DEFECTDOJO_PRODUCT_ID,
          \"target_start\": \"$(date +%Y-%m-%d)\",
          \"target_end\": \"$(date +%Y-%m-%d)\",
          \"engagement_type\": \"CI/CD\",
          \"status\": \"In Progress\",
          \"build_id\": \"$CI_PIPELINE_ID\",
          \"commit_hash\": \"$CI_COMMIT_SHORT_SHA\",
          \"branch_tag\": \"$CI_COMMIT_REF_NAME\",
          \"source_code_management_uri\": \"$CI_PROJECT_URL\"
        }") || { echo "ERROR: No se pudo conectar a DefectDojo en $DEFECTDOJO_URL"; exit 1; }
      export DEFECTDOJO_ENGAGEMENT_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
      echo "Engagement creado: $DEFECTDOJO_ENGAGEMENT_ID"
    - bash scripts/upload_to_defectdojo.sh "Gitleaks Scan"       "gitleaks-report.json"
    - bash scripts/upload_to_defectdojo.sh "Trufflehog Scan"     "trufflehog-report.json"
    - bash scripts/upload_to_defectdojo.sh "Trivy Scan"          "$REPORTS_DIR/trivy-report.json"
    - bash scripts/upload_to_defectdojo.sh "Semgrep JSON Report" "semgrep-report.json"
  rules:
    - if: $DEFECTDOJO_URL == null
      when: never
    - when: always
  allow_failure: true
```

> **Notas de implementación:**
> - La creación del engagement va en `script`, no en `before_script` — si falla la conexión, el error es visible y el job termina limpiamente con `exit 1`.
> - `curl -sf --max-time 15` — falla rápido (15 s timeout) si DefectDojo no responde.
> - Las reglas usan `when: always` en lugar de filtrar por branch — el job corre en cualquier rama mientras `DEFECTDOJO_URL` esté definida.
> - Los paths de artifacts: Gitleaks y TruffleHog en raíz, Trivy en `security-reports/`, Semgrep en raíz.

---

## Parte 6: Verificar resultados en el dashboard

### 6.1 Ver resumen del producto

1. Ve a **Products → Juice Shop**.
2. Observa el panel con:
   - Total de findings por severidad
   - Tendencia en el tiempo
   - Findings por herramienta de origen

### 6.2 Analizar deuda técnica

1. Ve a **Metrics → Product Metrics**.
2. Selecciona `Juice Shop`.
3. Revisa:
   - **Open findings** por severidad acumulados
   - **Closed/Accepted findings** por sprint
   - **Age of findings** — hallazgos antiguos sin remediar

### 6.3 Gestionar un hallazgo individual

1. Abre cualquier finding de severidad `Critical` o `High`.
2. Acciones disponibles:
   - **Risk Acceptance** — aceptar el riesgo con justificación y fecha de expiración
   - **False Positive** — marcar como falso positivo
   - **Assign** — asignar a un miembro del equipo
   - **Add Note** — agregar contexto o plan de remediación
   - **Link to JIRA** — si tienes la integración configurada

---

## Parte 7: Detener el entorno

Cuando termines el laboratorio:

```bash
# Detener sin borrar datos
docker compose down

# Detener Y borrar volúmenes (reset completo)
docker compose down -v
```

---

## 📋 Resumen de tipos de escaneo soportados

| Herramienta | Scan Type en DefectDojo |
|-------------|------------------------|
| Semgrep (JSON nativo `--json`) | `Semgrep JSON Report` |
| Semgrep (SARIF `--sarif`) | `SARIF` |
| Trivy (filesystem) | `Trivy Scan` |
| Trivy (container) | `Trivy Scan` |
| Gitleaks | `Gitleaks Scan` |
| OWASP ZAP | `ZAP Scan` |
| Snyk | `Snyk Scan` |
| Bandit | `Bandit Scan` |
| Checkov (IaC) | `Checkov Scan` |
| TruffleHog | `Trufflehog Scan` |
| Grype | `Anchore Grype` |

> Lista completa en: `http://localhost:8080/api/v2/#/import-scan/import_scan_create` → campo `scan_type`.

---

## 🔧 Troubleshooting común

**DefectDojo no arranca / contenedores en `Restarting`:**
```bash
# Ver logs del inicializador
docker compose logs initializer

# Ver logs de la app
docker compose logs uwsgi | tail -50

# El servicio de mensajería ahora se llama valkey (no redis)
docker compose logs valkey | tail -20
```

**Error 400 al importar via API:**
- Verifica que el `scan_type` coincida exactamente con el nombre esperado (sensible a mayúsculas).
- Para Semgrep: usar `Semgrep JSON Report` con archivos `--json`, no `SARIF`.
- Para TruffleHog: el archivo debe contener solo líneas NDJSON con `SourceMetadata` — el script las filtra automáticamente.
- Verifica que el formato del archivo sea válido para ese tipo de escaneo.

**Error 401 Unauthorized:**
- Verifica que el token sea correcto y no tenga espacios extra.
- Asegúrate de usar `Token <valor>` y no `Bearer <valor>`.

**Stage `defectdojo` no aparece en el pipeline:**
- Las `rules` del job lo están omitiendo. Si usas ramas distintas a `main`/`develop`, cambia a `when: always` con guardia `$DEFECTDOJO_URL == null`.
- Si `DEFECTDOJO_URL` no está definida como variable GitLab, el job se omite silenciosamente.

**`ERROR: No se pudo conectar a DefectDojo`:**
- Los runners SaaS de GitLab.com no alcanzan `localhost`. Usa ngrok u otro túnel público.
- Verifica que ngrok siga corriendo y que la URL en la variable de GitLab sea la actual.

**`mktemp: : Invalid argument` en Alpine:**
- Alpine usa BusyBox `mktemp` que no acepta sufijos. El script usa `$$` (PID del proceso) para generar nombres únicos: `/tmp/trufflehog-clean-$$.json`.

**`File extension "" is not allowed`:**
- DefectDojo rechaza archivos sin extensión. Causa: archivo temporal sin `.json`. Resuelto con la corrección de `mktemp` anterior.

**Hallazgos duplicados:**
- Usa `close_old_findings=true` en la llamada API para que DefectDojo cierre automáticamente hallazgos de importaciones anteriores que ya no aparezcan.
- DefectDojo usa un hash de deduplicación por `title + severity + file_path + line`.
