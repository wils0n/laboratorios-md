# 🌍 Guía: Configurar Nginx con Docker y Terraform

## 🎯 Objetivo
Aprender los conceptos básicos de **Terraform** y desplegar un contenedor **Nginx** en Docker mediante infraestructura como código.

---

## 🧠 1. Fundamentos de Terraform

Terraform es una herramienta de **Infraestructura como Código (IaC)** que permite definir, provisionar y administrar infraestructura en distintos proveedores (locales o en la nube) mediante archivos de configuración declarativos.

### Conceptos Clave

| Concepto | Descripción |
|-----------|-------------|
| **Provider** | Define el tipo de infraestructura a administrar (ej. AWS, Docker, Azure). |
| **Resource** | Elemento a crear, modificar o destruir (ej. contenedor, red, bucket, VM). |
| **Variable** | Parámetro reutilizable que se puede definir en un archivo `.tfvars`. |
| **State** | Archivo (`terraform.tfstate`) donde Terraform guarda el estado actual de la infraestructura. |
| **Plan** | Muestra los cambios que se realizarán antes de aplicarlos. |
| **Apply** | Ejecuta los cambios descritos en el plan. |
| **Destroy** | Elimina los recursos creados por Terraform. |

---

## ⚙️ 2. Instalación y verificación

Verifica que Terraform esté correctamente instalado:

```bash
terraform version
terraform help
```

Deberías ver una salida similar a:
```
Terraform v1.x.x
```

---

## 🐳 3. Proyecto: Nginx con Docker y Terraform

### Estructura del proyecto

```
terraform-nginx/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── index.html
└── Dockerfile
```

---

## 📄 4. Configuración paso a paso

### 4.1 Provider (Docker)
En el archivo `main.tf`:

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}
```

---

### 4.2 Crear una imagen personalizada de Nginx

Creamos un `Dockerfile` para servir un archivo HTML propio:

```Dockerfile
FROM nginx:latest
COPY index.html /usr/share/nginx/html/index.html
```

El archivo `index.html` puede contener:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Hola desde Terraform + Docker + Nginx</title>
</head>
<body>
  <h1>¡Despliegue exitoso! 🚀</h1>
</body>
</html>
```

---

### 4.3 Definir recursos de Docker en Terraform

En `main.tf`, añadimos los recursos:

```hcl
resource "docker_image" "nginx_image" {
  name         = "nginx-custom"
  build {
    context    = "${path.module}"
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "nginx_container" {
  name  = "nginx-terraform"
  image = docker_image.nginx_image.latest
  ports {
    internal = 80
    external = 8080
  }
}
```

---

## 🚀 5. Ejecución del proyecto

### 5.1 Inicializar Terraform
```bash
terraform init
```
> Descarga los plugins necesarios (por ejemplo, el provider de Docker).

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

Confirma con `yes` para desplegar el contenedor.

---

## 🔍 6. Verificar el despliegue

Ejecuta:
```bash
docker ps
```

Abre tu navegador y visita:
```
http://localhost:8080
```

Deberías ver el mensaje:
> “¡Despliegue exitoso! 🚀”

---

## 🧹 7. Eliminar recursos

Para destruir la infraestructura creada:

```bash
terraform destroy
```

Esto eliminará el contenedor e imagen creados por Terraform.

---

## 🧩 8. Archivos auxiliares

### variables.tf (opcional)
```hcl
variable "container_name" {
  description = "Nombre del contenedor Nginx"
  default     = "nginx-terraform"
}

variable "external_port" {
  description = "Puerto de exposición del contenedor"
  default     = 8080
}
```

### outputs.tf (opcional)
```hcl
output "nginx_url" {
  value = "http://localhost:${var.external_port}"
}
```

---

## 💡 9. Buenas prácticas

- Versionar los archivos `.tf` con Git.
- No incluir `terraform.tfstate` en tu repositorio (añadirlo a `.gitignore`).
- Utilizar variables para puertos, nombres e imágenes.
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
- Los **principios básicos de Terraform**.  
- Cómo **integrar Docker y Nginx** con infraestructura como código.  
- Cómo **aplicar, validar y destruir** configuraciones de forma declarativa.  

Terraform te permite pasar de configuraciones manuales a despliegues reproducibles y automatizados.

---

> 🧩 **Autor:** Wilson Julca Mejía  
> **Curso:** DevOps  
> **Tema:** Infraestructura como Código con Terraform y Docker  
> **Versión:** 1.0
