# Laboratorio: CI/CD en GitLab - Despliegue de Lambda en AWS con Terraform

**Duración estimada:** 90–120 min  
**Nivel:** Intermedio  
**Contexto:** Este laboratorio es el comparativo de `laboratorio_gitlab.md`. Allá desplegaste una función Lambda usando **Serverless Framework**. Aquí harás exactamente lo mismo usando **Terraform**. Al final podrás comparar ambos enfoques: qué hace cada tool automáticamente y qué tienes que declarar tú en HCL.

---

## Objetivos de aprendizaje

- Escribir un handler Lambda en Python puro, ejecutable localmente sin AWS
- Empaquetar el handler como ZIP con el data source `archive_file`
- Declarar un IAM execution role explícitamente en HCL
- Crear una Lambda Function URL como endpoint HTTP (sin API Gateway)
- Crear un pipeline GitLab con stages `validate → plan → apply`
- Usar el backend HTTP de GitLab para guardar el estado sin un bucket S3
- Comparar Terraform vs Serverless Framework para el mismo caso de uso

---

## Requisitos previos

✅ Cuenta en GitLab ([https://gitlab.com/](https://gitlab.com/))  
✅ Cuenta AWS propia con permisos para crear Lambda, IAM y CloudWatch  
✅ Terraform 1.0+ instalado localmente  
✅ Python 3.11+ instalado localmente  
✅ Haber completado `laboratorio_gitlab.md` (Serverless Framework) para el comparativo

---

## Estructura del proyecto

```
gitlab_terraform_demo/
├── .gitlab-ci.yml      # Pipeline de CI/CD
├── main.tf             # IAM role + Lambda + Function URL
├── variables.tf        # Variables de entrada
└── app/
    └── handler.py      # Handler Lambda — ejecutable localmente
```

Sin `scripts/`, sin `requirements.txt`, sin `user_data.sh`. El handler usa solo la librería estándar de Python.

---

## Parte 1: Handler Lambda

El handler es una función Python pura: recibe un evento, devuelve un dict. No necesita FastAPI ni Mangum — Lambda llama directamente a la función.

### 1.1 `app/handler.py`

**Archivo: `app/handler.py`**

```python
import json


def lambda_handler(event, context):
    params = event.get("queryStringParameters") or {}
    name = params.get("name", "World")

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "message": f"Hello, {name}!",
            "source": "Lambda puro en Python",
        }),
    }


if __name__ == "__main__":
    event = {"queryStringParameters": {"name": "UTEC"}}
    print(json.dumps(lambda_handler(event, None), indent=2))
```

### 1.2 Probar localmente

```bash
cd app/
python handler.py
```

```json
{
  "statusCode": 200,
  "headers": {"Content-Type": "application/json"},
  "body": "{\"message\": \"Hello, UTEC!\", \"source\": \"Lambda puro en Python\"}"
}
```

No necesitas AWS, credenciales ni internet. El handler es código Python normal.

---

## Parte 2: Archivos Terraform

### 2.1 `main.tf`

Terraform declara explícitamente todo lo que Serverless Framework crea automáticamente: el IAM role, la función Lambda y el endpoint HTTP.

**Archivo: `main.tf`**

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "http" {}
}

provider "aws" {
  region = var.aws_region
}

# ── Empaquetar handler.py como ZIP ────────────────────────────────────────────
# archive_file corre localmente durante terraform plan.
# Lee app/handler.py y genera lambda.zip en la raíz del proyecto.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/app/handler.py"
  output_path = "${path.module}/lambda.zip"
}

# ── IAM execution role ────────────────────────────────────────────────────────
# Serverless Framework crea este role automáticamente.
# Con Terraform lo declaramos nosotros en HCL.
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ── Lambda Function ───────────────────────────────────────────────────────────
resource "aws_lambda_function" "hello" {
  function_name    = var.project_name
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.11"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tags = {
    ManagedBy = "Terraform"
  }
}

# ── API Gateway v2 ───────────────────────────────────────────────────────────
# Equivalente a "events.httpApi" en serverless.yml.
# Serverless lo crea con 2 líneas de YAML; Terraform requiere 5 recursos.

resource "aws_apigatewayv2_api" "hello" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "hello" {
  api_id                 = aws_apigatewayv2_api.hello.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.hello.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "hello" {
  api_id    = aws_apigatewayv2_api.hello.id
  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello.id}"
}

resource "aws_apigatewayv2_stage" "hello" {
  api_id      = aws_apigatewayv2_api.hello.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.hello.execution_arn}/*/*"
}

output "api_url" {
  description = "URL del endpoint en API Gateway v2"
  value       = "${aws_apigatewayv2_stage.hello.invoke_url}/hello"
}
```

**Recursos que Terraform crea y lo que hace cada uno:**

| Recurso HCL | Equivalente en Serverless Framework |
|---|---|
| `data.archive_file.lambda_zip` | `sls deploy` empaqueta automáticamente |
| `aws_iam_role.lambda_exec` | Serverless crea `IamRoleLambdaExecution` en CloudFormation |
| `aws_iam_role_policy_attachment.lambda_logs` | Serverless adjunta permisos de logs automáticamente |
| `aws_lambda_function.hello` | `functions.hello` en `serverless.yml` |
| `aws_apigatewayv2_api.hello` | `events.httpApi` en `serverless.yml` (1 de 5) |
| `aws_apigatewayv2_integration.hello` | `events.httpApi` en `serverless.yml` (2 de 5) |
| `aws_apigatewayv2_route.hello` | `events.httpApi` en `serverless.yml` (3 de 5) |
| `aws_apigatewayv2_stage.hello` | `events.httpApi` en `serverless.yml` (4 de 5) |
| `aws_lambda_permission.apigw` | `events.httpApi` en `serverless.yml` (5 de 5) |

> **`source_code_hash`**: cuando cambias `handler.py`, el hash del ZIP cambia. Terraform detecta ese cambio en el próximo `plan` y sube el nuevo código a Lambda. Sin este campo, Terraform no actualizaría la función aunque el código cambie.

### 2.2 `variables.tf`

**Archivo: `variables.tf`**

```hcl
variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre de la función Lambda y prefijo de recursos IAM"
  type        = string
  default     = "tf-lambda-demo"
}
```


### 2.3 Validación local antes del pipeline

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan   # genera lambda.zip + muestra los recursos a crear
```

```bash
# Al terminar el laboratorio
terraform destroy
```

---

## Parte 3: Backend HTTP de GitLab

El bloque `backend "http" {}` en `main.tf` guarda el estado de Terraform directamente en tu proyecto de GitLab — sin necesidad de un bucket S3.

```
Runner → terraform init → conecta al backend HTTP del proyecto GitLab
                       → lee/escribe terraform.tfstate en GitLab
                       → los jobs plan y apply comparten el mismo estado
```

La conexión se configura con variables `TF_HTTP_*` en el pipeline (ver Parte 5). GitLab genera `CI_JOB_TOKEN` automáticamente por cada job — no necesitas configurar nada extra.

---

## Parte 4: Credenciales en GitLab CI/CD

### 4.1 Crear el usuario IAM

1. Ve a **AWS Console → IAM → Users → Create user**
2. Nómbralo `gitlab-ci-terraform` → **Next**
3. Selecciona **Attach policies directly** y agrega:
   - `AWSLambda_FullAccess`
   - `IAMFullAccess` (necesario para crear el execution role)
   - `AmazonAPIGatewayAdministrator` (necesario para crear el API Gateway v2)
4. **Create user**

### 4.2 Generar las credenciales

1. Abre el usuario `gitlab-ci-terraform` → pestaña **Security credentials**
2. **Access keys → Create access key → Command Line Interface (CLI)**
3. Copia `Access key ID` y `Secret access key` — **solo se muestran una vez**

### 4.3 Agregar las variables en GitLab

Ve a tu proyecto → **Settings → CI/CD → Variables → Add variable**:

| Variable               | Valor                      | Protected | Masked |
|------------------------|----------------------------|-----------|--------|
| `AWS_ACCESS_KEY_ID`    | Access key del usuario IAM | Sí        | Sí     |
| `AWS_SECRET_ACCESS_KEY`| Secret key del usuario IAM | Sí        | Sí     |
| `AWS_DEFAULT_REGION`   | `us-east-1`                | Sí        | No     |

---

## Parte 5: Pipeline completo `.gitlab-ci.yml`

```
validate (fmt-check + validate + lint-python en paralelo) → plan → apply (manual)
```

**Archivo: `.gitlab-ci.yml`**

```yaml
stages:
  - validate
  - plan
  - apply

default:
  image:
    name: hashicorp/terraform:1.8
    entrypoint: [""]

variables:
  TF_IN_AUTOMATION: "true"
  # Backend HTTP de GitLab — estado guardado en el propio proyecto, sin S3
  TF_HTTP_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/default"
  TF_HTTP_LOCK_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/default/lock"
  TF_HTTP_UNLOCK_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/default/lock"
  TF_HTTP_USERNAME: "gitlab-ci-token"
  TF_HTTP_PASSWORD: "${CI_JOB_TOKEN}"
  TF_HTTP_LOCK_METHOD: "POST"
  TF_HTTP_UNLOCK_METHOD: "DELETE"

.terraform_cache: &terraform_cache
  cache:
    key: "${CI_COMMIT_REF_SLUG}-terraform"
    paths:
      - .terraform/

.terraform_init: &terraform_init
  before_script:
    - terraform --version
    - terraform init -reconfigure

# ══════════════════════════════════════════════════════════════════════════════
# STAGE: validate
# ══════════════════════════════════════════════════════════════════════════════

fmt-check:
  stage: validate
  before_script:
    - terraform --version
  script:
    - terraform fmt -check -recursive
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

validate:
  stage: validate
  <<: *terraform_cache
  <<: *terraform_init
  script:
    - terraform validate
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

lint-python:
  stage: validate
  image: python:3.11-slim
  before_script:
    - pip install flake8
  script:
    - flake8 app/ --max-line-length=100 --statistics
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

# ══════════════════════════════════════════════════════════════════════════════
# STAGE: plan
# ══════════════════════════════════════════════════════════════════════════════

plan:
  stage: plan
  <<: *terraform_cache
  <<: *terraform_init
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - tfplan
      - lambda.zip    # generado por archive_file durante el plan
    expire_in: 1 week
    when: always
  needs:
    - job: fmt-check
    - job: validate
    - job: lint-python
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'

# ══════════════════════════════════════════════════════════════════════════════
# STAGE: apply
# ══════════════════════════════════════════════════════════════════════════════

apply:
  stage: apply
  <<: *terraform_cache
  <<: *terraform_init
  script:
    - terraform apply tfplan
    - terraform output
  environment:
    name: aws-lambda
  needs:
    - job: plan
      artifacts: true
  when: manual
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
```

---

## Parte 6: Conceptos clave

### 6.1 `archive_file` — packaging del ZIP

```hcl
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/app/handler.py"
  output_path = "${path.module}/lambda.zip"
}
```

`archive_file` es un **data source** — corre localmente durante `terraform plan`, no en AWS. Lee `app/handler.py` del workspace y genera `lambda.zip`. Por eso el artifact del job `plan` incluye tanto `tfplan` como `lambda.zip`: el job `apply` los necesita a ambos.

```
terraform plan
  └── archive_file corre localmente
        └── genera lambda.zip en el runner
              └── tfplan referencia ese ZIP (hash + path)

terraform apply tfplan
  └── sube lambda.zip a AWS
  └── crea/actualiza aws_lambda_function
```

### 6.2 `source_code_hash` — redeploy automático

```hcl
source_code_hash = data.archive_file.lambda_zip.output_base64sha256
```

Terraform compara este hash con el que tiene registrado en el estado. Si cambió (porque modificaste `handler.py`), el próximo `plan` marca la función Lambda para actualización. Sin este campo, Terraform no detectaría el cambio de código aunque el archivo sí haya cambiado.

### 6.3 API Gateway v2 — los 5 recursos que Serverless oculta

En el lab de Serverless Framework creaste el endpoint con 2 líneas en `serverless.yml`:

```yaml
events:
  - httpApi:
      path: /hello
      method: GET
```

Terraform expone exactamente lo que Serverless hace por debajo. Esas 2 líneas equivalen a 5 recursos HCL:

```
aws_apigatewayv2_api          → el API Gateway en sí (protocolo HTTP)
aws_apigatewayv2_integration  → conecta el API con la función Lambda
aws_apigatewayv2_route        → mapea "GET /hello" a la integración
aws_apigatewayv2_stage        → stage "$default" con auto-deploy activado
aws_lambda_permission         → permite que API Gateway invoque la función
```

Sin el `aws_lambda_permission`, API Gateway recibe un `403 Forbidden` al intentar llamar a Lambda — aunque la ruta esté bien configurada. Serverless lo crea silenciosamente; Terraform te lo hace visible.

### 6.4 `lambda.zip` como artifact

```yaml
plan:
  artifacts:
    paths:
      - tfplan
      - lambda.zip
```

El job `apply` corre en un contenedor nuevo — el workspace está vacío. Necesita tanto el plan binario (`tfplan`) como el ZIP del código (`lambda.zip`) que `archive_file` generó durante el plan. Sin `lambda.zip` en los artifacts, `terraform apply` no encuentra el archivo y falla.

### 6.5 Jobs en paralelo y flujo del pipeline

```
validate:
  ┌───────────────┐  ┌────────────┐  ┌──────────────┐
  │   fmt-check   │  │  validate  │  │ lint-python  │  ← al mismo tiempo
  └───────────────┘  └────────────┘  └──────────────┘
                             │
                           plan  (genera tfplan + lambda.zip)
                             │
                           apply ▶ (manual)
```

---

## Parte 7: Probar el pipeline

### 7.1 Push inicial

```bash
git add .gitlab-ci.yml main.tf variables.tf terraform.tfvars app/handler.py
git commit -m "feat: pipeline GitLab CI con despliegue Lambda via Terraform"
git push origin main
```

### 7.2 Observar la ejecución

1. Ve a **CI/CD → Pipelines** en GitLab.
2. Los tres jobs del stage `validate` corren en paralelo.
3. El job `plan` corre y guarda `tfplan` + `lambda.zip` como artifacts.
4. Haz clic en ▶ del job `apply` después de revisar el plan.
5. Al terminar, el output muestra la URL:

```
api_url = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/hello"
```

### 7.3 Invocar la función

```bash
curl "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/hello?name=UTEC"
# {"message": "Hello, UTEC!", "source": "Lambda puro en Python"}
```

### 7.4 Actualizar el handler y ver el redeploy

Modifica `app/handler.py` (agrega un campo al response), commitea y haz push. El pipeline detecta el cambio de hash y actualiza la función Lambda automáticamente al hacer apply.

### 7.5 Limpiar recursos

```bash
terraform destroy
```

---

## Parte 8: Comparativo — Terraform vs Serverless Framework

| Aspecto | Serverless Framework | Terraform |
|---|---|---|
| Config principal | `serverless.yml` | `main.tf` (HCL) |
| IAM execution role | Creado automáticamente | Declarado en `aws_iam_role` + `aws_iam_role_policy_attachment` |
| Packaging del código | Interno (`sls deploy`) | `data "archive_file"` genera el ZIP |
| Endpoint HTTP | `events.httpApi` → 2 líneas YAML | API Gateway v2 → 5 recursos HCL explícitos |
| Estado de infraestructura | CloudFormation stack | `terraform.tfstate` |
| Destruir recursos | `sls remove` | `terraform destroy` |
| Detectar cambios de código | Siempre reempaqueta | `source_code_hash` compara hashes |
| Soporte multi-provider | Solo AWS/Azure/GCP serverless | AWS, GCP, Azure, Kubernetes, etc. |
| Curva de aprendizaje | Menor (abstrae IAM y packaging) | Mayor (debes declarar todo) |

**¿Cuándo usar cada uno?**

- **Serverless Framework**: cuando el foco es la lógica de la app y quieres que el tool gestione la infraestructura serverless automáticamente.
- **Terraform**: cuando necesitas controlar exactamente qué recursos se crean, combinar Lambda con otros recursos (RDS, VPC, S3) o gestionar infraestructura de múltiples providers en el mismo pipeline.

---

## Parte 9: Troubleshooting

| Problema | Causa probable | Solución |
|----------|---------------|----------|
| `fmt-check` falla | Archivos `.tf` sin formatear | Corre `terraform fmt -recursive` localmente y commitea |
| `validate` falla | Referencia incorrecta en `main.tf` | Corre `terraform validate` localmente |
| `lint-python` falla | Estilo incorrecto en `app/` | Corre `flake8 app/ --max-line-length=100` y corrige |
| `plan` falla con `NoCredentialProviders` | Variables AWS no configuradas | Agrega `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION` en GitLab Variables |
| `plan` falla con `AccessDenied` al crear IAM role | Política IAM insuficiente | Verifica que el usuario tenga `IAMFullAccess` |
| `apply` falla con `AccessDenied` en API Gateway | Falta política de API Gateway | Agrega `AmazonAPIGatewayAdministrator` al usuario IAM |
| `curl` devuelve `{"message":"Forbidden"}` en el endpoint | Falta `aws_lambda_permission` para `apigateway.amazonaws.com` | Verifica que el recurso `aws_lambda_permission.apigw` esté en `main.tf` |
| `apply` falla con `lambda.zip: no such file` | Artifact no incluido en el plan | Agrega `lambda.zip` a los `artifacts.paths` del job `plan` |
| `apply` falla con `state lock` | Otro apply corriendo | Espera o ve a **Infrastructure → Terraform** en GitLab y borra el lock |
| `apply tfplan` falla con `state changed` | Estado cambió entre plan y apply | Vuelve a correr el job `plan` |
| Handler no actualiza en Lambda | Falta `source_code_hash` | Agrega `source_code_hash = data.archive_file.lambda_zip.output_base64sha256` |
| `curl` devuelve `{"message":"Internal Server Error"}` | Error en el handler Python | Revisa CloudWatch Logs: AWS Console → Lambda → Monitor → View logs |

**Reglas de seguridad:**
- Marca `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` como **Protected** y **Masked**
- Usa un usuario IAM dedicado para CI/CD, nunca tu usuario personal
- Agrega al `.gitignore`:

```
.terraform/
terraform.tfstate
terraform.tfstate.backup
lambda.zip
```

---

## Checklist de Éxito

- [ ] Handler corre localmente: `python app/handler.py` → respuesta JSON
- [ ] `fmt-check`, `validate` y `lint-python` corren en paralelo
- [ ] Job `plan` genera artifacts `tfplan` + `lambda.zip`
- [ ] Job `apply` requiere aprobación manual
- [ ] Lambda respondiendo vía API Gateway: `curl <api_url>?name=UTEC`
- [ ] Estado Terraform visible en **Infrastructure → Terraform States** en GitLab
- [ ] Al modificar `handler.py` y hacer push, el pipeline actualiza la función
- [ ] Credenciales AWS no aparecen en logs del pipeline
- [ ] Recursos destruidos al finalizar (`terraform destroy`)

---

📘 **Autor:**  
Wilson Julca Mejía  
Curso: *DevOps e Infraestructura como Código – Terraform y GitLab CI/CD*  
Universidad de Ingeniería y Tecnología (UTEC)
