# SAST aplicado a Juicy Shop - DevSecOps

---

## Objetivo

Practicar análisis SAST usando múltiples herramientas y variantes sobre el código de Juicy Shop, generando y revisando resultados, filtrando, excluyendo y exportando en diferentes formatos.

---

## Requisitos previos

- Juicy Shop DevSecOps en el directorio `juicy-shop-devsecops`
- Docker y Docker Compose instalados
- Node.js 20.x y npm (solo para preparar la app si corresponde)
- Git instalado

---

## Estructura del laboratorio

- Todas las ejecuciones deben hacerse desde el directorio raíz del código (`juicy-shop-devsecops`).

Clonar el repositorio del laboratorio y situarte en su raíz. Por ejemplo:

  ```bash
  git clone https://github.com/wils0n/juice-shop-devsecops
  cd juice-shop-devsecops
  ```

- Los resultados de cada herramienta van a la carpeta `resultados/` (SAST, secrets) o `zap-report/` (ZAP).
- Todos los comandos de ejemplo funcionan igual en Mac/Linux. En Windows usa PowerShell y ajusta las rutas (`${PWD}` en vez de `$(pwd)`).
- **Tips:** Si un análisis requiere que la aplicación esté corriendo (ZAP), primero levanta la app con Docker Compose.

---

## 1. Ejecución de SAST

### 1.1. SonarQube/SonarScanner

Resumen - SonarQube / SonarScanner

SonarQube es una plataforma de análisis de código que centraliza métricas de calidad y seguridad (bugs, vulnerabilidades, code smells, cobertura de tests, deuda técnica). El `sonar-scanner` es la herramienta cliente que envía el código y la configuración de análisis a un servidor SonarQube o SonarCloud.

Puntos clave:
- Alcance: multipropósito — detección de bugs, vulnerabilidades, code smells, reglas de calidad y cobertura.
- Integración: se integra fácilmente en CI/CD y soporta múltiples lenguajes mediante plugins.
- Fortalezas: panel centralizado con historial, métricas, reglas configurables y gestión por proyecto/developer.
- Limitaciones: puede producir falsos positivos; la calidad del análisis depende de las reglas activas y la configuración del proyecto (por ejemplo inclusiones/exclusiones, análisis incremental).

Buenas prácticas:
- Configura `sonar.projectKey` y propiedades por proyecto para obtener resultados consistentes.
- Evita enviar secretos en claro; usa tokens de análisis y almacénalos como variables seguras en tu CI.
- Revisa primero vulnerabilidades y issues de alta severidad; ajusta exclusiones y reglas para reducir ruido.


#### 1.1.1. Levantar SonarQube

**Linux/Mac:**

```bash
docker run -d --rm --name sonarqube -p 9000:9000 sonarqube:lts
# Espera 1 minuto antes de escanear (http://localhost:9000)
```

**Windows (PowerShell):**

```powershell
docker run -d --rm --name sonarqube -p 9000:9000 sonarqube:lts
# Espera 1 minuto antes de escanear (http://localhost:9000)
```

#### 1.1.2. Obtener TOKEN de SonarQube

1. Entrar a SonarQube en http://localhost:9000.

2. Loguearte con el usuario:

- Usuario: admin

- Contraseña: admin

  (Te pedirá cambiar la contraseña en el primer acceso. Guárdala bien.)

3. Ir a tu perfil (arriba a la derecha) > My Account > Security > Generate Tokens.

4. Crear un token (ejemplo: devsecops-lab), de tipo "Global Analysis Type".

5. Copiar ese token (¡no se puede recuperar después!).

6. En todos los comandos que usen SonarScanner, agrega la opción:

```
   -Dsonar.login=TU_TOKEN
```

#### 1.1.3. Escaneo con variantes

a) Escaneo default

Antes de ejecutar el comando asegúrate de clonar el repositorio del laboratorio y situarte en su raíz. Por ejemplo:

  ```bash
  git clone https://github.com/wils0n/juice-shop-devsecops
  cd juice-shop-devsecops
  ```

**Linux/Mac:**

```bash

export TOKEN=TU_TOKEN
docker run --rm -e SONAR_HOST_URL=http://host.docker.internal:9000 \
  -v "$(pwd)":/usr/src -v "$(pwd)/resultados":/resultados sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey=JuicyShopDevSecOpsDefault -Dsonar.sources=. \
  -Dsonar.issuesReport.json.enable=true \
  -Dsonar.login=$TOKEN
```

**Windows (PowerShell):**

```powershell
docker run --rm -e SONAR_HOST_URL=http://host.docker.internal:9000 `
  -v ${PWD}:/usr/src -v ${PWD}\resultados:/resultados sonarsource/sonar-scanner-cli `
  "-Dsonar.projectKey=JuicyShopDevSecOpsDefault" "-Dsonar.sources=." `
  "-Dsonar.issuesReport.json.enable=true" `
  "-Dsonar.login=TU_TOKEN"
```

#### Explicación del comando (Linux/Mac)

Breve desglose de lo que hace cada parte del ejemplo de Linux/Mac:

- `export TOKEN=TU_TOKEN`
  - Guarda el token de SonarQube en la variable de entorno `TOKEN` de tu shell. Es la credencial que se usará para autenticarse en SonarQube.

- `docker run --rm`:
  - Ejecuta la imagen `sonarsource/sonar-scanner-cli` y elimina el contenedor cuando termine (`--rm`).

- `-e SONAR_HOST_URL=http://host.docker.internal:9000`:
  - Pasa la URL del servidor SonarQube al contenedor como variable de entorno. `host.docker.internal` apunta a la máquina host desde Docker Desktop (macOS/Windows).

- `-v "$(pwd)":/usr/src`:
  - Monta el directorio actual dentro del contenedor en `/usr/src`. El scanner analizará ese path.

- `-v "$(pwd)/resultados":/resultados`:
  - Monta (o crea) una carpeta `resultados` local para volcar artefactos (JSON, HTML, SARIF) generados por el análisis.

- `sonarsource/sonar-scanner-cli`:
  - Imagen oficial que contiene la herramienta `sonar-scanner` lista para ejecutarse.

- `-Dsonar.projectKey=... -Dsonar.sources=. -D...`:
  - Propiedades que se pasan al scanner:
    - `sonar.projectKey`: clave del proyecto en SonarQube.
    - `sonar.sources=.`: ruta de las fuentes a analizar (aquí `.` dentro del contenedor).
    - `sonar.issuesReport.json.enable=true`: pedir que el scanner genere un reporte de issues en JSON.
    - `sonar.login=$TOKEN`: token de autenticación (la variable se expande en tu shell antes de ejecutar `docker`).

Notas y buenas prácticas:

- Seguridad del token:
  - Evita escribir el token en el historial del shell. En su lugar puedes leerlo de forma segura con `read -s TOKEN` o usar un archivo `.env` con permisos restringidos y pasar `--env-file .env` a `docker run`.
  - Si accidentalmente expones el token (por ejemplo en un repo), revócalo y crea uno nuevo.

- `host.docker.internal` en Linux:
  - En Docker Desktop (macOS/Windows) funciona; en Linux puede no existir por defecto. En ese caso usa la IP del host o configura la red (`--network host` o puente) según tu entorno.

- Resultados:
  - Cualquier artefacto que el scanner escriba en `/resultados` estará disponible en `$(pwd)/resultados` en tu máquina.

- Evitar exponer el token en los argumentos visibles:
  - Como alternativa a pasar `-Dsonar.login=$TOKEN` directamente, puedes exportar `SONAR_LOGIN` y usar un wrapper dentro del contenedor que lea la variable de entorno y la pase al scanner (evita que el token quede en el history del shell como argumento literal).


b) Filtrado por severidad (mayor/critical)

**Linux/Mac:**

```bash
export TOKEN=TU_TOKEN
docker run --rm -e SONAR_HOST_URL=http://host.docker.internal:9000 \
  -v "$(pwd)":/usr/src -v "$(pwd)/resultados":/resultados sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey=JuicyShopDevSecOpsSeverity -Dsonar.sources=. \
  -Dsonar.issuesReport.includeSeverity=MAJOR,CRITICAL \
  -Dsonar.issuesReport.json.enable=true \
  -Dsonar.login=$TOKEN
```

**Windows (PowerShell):**

```powershell
docker run --rm -e SONAR_HOST_URL=http://host.docker.internal:9000 `
  -v ${PWD}:/usr/src -v ${PWD}\resultados:/resultados sonarsource/sonar-scanner-cli `
  "-Dsonar.projectKey=JuicyShopDevSecOpsSeverity" "-Dsonar.sources=." `
  "-Dsonar.issuesReport.includeSeverity=MAJOR,CRITICAL" `
  "-Dsonar.issuesReport.json.enable=true" `
  "-Dsonar.login=TU_TOKEN"
```

c) Excluir tests

**Linux/Mac:**

```bash
export TOKEN=TU_TOKEN
docker run --rm -e SONAR_HOST_URL=http://host.docker.internal:9000 \
  -v "$(pwd)":/usr/src -v "$(pwd)/resultados":/resultados sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey=JuicyShopDevSecOpsExclude -Dsonar.sources=. \
  -Dsonar.exclusions="**/test/**" \
  -Dsonar.login=$TOKEN \
  -Dsonar.issuesReport.json.enable=true
```

**Windows (PowerShell):**

```powershell
docker run --rm -e SONAR_HOST_URL=http://host.docker.internal:9000 `
  -v ${PWD}:/usr/src -v ${PWD}\resultados:/resultados sonarsource/sonar-scanner-cli `
  "-Dsonar.projectKey=JuicyShopDevSecOpsExclude" "-Dsonar.sources=." `
  "-Dsonar.exclusions=**/test/**" `
  "-Dsonar.login=TU_TOKEN" `
  "-Dsonar.issuesReport.json.enable=true"
```

### 1.2. Semgrep

Resumen - Semgrep

Semgrep es una herramienta de análisis estático basada en patrones que soporta múltiples lenguajes (JavaScript, Python, Java, Go, etc.). Permite usar reglas preconstruidas (incluyendo colecciones OWASP) o crear reglas personalizadas en una sintaxis sencilla.

Puntos clave:
- Lenguajes: multi-lenguaje (muy útil en repositorios con stacks mixtos).
- Uso: muy rápida, fácil de configurar en CI, puede ejecutar reglas locales o usar las reglas públicas/privadas de Semgrep registry.
- Fortalezas: alta customización, buena para detectar patrones lógicos complejos, exporta JSON y SARIF para integraciones con otras herramientas.
- Limitaciones: requiere afinamiento de reglas para evitar ruido; las reglas personalizadas necesitan validación y mantenimiento.

Cómo interpretar resultados:
- Prioriza hallazgos con severidad alta/ERROR y adapta las reglas para el contexto del proyecto. Exporta SARIF si quieres integrarlo con plataformas que consumen ese formato.


a) Default

**Linux/Mac:**

```bash
docker run --rm -v "$(pwd)":/src -v "$(pwd)/resultados":/resultados returntocorp/semgrep semgrep \
  --config auto /src --json --output /resultados/semgrep-default.json
```

**Windows (PowerShell):**

```powershell
docker run --rm -v ${PWD}:/src -v ${PWD}\resultados:/resultados returntocorp/semgrep semgrep `
  --config auto /src --json --output /resultados/semgrep-default.json
```

b) Solo severidad crítica

**Linux/Mac:**

```bash
docker run --rm -v "$(pwd)":/src -v "$(pwd)/resultados":/resultados returntocorp/semgrep semgrep \
  --config auto --severity ERROR /src --json --output /resultados/semgrep-high.json
```

**Windows (PowerShell):**

```powershell
docker run --rm -v ${PWD}:/src -v ${PWD}\resultados:/resultados returntocorp/semgrep semgrep `
  --config auto --severity ERROR /src --json --output /resultados/semgrep-high.json
```

c) OWASP Top Ten rules

**Linux/Mac:**

```bash
docker run --rm -v "$(pwd)":/src -v "$(pwd)/resultados":/resultados returntocorp/semgrep semgrep \
  --config "p/owasp-top-ten" /src --json --output /resultados/semgrep-owasp.json
```

**Windows (PowerShell):**

```powershell
docker run --rm -v ${PWD}:/src -v ${PWD}\resultados:/resultados returntocorp/semgrep semgrep `
  --config "p/owasp-top-ten" /src --json --output /resultados/semgrep-owasp.json
```

d) Formato SARIF

**Linux/Mac:**

```bash
docker run --rm -v "$(pwd)":/src -v "$(pwd)/resultados":/resultados returntocorp/semgrep semgrep \
  --config auto /src --sarif --output /resultados/semgrep-sarif.sarif
```

**Windows (PowerShell):**

```powershell
docker run --rm -v ${PWD}:/src -v ${PWD}\resultados:/resultados returntocorp/semgrep semgrep `
  --config auto /src --sarif --output /resultados/semgrep-sarif.sarif
```

e) Excluyendo carpeta de tests

**Linux/Mac:**

```bash
docker run --rm -v "$(pwd)":/src -v "$(pwd)/resultados":/resultados returntocorp/semgrep semgrep \
  --config auto --exclude /src/tests/ /src --json --output /resultados/semgrep-exclude-tests.json
```

**Windows (PowerShell):**

```powershell
docker run --rm -v ${PWD}:/src -v ${PWD}\resultados:/resultados returntocorp/semgrep semgrep `
  --config auto --exclude /src/tests/ /src --json --output /resultados/semgrep-exclude-tests.json
```

---