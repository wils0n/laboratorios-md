# 🌍 Guía: Configurar un sitio web estático en S3 con Terraform

## 🎯 Objetivo
Aprender los conceptos básicos de **Terraform** y desplegar un sitio web estático en **Amazon S3** usando infraestructura como código.

---

## 🧠 1. Fundamentos de Terraform y AWS S3

Terraform permite definir y administrar recursos en AWS (como S3) de forma declarativa. S3 es un servicio de almacenamiento de objetos que puede servir archivos como un sitio web estático.

### Conceptos Clave

| Concepto | Descripción |
|-----------|-------------|
| **Provider** | Define el tipo de infraestructura a administrar (ej. AWS, Docker). |
| **Resource** | Elemento a crear, modificar o destruir (ej. bucket, objeto, política). |
| **Variable** | Parámetro reutilizable definido en `.tfvars` o `variables.tf`. |
| **State** | Archivo (`terraform.tfstate`) donde Terraform guarda el estado actual. |
| **Plan** | Muestra los cambios antes de aplicarlos. |
| **Apply** | Ejecuta los cambios descritos en el plan. |
| **Destroy** | Elimina los recursos creados por Terraform. |

---

## ⚙️ 2. Instalación y verificación

Verifica que Terraform esté instalado:

```bash
terraform version
terraform help
```

---

## 🐳 3. Proyecto: Sitio web estático en S3

### Estructura del proyecto

```
s3/
├── main.tf
├── variables.tf
├── terraform.tfvars
├── index.html
├── policies.json
└── guide_terraform_s3.md
```

---

## 📄 4. Configuración paso a paso

### 4.1 Provider (AWS)
En el archivo `main.tf`:

```hcl
terraform {
	required_version = ">= 1.0"
	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = "~> 5.0"
		}
		random = {
			source  = "hashicorp/random"
			version = "~> 3.0"
		}
	}
}

provider "aws" {
	region = var.aws_region
}
```

---

### 4.2 Crear bucket S3 único y configurar como sitio web

```hcl
resource "random_id" "suffix" {
	byte_length = 4
}

resource "aws_s3_bucket" "example" {
	bucket        = "my-tf-test-bucket-${random_id.suffix.hex}"
	force_destroy = true
	tags = {
		Name        = "My bucket"
		Environment = "Dev"
	}
}

resource "aws_s3_bucket_website_configuration" "website" {
	bucket = aws_s3_bucket.example.bucket
	index_document {
		suffix = "index.html"
	}
}
```

---

### 4.3 Subir el archivo HTML

```hcl
resource "aws_s3_object" "index_html" {
	bucket       = aws_s3_bucket.example.bucket
	key          = "index.html"
	source       = "${path.module}/index.html"
	content_type = "text/html"
}
```

---

### 4.4 Permitir acceso público y política

```hcl
resource "aws_s3_bucket_public_access_block" "public" {
	bucket = aws_s3_bucket.example.bucket
	block_public_acls       = false
	block_public_policy     = false
	ignore_public_acls      = false
	restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public_access" {
	bucket = aws_s3_bucket.example.bucket
	policy = jsonencode({
		Version = "2012-10-17",
		Statement = [
			{
				Sid       = "PublicReadGetObject",
				Effect    = "Allow",
				Principal = "*",
				Action    = "s3:GetObject",
				Resource  = "${aws_s3_bucket.example.arn}/*"
			}
		]
	})
}
```

---

### 4.5 Output de la URL del sitio web

```hcl
output "website_url" {
	value = "http://${aws_s3_bucket.example.bucket}.s3-website.${var.aws_region}.amazonaws.com"
}
```

---

## 🚀 5. Ejecución del proyecto

### 5.1 Inicializar Terraform
```bash
terraform init
```
> Descarga los plugins necesarios (provider AWS y random).

### 5.2 Validar la configuración
```bash
terraform validate
```

### 5.3 Previsualizar los cambios
```bash
terraform plan
```

### 5.4 Aplicar los cambios
```bash
terraform apply
```
Confirma con `yes` para crear el bucket y subir el archivo.

---

## 🔍 6. Verificar el despliegue

Al finalizar, Terraform mostrará la URL del sitio web:

```
Outputs:
website_url = "http://my-tf-test-bucket-xxxx.s3-website.<region>.amazonaws.com"
```

Abre tu navegador y visita la URL para ver el sitio web estático.

---

## 🧹 7. Eliminar recursos

Para destruir la infraestructura creada:

```bash
terraform destroy
```
Esto eliminará el bucket y los objetos creados por Terraform.

---

## 🧩 8. Archivos auxiliares

### variables.tf (ejemplo)
```hcl
variable "aws_region" {
	description = "Región de AWS"
	default     = "us-east-1"
}
```

### terraform.tfvars (ejemplo)
```hcl
aws_region = "us-east-1"
```

---

## 💡 9. Buenas prácticas

- Versionar los archivos `.tf` con Git.
- No incluir `terraform.tfstate` en tu repositorio (añadirlo a `.gitignore`).
- Utilizar variables para región, nombres y configuraciones.
- Ejecutar `terraform fmt` para mantener el formato estándar.
- Revisar los planes antes de aplicar (`terraform plan`).

---

## 🧰 10. Comandos útiles de Terraform

| Comando | Descripción |
|----------|--------------|
| `terraform init` | Inicializa el entorno de trabajo. |
| `terraform plan` | Muestra los cambios que se aplicarán. |
| `terraform apply` | Aplica los cambios. |
| `terraform destroy` | Elimina la infraestructura. |
| `terraform validate` | Valida la sintaxis y dependencias. |
| `terraform fmt` | Formatea los archivos `.tf`. |
| `terraform state list` | Lista los recursos del estado actual. |

---

## 🎓 Conclusión

Con esta guía has aprendido:
- Los **principios básicos de Terraform y AWS S3**.
- Cómo **desplegar un sitio web estático** usando infraestructura como código.
- Cómo **aplicar, validar y destruir** configuraciones de forma declarativa.

Terraform te permite pasar de configuraciones manuales a despliegues reproducibles y automatizados en la nube.

---

> 🧩 **Autor:** Wilson Julca Mejía  
> **Curso:** DevOps  
> **Tema:** Infraestructura como Código con Terraform y AWS S3  
> **Versión:** 1.0
