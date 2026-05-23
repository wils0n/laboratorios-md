# Laboratorio: CI/CD en Bitbucket Pipelines - Despliegue a AWS Lambda con Serverless Framework v4

**Duración estimada:** 120–150 min  
**Nivel:** Intermedio–Avanzado  
**Contexto:** Este laboratorio es la versión Bitbucket del flujo de CI/CD visto en la guia_introduccion.md. Aprenderás a desplegar automáticamente una API Next.js a AWS Lambda usando Serverless Framework v4 desde un pipeline Bitbucket Pipelines con lint, tests, build, cache y aprobación manual.

---

## Objetivos de aprendizaje

- Crear un pipeline CI/CD en Bitbucket para aplicaciones Node.js
- Crear una API REST con Next.js (API Routes)
- Escribir un handler Lambda directo que expone una API Route de Next.js
- Escribir un handler Lambda compatible con API Gateway v2
- Configurar Serverless Framework v4 con `serverless.yml`
- Desplegar una aplicación Next.js a AWS Lambda desde el pipeline
- Configurar variables seguras (credenciales AWS) en Bitbucket Pipelines
- Usar cache de pipeline (npm) para acelerar ejecuciones
- Pasar artifacts entre steps
- Ejecutar steps en paralelo con `parallel:`
- Usar `branches:` y `pull-requests:` para controlar cuándo corre cada pipeline
- Implementar deploy con aprobación manual (`trigger: manual`)

---

## Requisitos previos

✅ Cuenta en Bitbucket ([https://bitbucket.org/](https://bitbucket.org/))  
✅ Cuenta en AWS con permisos para Lambda, API Gateway, IAM y CloudFormation  
✅ Cuenta en Serverless Framework ([https://app.serverless.com/](https://app.serverless.com/)) — requerida por v4  
✅ Repositorio en Bitbucket con Pipelines habilitado  
✅ Node.js 20+ instalado localmente

---

## Estructura del proyecto

```
bitbucket_lambda_demo/
├── bitbucket-pipelines.yml     # Pipeline principal de CI/CD
├── handler.js                  # Handler Lambda (función directa, sin servidor Next.js)
├── next.config.js              # Configuración de Next.js
├── jest.config.js              # Configuración de Jest
├── .eslintrc.json              # Configuración de ESLint
├── pages/
│   └── api/
│       └── hello.js            # API Route: GET /api/hello
├── __tests__/
│   └── hello.test.js           # Tests unitarios
├── serverless.yml              # Configuración de Serverless Framework
├── package.json                # Dependencias y scripts
└── README.md
```

---

## Parte 1: Aplicación Next.js

### 1.1 API Route

Next.js expone funciones de backend como **API Routes** en la carpeta `pages/api/`. Cada archivo se convierte en un endpoint HTTP independiente. En Lambda, cada API Route es una función que recibe un objeto `req` (request) y `res` (response).

**Archivo: `pages/api/hello.js`**

```javascript
export default function handler(req, res) {
  const { name = 'World' } = req.query;
  res.status(200).json({ message: `Hello, ${name}!`, source: 'Next.js' });
}
```

Esta función:
- Lee el parámetro `name` de la query string (`?name=UTEC`)
- Devuelve un JSON con el saludo y la fuente (`Next.js`)
- Es fácilmente testeable de forma unitaria sin necesitar un servidor real

### 1.2 `package.json`

Separa dependencias de producción (`dependencies`) y desarrollo (`devDependencies`). Serverless Framework excluye automáticamente las `devDependencies` del ZIP que sube a Lambda.

**Archivo: `package.json`**

```json
{
  "name": "bitbucket-lambda-demo",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "test": "jest --coverage",
    "lint": "eslint pages/ handler.js --max-warnings=0"
  },
  "dependencies": {
    "next": "^14.2.3",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "eslint": "^8.57.0",
    "eslint-config-next": "^14.2.3",
    "jest": "^29.7.0",
    "jest-environment-node": "^29.7.0",
    "jest-junit": "^16.0.0",
    "serverless": "^4.0.0"
  },
  "jest-junit": {
    "outputDirectory": ".",
    "outputName": "report.xml"
  }
}
```

**Dependencias de producción (para `next dev`, `next build`, `next start`):**

| Paquete | Rol |
|---------|-----|
| `next` | Framework — compila y sirve la app en local |
| `react` / `react-dom` | Requerido por Next.js |

> Ninguna de estas dependencias va al ZIP de Lambda. `handler.js` es una función pura sin `require()` — el paquete Lambda pesa ~1 KB.

**Dependencias de desarrollo (solo en CI/CD):**

| Paquete | Rol |
|---------|-----|
| `eslint` + `eslint-config-next` | Linter |
| `jest` + `jest-environment-node` | Runner de tests |
| `jest-junit` | Genera `report.xml` (formato JUnit) para Bitbucket |
| `serverless` | Deploy a AWS Lambda |

### 1.3 `next.config.js`

**Archivo: `next.config.js`**

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {};

module.exports = nextConfig;
```

### 1.4 `.eslintrc.json`

**Archivo: `.eslintrc.json`**

```json
{
  "extends": ["next/core-web-vitals"],
  "env": {
    "node": true,
    "jest": true
  }
}
```

Correr localmente:
```bash
npm install
npm run dev
# GET http://localhost:3000/api/hello?name=UTEC
```

---

## Parte 2: Handler Lambda

### 2.1 Por qué no usamos el servidor Next.js en Lambda

Ejecutar el servidor completo de Next.js en Lambda presenta dos problemas:

1. **Tamaño:** `node_modules/next` completo pesa ~260 MB descomprimido — supera el límite de 250 MB de Lambda
2. **Dependencias faltantes:** el bundle mínimo que genera `output: 'standalone'` omite webpack (`bundle5`), pero el código de inicialización de `next()` aún lo requiere → error en runtime

La solución correcta para producción es [OpenNext](https://opennext.js.org/), un wrapper especialmente diseñado para Next.js en Lambda. Para este laboratorio — cuyo objetivo es CI/CD, no la arquitectura Lambda avanzada — usamos un **handler directo**: la API Route de Next.js es una función pura, la reimplementamos en el formato de evento de API Gateway.

```
API Gateway → evento Lambda → handler.js → respuesta JSON
```

**Archivo: `handler.js`**

```javascript
// Lambda handler para /api/hello
// La API Route de Next.js es una función pura (req, res) => void.
// En Lambda, traducimos el evento de API Gateway directamente — sin servidor Next.js.
exports.handler = async (event) => {
  const name = event.queryStringParameters?.name || 'World';
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: `Hello, ${name}!`, source: 'Next.js' }),
  };
};
```

**Ventajas para el laboratorio:**

| Aspecto | Resultado |
|---------|-----------|
| Tamaño del ZIP | ~1 KB (solo `handler.js`, sin `node_modules`) |
| Dependencias en Lambda | Ninguna |
| Cold start | Instantáneo |
| Next.js en CI/CD | Build, lint y tests siguen corriendo normalmente |

> El pipeline ejecuta `npm run build` (valida que el app compila), `npm run lint` (ESLint sobre código Next.js) y `npm test` (Jest sobre la API Route). Solo el runtime en Lambda es un handler directo sin el servidor Next.js.

---

## Parte 3: Tests con Jest

### 3.1 Configuración de Jest

Next.js requiere que Jest use su transformador (SWC) para procesar el código. El preset `next/jest` configura esto automáticamente.

**Archivo: `jest.config.js`**

```javascript
const nextJest = require('next/jest');

// Crea la configuración de Jest con el transformador de Next.js
const createJestConfig = nextJest({ dir: './' });

module.exports = createJestConfig({
  testEnvironment: 'node',
  reporters: ['default', 'jest-junit'],
  collectCoverageFrom: ['pages/api/**/*.js'],
});
```

- `testEnvironment: 'node'`: las API Routes son código Node.js, no código de browser
- `reporters: ['default', 'jest-junit']`: genera `report.xml` en formato JUnit que Bitbucket muestra en la UI
- `collectCoverageFrom`: limita la cobertura a la carpeta de API Routes

### 3.2 Tests unitarios

Los tests de las API Routes no necesitan un servidor real. Se invoca el handler directamente con objetos `req` y `res` simulados (mocks).

**Archivo: `__tests__/hello.test.js`**

```javascript
import handler from '../pages/api/hello';

function mockRes() {
  return {
    status: jest.fn().mockReturnThis(),
    json: jest.fn(),
  };
}

test('retorna saludo por defecto cuando no hay query param', () => {
  const req = { query: {} };
  const res = mockRes();
  handler(req, res);
  expect(res.status).toHaveBeenCalledWith(200);
  expect(res.json).toHaveBeenCalledWith({ message: 'Hello, World!', source: 'Next.js' });
});

test('retorna saludo personalizado con query param name', () => {
  const req = { query: { name: 'UTEC' } };
  const res = mockRes();
  handler(req, res);
  expect(res.status).toHaveBeenCalledWith(200);
  expect(res.json).toHaveBeenCalledWith({ message: 'Hello, UTEC!', source: 'Next.js' });
});
```

**¿Por qué no `supertest`?**

Las API Routes de Next.js son funciones puras `(req, res) => void`. No necesitan un servidor HTTP para ser testeadas — se invocan directamente con objetos mock. Esto hace los tests más rápidos y sin dependencias externas. `supertest` sería necesario si quisieras testear el servidor completo (pruebas de integración).

Correr los tests localmente:
```bash
npm test
# Genera: report.xml  (JUnit)
#         coverage/   (HTML + LCOV)
```

---

## Parte 4: Configuración de Serverless Framework v4

### 4.1 `serverless.yml`

**Archivo: `serverless.yml`**

```yaml
service: bitbucket-lambda-demo
frameworkVersion: '4'

provider:
  name: aws
  runtime: nodejs20.x
  region: ${env:AWS_DEFAULT_REGION, "us-east-1"}
  stage: ${opt:stage, "dev"}
  environment:
    STAGE: ${sls:stage}
    NODE_ENV: production

package:
  # handler.js no usa node_modules — el ZIP es solo el handler (~1 KB)
  patterns:
    - '!node_modules/**'
    - '!.next/**'
    - '!pages/**'
    - '!__tests__/**'
    - '!coverage/**'
    - '!report.xml'
    - '!jest.config.js'
    - '!next.config.js'
    - '!.eslintrc.json'
    - '!package*.json'

functions:
  app:
    handler: handler.handler
    description: "API Next.js desplegada desde Bitbucket Pipelines"
    events:
      - httpApi:
          path: /api/hello
          method: GET
```

**Campos clave:**

| Campo | Descripción |
|-------|-------------|
| `runtime: nodejs20.x` | Runtime Lambda — coincide con la imagen Docker del pipeline |
| `patterns: !node_modules/**` | Excluye dependencias — `handler.js` no tiene imports externos |
| `httpApi: /api/hello` | Crea un API Gateway v2 HTTP endpoint apuntando a Lambda |
| `handler: handler.handler` | Exportación `exports.handler` del archivo `handler.js` |

### 4.2 Validación local

Para desarrollo local usa `next dev` — la API Route de Next.js y el handler Lambda comparten la misma lógica:

```bash
npm install
npm run dev
# GET http://localhost:3000/api/hello?name=UTEC
```

Para ejecutar los tests unitarios (no necesita servidor ni build):
```bash
npm test
# Testea pages/api/hello.js directamente sin levantar Next.js
```

---

## Parte 5: Configuración de credenciales

Necesitas tres tipos de credenciales: una para Serverless Framework, dos para AWS.

### 5.1 Obtener `SERVERLESS_ACCESS_KEY`

Serverless Framework v4 requiere autenticación con una cuenta Serverless. En CI/CD se usa una Access Key en lugar del login interactivo.

1. Ve a [app.serverless.com](https://app.serverless.com/) y crea una cuenta (plan gratuito disponible)
2. Clic en tu perfil (esquina superior derecha) → **Settings**
3. Sección **Access Keys → Create**
4. Nómbrala `bitbucket-ci` → clic en **Create**
5. Copia el token generado — **solo se muestra una vez**

> Sin esta key, Serverless v4 intenta un login interactivo en el pipeline y el step falla.

### 5.2 Obtener `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`

**Crear el usuario IAM:**

1. Ve a AWS Console → **IAM → Users → Create user**
2. Nómbralo `bitbucket-ci-deployer` → clic en **Next**
3. Selecciona **Attach policies directly** y agrega:
   - `AWSLambda_FullAccess`
   - `AmazonAPIGatewayAdministrator`
   - `AWSCloudFormationFullAccess`
   - `IAMFullAccess`
   - `AmazonS3FullAccess`
4. Clic en **Create user**

**Generar las credenciales:**

1. Abre el usuario `bitbucket-ci-deployer` → pestaña **Security credentials**
2. Sección **Access keys → Create access key**
3. Selecciona **Command Line Interface (CLI)** como caso de uso
4. Copia `Access key ID` y `Secret access key` — **solo se muestran una vez**

### 5.3 Agregar las variables en Bitbucket Pipelines

Bitbucket ofrece dos niveles: **Repository variables** (todos los steps) y **Deployment variables** (solo steps con `deployment: <entorno>`).

#### Variables de repositorio (globales)

**Repository settings → Pipelines → Repository variables:**

| Variable                | Valor                              | Secured |
|-------------------------|------------------------------------|---------|
| `SERVERLESS_ACCESS_KEY` | token de app.serverless.com        | Sí      |
| `AWS_DEFAULT_REGION`    | ej. `us-east-1`                    | No      |

#### Variables de despliegue (entorno `production`)

**Repository settings → Pipelines → Deployments → production → Add variable:**

| Variable                | Valor                              | Secured |
|-------------------------|------------------------------------|---------|
| `AWS_ACCESS_KEY_ID`     | Access key del usuario IAM         | Sí      |
| `AWS_SECRET_ACCESS_KEY` | Secret access key del usuario IAM  | Sí      |

> Las Deployment variables solo se inyectan en steps con `deployment: production`, limitando la exposición de credenciales al único step que realmente despliega.

**¿Cómo llegan al pipeline?**

```
Bitbucket Repository Variables → todos los steps
  └─ SERVERLESS_ACCESS_KEY  → Serverless Framework
  └─ AWS_DEFAULT_REGION     → AWS SDK

Bitbucket Deployment Variables → step con deployment: production
  └─ AWS_ACCESS_KEY_ID      → AWS SDK credential chain
  └─ AWS_SECRET_ACCESS_KEY  → AWS SDK credential chain
```

---

## Parte 6: Pipeline completo `bitbucket-pipelines.yml`

El pipeline lint y test corren en paralelo (bloque `parallel:`), seguidos del stage `deploy` con aprobación manual.

```
lint + test (en paralelo) → deploy stage (build + deploy_aws - manual)
```

**Archivo: `bitbucket-pipelines.yml`**

```yaml
image: node:20

definitions:
  caches:
    npm-cache: node_modules

pipelines:
  # ── Rama principal ────────────────────────────────────────────────
  branches:
    main:
      - parallel:
          - step:
              name: lint
              caches:
                - npm-cache
              script:
                - npm ci
                - npm run lint

          - step:
              name: test
              caches:
                - npm-cache
              script:
                - npm ci
                - npm test
              artifacts:
                - report.xml
                - coverage/**

      - stage:
          name: deploy
          trigger: manual
          steps:
            - step:
                name: deploy_aws
                caches:
                  - npm-cache
                deployment: production
                script:
                  - npm ci
                  - npm run build
                  - npx serverless deploy --stage production --verbose

  # ── Pull Requests ─────────────────────────────────────────────────
  pull-requests:
    "**":
      - parallel:
          - step:
              name: lint
              caches:
                - npm-cache
              script:
                - npm ci
                - npm run lint

          - step:
              name: test
              caches:
                - npm-cache
              script:
                - npm ci
                - npm test
              artifacts:
                - report.xml
                - coverage/**
```

---

## Parte 7: Conceptos clave del pipeline

### 7.1 Por qué `npm run build` está en el step de deploy (no en validate)

El build de Next.js (`.next/`) puede pesar varios MB. Moverlo como artifact entre stages sería lento. En cambio, el step `deploy_aws` hace el build y el deploy en el mismo contenedor: los archivos no salen del filesystem del runner.

```
validate:              deploy_aws:
  lint  │  test          npm ci → npm run build → serverless deploy
        │                               ↑
        │                    .next/ generado aquí mismo
```

Si el build fallara en deploy sin haberse validado antes con `npm run build` localmente, el deploy simplemente no correría. El orden de stages garantiza que lint y tests pasan primero.

### 7.2 Tipos de trigger: `branches:` vs `pull-requests:`

```yaml
pipelines:
  branches:
    main:          # push a main → validate + deploy (manual)
  pull-requests:
    "**":          # cualquier PR → validate (sin deploy)
```

Los PRs nunca disparan el deploy — solo la rama `main` lo hace. Esto garantiza que el deploy a producción solo ocurre desde código ya mergeado y revisado.

**Equivalencia con GitLab CI:**

| GitLab CI | Bitbucket Pipelines |
|-----------|---------------------|
| `if: '$CI_COMMIT_BRANCH == "main"'` | `branches: main:` |
| `if: '$CI_PIPELINE_SOURCE == "merge_request_event"'` | `pull-requests: "**":` |
| `when: manual` | `trigger: manual` |

### 7.3 Steps en paralelo con `parallel:`

En GitLab CI, dos jobs en el mismo stage corren en paralelo automáticamente. En Bitbucket, el paralelismo debe declararse explícitamente con `parallel:` al mismo nivel que `step:` o `stage:` en la lista del pipeline:

```yaml
- parallel:           # mismo nivel que step:/stage: — no dentro de stage > steps
    - step:
        name: lint
    - step:
        name: test
- stage:              # corre después de que parallel termine
    name: deploy
    steps:
      - step:
          name: deploy_aws
```

```
  ┌──────────┐  ┌──────────┐
  │   lint   │  │   test   │   ← corren al mismo tiempo (parallel:)
  └──────────┘  └──────────┘
        ↓
  ┌──────────────────────────┐
  │       deploy_aws         │   ← corre después (stage: deploy)
  └──────────────────────────┘
```

> `parallel:` dentro de `stage > steps` **no está soportado** por Bitbucket Pipelines. Si quieres agrupación visual (stages) Y paralelismo, usa `parallel:` a nivel de pipeline y `stage:` solo donde el paso es secuencial.

### 7.4 Cache de npm

```yaml
definitions:
  caches:
    npm-cache: node_modules   # directorio a persistir

- step:
    caches:
      - npm-cache             # referencia por nombre
```

- `node_modules/` se guarda entre ejecuciones del pipeline.
- Bitbucket invalida el cache automáticamente cuando detecta cambios en `package-lock.json`.
- Cada step que usa `npm ci` puede restaurar el cache en lugar de descargar todo desde npm.

> **Diferencia con GitLab CI:** GitLab necesita un `key: "$CI_COMMIT_REF_SLUG-npm"` explícito para scopear el cache por rama. Bitbucket gestiona el scope por rama automáticamente.

### 7.5 `trigger: manual` y Deployment variables

`trigger: manual` va en el **`stage:`**, no en el `step:` dentro del stage — Bitbucket no permite el trigger en steps individuales dentro de un stage:

```yaml
- stage:
    name: deploy
    trigger: manual          # ← en el stage, no en el step
    steps:
      - step:
          name: deploy_aws
          deployment: production   # inyecta Deployment variables del entorno "production"
          script:
            - npx serverless deploy --stage production --verbose
```

- El stage aparece en el pipeline con un botón **Run** — un humano debe aprobarlo.
- `deployment: production` tiene dos efectos:
  1. Marca el step en el historial de **Deployments** de Bitbucket
  2. Inyecta las variables configuradas en el entorno `production` (AWS credentials)

### 7.6 Variables predefinidas de Bitbucket

| Variable | Descripción | Equivalente GitLab |
|----------|-------------|-------------------|
| `$BITBUCKET_BRANCH` | Rama actual | `$CI_COMMIT_BRANCH` |
| `$BITBUCKET_COMMIT` | SHA completo del commit | `$CI_COMMIT_SHA` |
| `$BITBUCKET_BUILD_NUMBER` | Número incremental del build | `$CI_PIPELINE_IID` |
| `$BITBUCKET_REPO_SLUG` | Nombre del repositorio | `$CI_PROJECT_NAME` |
| `$BITBUCKET_WORKSPACE` | Workspace (organización/usuario) | `$CI_PROJECT_NAMESPACE` |
| `$BITBUCKET_CLONE_DIR` | Directorio raíz del proyecto | `$CI_PROJECT_DIR` |
| `$BITBUCKET_PR_ID` | ID del Pull Request | `$CI_MERGE_REQUEST_IID` |

### 7.7 Serverless Framework v4: flujo de despliegue con Next.js

Cuando `npx serverless deploy` corre en el pipeline, ejecuta estos pasos internamente:

```
1. Lee serverless.yml
2. Aplica package.patterns — excluye node_modules/**, .next/**, pages/**, etc.
3. Empaqueta solo handler.js → ZIP ~1 KB (sin dependencias externas)
4. Genera template CloudFormation
5. Sube el ZIP del código a un bucket S3 (creado automáticamente)
6. Crea/actualiza el stack CloudFormation en AWS:
   ├── AWS::Lambda::Function       (la función Node.js)
   ├── AWS::ApiGatewayV2::Api      (el endpoint HTTP)
   └── AWS::IAM::Role              (permisos de ejecución de Lambda)
7. Imprime el endpoint URL generado
```

**Variables de entorno que Serverless v4 lee automáticamente:**

```
SERVERLESS_ACCESS_KEY   → autenticación con app.serverless.com
AWS_ACCESS_KEY_ID       → credencial IAM
AWS_SECRET_ACCESS_KEY   → credencial IAM
AWS_DEFAULT_REGION      → región de despliegue
```

---

## Parte 8: Probar el pipeline

### 8.1 Habilitar Pipelines en el repositorio

1. Ve a tu repositorio → **Repository settings**
2. En el menú lateral → **Pipelines → Settings**
3. Activa el toggle **Enable Pipelines**

### 8.2 Push inicial

```bash
git add bitbucket-pipelines.yml handler.js next.config.js jest.config.js \
        .eslintrc.json serverless.yml package.json pages/ __tests__/
git commit -m "feat: pipeline Bitbucket CI con despliegue de Next.js a AWS Lambda"
git push origin main
```

### 8.3 Observar la ejecución

1. Ve a **Pipelines** en tu repositorio de Bitbucket.
2. Observa el stage `validate` — `lint` y `test` corren en paralelo.
3. El step `deploy_aws` aparece en el stage `deploy` con el botón **Run** — haz clic para ejecutarlo manualmente.
4. En los logs verás el stack CloudFormation creándose y al final el endpoint:

```
endpoints:
  GET - https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/api/hello
```

5. Prueba el endpoint:

```bash
curl "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/api/hello?name=UTEC"
# {"message": "Hello, UTEC!", "source": "Next.js"}
```

### 8.4 Probar localmente antes del pipeline

**Opción A — Next.js dev server:**
```bash
npm install
npm run dev
curl "http://localhost:3000/api/hello?name=local"
```

**Opción B — tests unitarios:**
```bash
npm test
# No necesita servidor ni build — testea el handler directamente
```

### 8.5 Crear un Pull Request para ver artifacts en acción

```bash
git checkout -b feature/nueva-funcionalidad
# modifica pages/api/hello.js o __tests__/hello.test.js
git add .
git commit -m "feat: nueva funcionalidad"
git push origin feature/nueva-funcionalidad
```

Crea un PR en Bitbucket. El pipeline de `pull-requests: "**":` ejecuta `lint` y `test` en paralelo. En el PR verás:
- Estado del pipeline (verde/rojo) directamente en la vista del PR
- Artifacts `report.xml` y `coverage/` descargables desde la UI del pipeline

---

## Parte 9: Buenas prácticas y troubleshooting

| Problema | Causa probable | Solución |
|----------|---------------|----------|
| Pipeline no se dispara | Pipelines no habilitado | Repository settings → Pipelines → Settings → Enable |
| `deploy_aws` falla con `AccessDenied` | Permisos IAM insuficientes | Verifica las políticas del usuario `bitbucket-ci-deployer` |
| `deploy_aws` falla con `Invalid credentials` | Variables AWS no en Deployment variables | Agrega `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` en Deployments → production |
| `deploy_aws` falla con `You must be logged in` | Falta `SERVERLESS_ACCESS_KEY` | Crea Access Key en app.serverless.com y agrégala como Repository variable Secured |
| Variables AWS no disponibles en `deploy_aws` | Falta `deployment: production` en el step | El step debe declarar `deployment: production` para recibir las Deployment variables |
| `next build` falla con `Cannot find module` | `node_modules` incompleto | Verifica que `npm ci` corra antes de `npm run build` |
| ZIP de Lambda demasiado grande | `package.patterns` no excluye `node_modules` | Verifica que `serverless.yml` tenga `- '!node_modules/**'` en patterns |
| Lambda responde 500 | Error en el handler | Revisa los logs en AWS CloudWatch → `/aws/lambda/<nombre>` |
| Tests fallan con `SyntaxError: import` | Jest no transforma ESM de Next.js | Verifica que `jest.config.js` use `nextJest` de `next/jest` |
| Stack CloudFormation queda en `ROLLBACK` | Error al crear recursos AWS | Ve a AWS Console → CloudFormation → eventos del stack para el error detallado |
| Cache no se aplica | `package-lock.json` cambió | Normal — Bitbucket invalida el cache cuando `package-lock.json` cambia |
| `minutes quota exceeded` | Se agotaron los minutos del plan gratuito | Verifica cuota en Workspace settings → Plan details; optimiza con cache |

### 9.2 Errores reales encontrados durante el desarrollo de este lab

Estos errores surgieron al construir el proyecto. Se documentan con causa raíz y solución exacta para que puedas reconocerlos si los ves.

---

#### Error 1: "The step section is empty or null"

**Mensaje completo:**
```
There is an error in your bitbucket-pipelines.yml at
[pipelines > branches > main > 0 > stage > steps > 0].
The step section is empty or null.
```

**Causa:** `parallel:` estaba anidado *dentro* de `stage > steps`, que no está soportado por Bitbucket Pipelines. El parser interpreta el `parallel:` como un `step:` vacío.

```yaml
# ❌ Incorrecto — parallel: dentro de stage > steps
- stage:
    name: validate
    steps:
      - parallel:          # ← aquí falla
          - step: ...
```

**Solución:** Mover `parallel:` al nivel de la lista del pipeline, fuera del `stage:`.

```yaml
# ✅ Correcto — parallel: al mismo nivel que stage:
- parallel:
    - step:
        name: lint
    - step:
        name: test
- stage:
    name: deploy
    steps:
      - step:
          name: deploy_aws
```

---

#### Error 2: "A step within stage can't contain a manual trigger"

**Mensaje completo:**
```
Configuration error — A step within stage can't contain a manual trigger.
Try defining a manual trigger on a stage.
```

**Causa:** `trigger: manual` estaba definido en el `step:` dentro de un `stage:`. Bitbucket solo permite el trigger en el `stage:`, no en sus steps individuales.

```yaml
# ❌ Incorrecto — trigger: manual en el step
- stage:
    name: deploy
    steps:
      - step:
          name: deploy_aws
          trigger: manual    # ← aquí falla
```

**Solución:** Subir `trigger: manual` al nivel del `stage:`.

```yaml
# ✅ Correcto — trigger: manual en el stage
- stage:
    name: deploy
    trigger: manual          # ← aquí va
    steps:
      - step:
          name: deploy_aws
```

---

#### Error 3: "Unzipped size must be smaller than 262144000 bytes"

**Mensaje completo:**
```
An error occurred: AppLambdaFunction - Unzipped size must be smaller
than 262144000 bytes, currently 282168756 bytes.
```

**Causa:** `serverless.yml` sin `package.patterns` — Serverless empaquetó el proyecto completo incluyendo `node_modules/` (418 MB) y `.next/` (build de Next.js).

AWS Lambda impone un límite de **250 MB descomprimido** (50 MB comprimido para upload directo).

**Solución:** Excluir todo lo que el handler no necesita. Como `handler.js` no tiene `require()` externos, el ZIP puede ser de ~1 KB:

```yaml
package:
  patterns:
    - '!node_modules/**'
    - '!.next/**'
    - '!pages/**'
    - '!__tests__/**'
    - '!coverage/**'
    - '!report.xml'
    - '!jest.config.js'
    - '!next.config.js'
    - '!.eslintrc.json'
    - '!package*.json'
```

> **Regla práctica:** antes de desplegar, ejecuta `npx serverless package` localmente y verifica el tamaño del ZIP en `.serverless/`.

---

#### Error 4: "Cannot find module './bundle5'" (Lambda 500)

**Mensaje completo en CloudWatch:**
```
Error: Cannot find module './bundle5'
Require stack:
  - /var/task/node_modules/next/dist/server/config.js
  - /var/task/node_modules/next/dist/server/config-utils.js
  - /var/task/node_modules/next/dist/esm/server/config.js
  ...
```

**Causa:** Se intentó correr el servidor Next.js dentro de Lambda usando `next()` (API pública). Aunque el bundle standalone reduce `node_modules/next` a ~22 MB, esa versión es un árbol podado que omite webpack (`bundle5`). Sin embargo, `next()` en tiempo de inicialización carga `config.js → config-utils.js → webpack.js → bundle5` y falla.

```
next()
 └─ next/dist/server/next.js
     └─ next/dist/server/config.js
         └─ next/dist/server/config-utils.js
             └─ next/dist/esm/server/config.js
                 └─ require('./bundle5')  ← no existe en standalone
```

**Solución:** No correr Next.js en Lambda. En su lugar, implementar el handler como función pura que responde directamente al evento de API Gateway:

```javascript
// handler.js — sin imports de Next.js
exports.handler = async (event) => {
  const name = event.queryStringParameters?.name || 'World';
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: `Hello, ${name}!`, source: 'Next.js' }),
  };
};
```

La lógica de la API Route (`pages/api/hello.js`) y el handler Lambda comparten la misma implementación — solo difieren en la interfaz de entrada/salida (Next.js `req/res` vs evento API Gateway).

> Para producción con Next.js completo en Lambda (SSR, middleware, etc.) la solución correcta es [OpenNext](https://opennext.js.org/).

---

**Reglas de seguridad:**
- Marca `SERVERLESS_ACCESS_KEY`, `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` como **Secured**
- Usa un usuario IAM dedicado para CI/CD, nunca las credenciales root de AWS
- Usa Deployment variables para credenciales de entornos específicos — no las pongas en Repository variables
- Usa `trigger: manual` para deploys a producción
- Al finalizar el laboratorio, elimina los recursos de AWS: `npx serverless remove --stage production`

---

## Checklist de Éxito

- [ ] Pipelines habilitado en el repositorio de Bitbucket
- [ ] `lint` y `test` corren en paralelo en el stage `validate`
- [ ] Pipeline usa cache de npm, más rápido en la segunda ejecución
- [ ] Tests pasan y `report.xml` es descargable desde la UI del pipeline
- [ ] `deploy_aws` corre `next build` antes de `serverless deploy`
- [ ] `deploy_aws` requiere aprobación manual antes de ejecutar
- [ ] `deploy_aws` despliega correctamente a AWS Lambda via Serverless Framework v4
- [ ] Endpoint Lambda responde: `{"message": "Hello, World!", "source": "Next.js"}`
- [ ] Pipeline de PR ejecuta solo `validate` (sin deploy)
- [ ] Credenciales AWS nunca se exponen en logs (variables Secured)
- [ ] Recursos visibles en AWS CloudFormation Console y Lambda Console

---

## Entregables

1. **Repositorio Bitbucket** con:
   - `bitbucket-pipelines.yml` con los 2 stages (`validate`, `deploy`)
   - `handler.js` funcional como Lambda handler directo (sin dependencias externas)
   - `pages/api/hello.js` con la API Route
   - `__tests__/hello.test.js` con tests unitarios
   - `serverless.yml` con configuración de Serverless Framework v4
   - `package.json` con dependencias separadas (prod vs dev)
2. **Capturas de pantalla:**
   - Pipeline completo con stages y steps en paralelo (lint + test)
   - Artifact `report.xml` descargable en la UI del pipeline
   - Logs del step `deploy_aws` mostrando el endpoint generado
   - Respuesta del endpoint Lambda desde `curl` o el navegador
   - Stack en AWS CloudFormation Console mostrando los recursos creados
   - Variables de repositorio y deployment configuradas (sin mostrar el valor)
3. **Reflexión:**
   - ¿Por qué `next build` está en el step de deploy y no en validate?
   - ¿Por qué el `handler.js` de Lambda no usa el servidor de Next.js directamente? ¿Qué limitación de tamaño impone AWS Lambda?
   - ¿Qué diferencias encontraste entre Bitbucket Pipelines y GitLab CI/CD?

---

📘 **Autor:**  
Wilson Julca Mejía  
Curso: *DevOps y Bitbucket Pipelines – Next.js y AWS Lambda*  
Universidad de Ingeniería y Tecnología (UTEC)
