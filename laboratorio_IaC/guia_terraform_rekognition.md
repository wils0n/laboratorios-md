# Tutorial: Provisionar API de Reconocimiento de Imágenes con Terraform

## Objetivo

Esta guía muestra cómo provisionar en AWS, usando Terraform, una API REST que reciba imágenes (Base64), invoque una función Lambda que llame a Amazon Rekognition y devuelva etiquetas detectadas.

Arquitectura:
Cliente → API Gateway → Lambda → Rekognition
                                 ↓
                            CloudWatch Logs

## Requisitos previos

- Cuenta AWS con credenciales configuradas en tu Mac (AWS CLI o variables de entorno).
- Terraform >= 1.0 instalado.
- Postman u otra herramienta para probar HTTP.
- Imagen de prueba (para convertir a Base64).
- Carpeta de trabajo: un módulo Terraform por stack (ej: terraform-rekognition).

## Estructura recomendada del proyecto

terraform-rekognition/
- main.tf
- variables.tf
- outputs.tf
- lambda/
  - lambda_function.py
- terraform.tfvars (opcional)

## Paso 1 — Provider y recursos básicos (main.tf)

Ejemplo mínimo (proveedor, rol IAM, Lambda, API Gateway, permisos):

```hcl
// main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.lambda_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_name}-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "rekognition:DetectLabels",
          "rekognition:DetectModerationLabels",
          "rekognition:DetectFaces"
        ]
        Resource = "*"
      }
    ]
  })
}

# Empaquetar la función: apuntamos a un ZIP local (ver sección empaquetado)
resource "aws_lambda_function" "rekognition" {
  filename         = "${path.module}/lambda/function.zip"
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda/function.zip")
  timeout          = 10
  memory_size      = 256
  publish          = true
  environment {
    variables = {
      # variables si necesitas
    }
  }
}

# API Gateway REST
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.lambda_name}-api"
  description = "API para detectar etiquetas con Rekognition"
}

resource "aws_api_gateway_resource" "detect" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "detect"
}

resource "aws_api_gateway_method" "post_detect" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.detect.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.detect.id
  http_method = aws_api_gateway_method.post_detect.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.rekognition.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
}

# Permitir que API Gateway invoque la Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rekognition.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

```

## Paso 2 — Variables y outputs

variables.tf

```hcl
// variables.tf
variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "lambda_name" {
  description = "Nombre de la función Lambda"
  type        = string
  default     = "RekognitionImageLabeler"
}
```

outputs.tf

```hcl
// outputs.tf
output "api_endpoint" {
  value = "${aws_api_gateway_stage.prod.invoke_url}"
  description = "URL pública del endpoint (stage prod)"
}
```

Nota: aws_api_gateway_stage.invoke_url es soportado por versiones recientes; si no, construir con: "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/detect".

## Paso 3 — Código de la Lambda

Archivo: lambda/lambda_function.py

```python
# lambda/lambda_function.py
import json
import base64
import boto3

rek = boto3.client("rekognition")

def lambda_handler(event, context):
    try:
        body = event.get("body")
        if body is None:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing body"})}

        # Si API Gateway no transmite como JSON parsed, intentar parsear
        if isinstance(body, str):
            payload = json.loads(body)
        else:
            payload = body

        image_b64 = payload.get("image")
        if not image_b64:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing 'image' in JSON body."})}

        image_bytes = base64.b64decode(image_b64)

        response = rek.detect_labels(Image={"Bytes": image_bytes}, MaxLabels=10, MinConfidence=75)
        labels = [lbl["Name"] for lbl in response.get("Labels", [])]

        return {
            "statusCode": 200,
            "body": json.dumps({"labels": labels})
        }

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
```

## Paso 4 — Empaquetado (en macOS)

1. Sitúate en la carpeta del módulo (terraform-rekognition).
2. Crea el ZIP con el código:

```bash
# desde la raíz del módulo
cd lambda
zip -r ../lambda/function.zip .
cd ..
```

Si tu función necesita librerías externas no incluidas en Lambda runtime debes instalarlas en la carpeta lambda/ y luego zipearlas (ejemplo con pip y carpeta vendor).

## Paso 5 — Inicializar y aplicar Terraform

Desde la carpeta donde están los .tf:

```bash
terraform init
terraform validate
terraform plan -out plan.tfplan
terraform apply "plan.tfplan"
```

Confirma y espera a que Terraform cree los recursos. Al terminar, verás la salida con la URL del API.

## Paso 6 — Probar la API (Postman)

- Método: POST
- URL: (output) ej: https://{id}.execute-api.{region}.amazonaws.com/prod/detect
- Headers: Content-Type: application/json
- Body (raw JSON):

```json
{
  "image": "BASE64_DE_TU_IMAGEN"
}
```

Respuesta esperada (200):

```json
{
  "labels": ["Car", "Vehicle", "Automobile"]
}
```

Alternativamente en macOS puedes obtener Base64 con:

```bash
base64 -i car.jpeg -o imagen_base64.txt
# o
base64 car.jpeg > imagen_base64.txt
```

## Manejo de errores comunes

- 400 Missing 'image': verificar el body JSON y que la key "image" exista.
- 500 Invalid base64: confirmar que la cadena sea Base64 válida (sin cabeceras data:...).
- IAM o permisos: revisar CloudWatch Logs para la Lambda y asegurarse que la política permite rekognition:DetectLabels.
- Región: Rekognition debe estar disponible en la región seleccionada.

## Limpieza

Para eliminar todo lo creado:

```bash
terraform destroy
```

También borrar el ZIP si lo deseas:

```bash
rm lambda/function.zip
```

## Buenas prácticas / notas

- Versionar los archivos Terraform con Git.
- No subir terraform.tfstate a repositorio público.
- Para despliegues repetibles, considera usar S3 para alojar paquetes Lambda y usar aws_s3_object + s3_key en aws_lambda_function.
- Para producción, refinar la política IAM y limitar recursos (no usar Resource="*").
- Configurar alarmas y métricas en CloudWatch para monitoreo.

## Explicación de cada recurso en `main.tf`

Esta sección describe, en orden de aparición, qué hace cada bloque importante en el `main.tf` del ejemplo y por qué es necesario.

- terraform { ... }
  - Define requisitos de Terraform y proveedores (por ejemplo la versión del provider `aws` y la versión mínima de Terraform). No crea recursos: asegura que el entorno (versión del provider y de Terraform) sea compatible con la configuración escrita.

- provider "aws"
  - Configura el proveedor AWS: región y credenciales (estas se toman desde el entorno o el perfil configurado). Es el puente que permite a Terraform llamar a la API de AWS para crear recursos.

- data "aws_iam_policy_document" "lambda_assume_role"
  - Genera de forma declarativa el documento JSON que define la relación de confianza (trust policy) necesaria para que Lambda pueda asumir el role (STS AssumeRole). Es más limpio y menos propenso a errores que escribir JSON a mano.

- resource "aws_iam_role" "lambda_exec"
  - Crea el IAM Role que la función Lambda usará como identidad de ejecución. Este role contiene la relación de confianza (assume role) creada anteriormente.

- resource "aws_iam_role_policy" "lambda_policy"
  - Adjunta una política inline al role de Lambda con los permisos que la función necesita:
    - Permisos de CloudWatch Logs (crear grupos/streams y escribir eventos) para registrar ejecuciones.
    - Permisos de Amazon Rekognition (por ejemplo DetectLabels, DetectFaces) para que la función pueda usar Rekognition.
  - Nota: en el ejemplo se usa Resource = "*" para Rekognition; en producción conviene restringir a recursos concretos si es posible.

- resource "aws_lambda_function" "rekognition"
  - Crea la función Lambda con la configuración de runtime, handler, memoria, timeout, y el paquete de código (`filename` apunta al ZIP local).
  - `source_code_hash = filebase64sha256(...)` se usa para que Terraform detecte cambios en el ZIP y despliegue nuevas versiones cuando el código cambie.
  - `publish = true` publica una versión de la función cuando cambia el código.

- resource "aws_api_gateway_rest_api" "api"
  - Crea el API REST en API Gateway que agrupa recursos (rutas), métodos y despliegues. Es el contenedor lógico del endpoint público.

- resource "aws_api_gateway_resource" "detect"
  - Añade un recurso (ruta) debajo del root del API, por ejemplo `/detect`. Cada recurso representa un segmento de la URL.

- resource "aws_api_gateway_method" "post_detect"
  - Define el método HTTP (POST) para la ruta `/detect`. Aquí se configura autorización, parámetros y otras opciones del método.

- resource "aws_api_gateway_integration" "lambda_integration"
  - Conecta el método POST `/detect` con la función Lambda.
  - `type = "AWS_PROXY"` indica integración proxy (Lambda proxy integration): API Gateway manda el request completo a Lambda y espera respuesta con `statusCode` y `body` en el formato esperado.
  - `uri` apunta al `invoke_arn` de la Lambda para que API Gateway sepa a qué función enviar el evento.

- resource "aws_api_gateway_deployment" "deployment"
  - Crea un deployment del API (un snapshot que puede ser asociado a un stage). Terraform necesita esto para publicar cambios.
  - `depends_on` asegura que métodos e integraciones estén creados antes del deployment.
  - `lifecycle { create_before_destroy = true }` ayuda a evitar tiempos de inactividad al actualizar deployments.

- resource "aws_api_gateway_stage" "prod"
  - Crea un stage (por ejemplo `prod`) ligado a un deployment. El stage forma parte de la URL pública (por ejemplo `/prod/detect`).

- resource "aws_lambda_permission" "apigw"
  - Concede permiso explícito para que API Gateway invoque la Lambda. Indica `principal = "apigateway.amazonaws.com"` y restringe el `source_arn` al API creado.

Notas adicionales rápidas:
- `${path.module}`: ruta del módulo/paquete actual. Se usa para referenciar el ZIP relativo (`${path.module}/lambda/function.zip`).
- `filebase64sha256("...")`: calcula un hash del ZIP; Terraform lo usa para detectar cambios en el código y forzar redeploy.
- AWS_PROXY vs integración no-proxy: la integración proxy simplifica la interacción porque entrega la petición HTTP completa a la Lambda (headers, body, path, etc.) y espera una respuesta con `statusCode` y `body`. Con integración no-proxy necesitas mapas de transformación.

Si quieres, puedo añadir comentarios inline en el `main.tf` del repositorio para que cada bloque tenga una nota corta directamente en el archivo de Terraform.
