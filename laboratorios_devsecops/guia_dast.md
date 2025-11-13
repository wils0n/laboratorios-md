# Guía de Laboratorio: Análisis Dinámico de Seguridad de Aplicaciones (DAST) con OWASP ZAP


**Duración estimada:** 90–120 min

**Nivel:** Intermedio

**Contexto:** Este laboratorio se enfoca en aplicar técnicas de **Análisis Dinámico de Seguridad de Aplicaciones (DAST)** sobre una aplicación web vulnerable, **OWASP Juicy Shop**. Aprenderás a utilizar **OWASP ZAP (Zed Attack Proxy)** desde Docker para simular ataques, identificar vulnerabilidades en tiempo de ejecución y generar reportes de seguridad.

---

## 🎯 Objetivos de aprendizaje

- Ejecutar análisis DAST pasivos y activos utilizando **OWASP ZAP**.
- Identificar vulnerabilidades comunes como **SQL Injection (SQLi)**, **Cross-Site Scripting (XSS)** y **Broken Authentication**.
- Generar y exportar reportes de vulnerabilidades en múltiples formatos (HTML, XML, SARIF).
- Interpretar los resultados de un escaneo DAST y relacionarlos con el **OWASP Top Ten**.
- Automatizar un escaneo DAST básico dentro de un pipeline de **GitLab CI/CD**.

---

## 🧩 Requisitos previos

✅ Docker Desktop instalado y corriendo. 

✅ La aplicación **OWASP Juicy Shop** disponible y ejecutándose (puedes usar `docker run --rm -p 3000:3000 bkimminich/juice-shop`). 

✅ Conocimientos básicos sobre vulnerabilidades web (OWASP Top Ten). 

✅ Conectividad a Internet para descargar la imagen de OWASP ZAP. 

> **Importante:** Antes de cada comando, asegúrate de que Juicy Shop esté corriendo y accesible en `http://localhost:3000`. Para los comandos Docker, ZAP necesita conectarse a la aplicación host, por lo que se usa `http://host.docker.internal:3000`.

---

## Parte 1: Análisis Pasivo (Baseline Scan)

Un análisis pasivo inspecciona las respuestas HTTP en busca de vulnerabilidades sin enviar payloads maliciosos. Es ideal para crear una línea base de seguridad.

### 1.1. Análisis baseline sin login

Este comando escanea la página principal de la aplicación.

**Linux/Mac:**
```bash
docker run --rm -v "$(pwd)/zap-report":/zap/wrk/:rw zaproxy/zap-stable:latest \
  zap-baseline.py -t http://host.docker.internal:3000 -r /zap-default.html
```

**Windows (PowerShell):**
```powershell
docker run --rm -v ${PWD}\zap-report:/zap/wrk/:rw zaproxy/zap-stable:latest `
  zap-baseline.py -t http://host.docker.internal:3000 -r /zap-default.html
```

### 1.2. Análisis de la página de login

Este análisis se enfoca específicamente en la página de autenticación para detectar posibles debilidades.

**Linux/Mac:**
```bash
docker run --rm -v "$(pwd)/zap-report":/zap/wrk/:rw zaproxy/zap-stable:latest \
  zap-baseline.py -t http://host.docker.internal:3000/#/login -r /zap-login.html
```

**Windows (PowerShell):**
```powershell
docker run --rm -v ${PWD}\zap-report:/zap/wrk/:rw zaproxy/zap-stable:latest `
  zap-baseline.py -t http://host.docker.internal:3000/#/login -r /zap-login.html
```

---

## Parte 2: Análisis Activo (Active Scan)

Un análisis activo simula ataques reales contra la aplicación, enviando payloads para descubrir vulnerabilidades más profundas.

### 2.1. Ataque activo estándar

Este comando ejecuta un escaneo completo que busca un amplio rango de vulnerabilidades.

**Linux/Mac:**
```bash
docker run --rm -v "$(pwd)/zap-report":/zap/wrk/:rw zaproxy/zap-stable:latest \
  zap-full-scan.py -t http://host.docker.internal:3000 -r /zap-fullscan.html
```

**Windows (PowerShell):**
```powershell
docker run --rm -v ${PWD}\zap-report:/zap/wrk/:rw zaproxy/zap-stable:latest `
  zap-full-scan.py -t http://host.docker.internal:3000 -r /zap-fullscan.html
```

### 2.2. Ataque dirigido a endpoints específicos

Es una buena práctica enfocar los ataques en endpoints que son propensos a ciertas vulnerabilidades como SQLi o XSS.

**Linux/Mac:**
```bash
docker run --rm -v "$(pwd)/zap-report":/zap/wrk/:rw zaproxy/zap-stable:latest \
  zap-full-scan.py -t http://host.docker.internal:3000/rest/products/search -r /zap-sqli-xss.html
```

**Windows (PowerShell):**
```powershell
docker run --rm -v ${PWD}\zap-report:/zap/wrk/:rw zaproxy/zap-stable:latest `
  zap-full-scan.py -t http://host.docker.internal:3000/rest/products/search -r /zap-sqli-xss.html
```

**Otras rutas sugeridas para pruebas específicas:**
- `/rest/user/login` (Broken Authentication)
- `/rest/user/reset-password` (Sensitive Data Exposure)
- `/rest/products/reviews` (XSS, CSRF)
- `/public/images` (Directory Traversal, Sensitive Data Exposure)

---

## Parte 3: Gestión de Reportes

Generar reportes en formatos estándar es clave para integrar DAST en el ciclo de vida de desarrollo.

### 3.1. Exportando en múltiples formatos (HTML, XML, SARIF)

**Linux/Mac:**
```bash
docker run --rm -v "$(pwd)/zap-report":/zap/wrk/:rw zaproxy/zap-stable:latest \
  zap-baseline.py -t http://host.docker.internal:3000 \
  -r /zap-export.html -x /zap-export.xml -w /zap-export.sarif
```

**Windows (PowerShell):**
```powershell
docker run --rm -v ${PWD}\zap-report:/zap/wrk/:rw zaproxy/zap-stable:latest `
  zap-baseline.py -t http://host.docker.internal:3000 `
  -r /zap-export.html -x /zap-export.xml -w /zap-export.sarif
```

### 3.2. Visualización y revisión de resultados

- Abre los archivos HTML (`zap-default.html`, `zap-fullscan.html`, etc.) en tu navegador para un análisis visual.
- Importa los archivos XML o SARIF a herramientas como **DefectDojo**, **VSCode (con extensiones de seguridad)** o **GitLab Security Dashboards** para una gestión centralizada.
- Compara los hallazgos con el **[OWASP Top Ten](https://owasp.org/www-project-top-ten/)** para priorizar la remediación.

---

## Parte 4: Automatización con GitLab CI/CD

Integrar DAST en el pipeline de CI/CD permite detectar vulnerabilidades de forma temprana y automática.

**Archivo:** `.gitlab-ci.yml` (ejemplo de un job DAST)

```yaml
stages:
  - dast_review

# Escaneo DAST con OWASP ZAP
zap_scan:
  stage: dast_review
  image: docker:latest
  services: [docker:dind]
  variables:
    DOCKER_DRIVER: overlay2
  script:
    # 1. Crear una red para comunicar los contenedores
    - docker network create zap-net
    # 2. Levantar la aplicación a escanear en la red creada
    - docker run -d --name webapp-zap --network zap-net -p 3000:3000 bkimminich/juice-shop
    # 3. Esperar a que la aplicación esté lista (ajustar tiempo si es necesario)
    - sleep 30
    # 4. Crear directorio para los reportes y darle permisos
    - mkdir -p zap-report && chmod 777 zap-report
    # 5. Ejecutar el escaneo ZAP Baseline
    - |
      docker run --rm --network zap-net \
        -v "$PWD/zap-report:/zap/wrk:rw" \
        zaproxy/zap-stable:latest \
        zap-baseline.py \
          -t http://webapp-zap:3000 \
          -r zap-default.html \
          -J zap-result.json || true
    # 6. Verificar que los reportes se generaron
    - ls -la zap-report/
    # 7. Limpiar el entorno
    - docker stop webapp-zap || true
    - docker rm webapp-zap || true
    - docker network rm zap-net || true
  artifacts:
    paths:
      - zap-report/
    expire_in: 1 week
    when: always
  allow_failure: true
```

---

## ✅ Checklist de Éxito

- [ ] Ejecutado un análisis pasivo y uno activo contra Juicy Shop.
- [ ] Generado al menos un reporte en formato HTML y visualizado en el navegador.
- [ ] Identificado al menos 3 tipos de vulnerabilidades diferentes en los reportes.
- [ ] Comprendido el propósito de los scripts `zap-baseline.py` y `zap-full-scan.py`.
- [ ] Configurado y ejecutado exitosamente el job `zap_scan` en un pipeline de GitLab CI/CD.

---

## 📘 Entregables

1.  **Carpeta de reportes** (`zap-report/`) con al menos dos reportes (ej. `zap-default.html` y `zap-login.html`).
2.  **Capturas de pantalla** de:
    -   La ejecución de un comando de análisis activo en la terminal.
    -   El reporte HTML de ZAP mostrando las vulnerabilidades encontradas.
    -   El pipeline de GitLab CI/CD ejecutando el job `zap_scan`.
3.  **Documento de reflexión**:
    -   ¿Cuál es la diferencia clave entre un análisis pasivo y uno activo? ¿Cuándo usarías cada uno?
    -   Menciona dos vulnerabilidades críticas que encontraste y explica brevemente su riesgo.

---

**Autor:** Wilson Julca Mejía
Curso: *DevSecOps y Seguridad en CI/CD – UTEC*
Universidad de Ingeniería y Tecnología (UTEC)

