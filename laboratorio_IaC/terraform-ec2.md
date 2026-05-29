# 🖥️ Guía: Desplegar un servidor web en EC2 con Terraform

## 🎯 Objetivo
Aprender a crear infraestructura de cómputo en AWS usando Terraform: una instancia **EC2** con **nginx** y un **Security Group** para controlar el acceso.

---

## 🧠 1. Nuevos conceptos respecto al lab anterior (S3)

| Concepto | Descripción |
|-----------|-------------|
| **Data Source** | Lee información existente en AWS (ej. AMI más reciente) sin crear recursos. |
| **Security Group** | Firewall virtual que controla tráfico entrante y saliente de la instancia. |
| **aws_instance** | Recurso principal de cómputo EC2 (servidor virtual). |
| **user_data** | Script que se ejecuta automáticamente al arrancar la instancia. |
| **depends_on** | Fuerza el orden de creación entre recursos con dependencias implícitas. |

---

## 🔑 2. Prerrequisito: Credenciales AWS

Terraform usa las mismas credenciales que AWS CLI. Sin ellas, no puede crear recursos en tu cuenta.

### Opción A — AWS CLI (recomendado para alumnos)
```bash
aws configure
# Solicita: Access Key ID, Secret Access Key, región, output format
```
Terraform lee automáticamente `~/.aws/credentials`.

### Opción B — Variables de entorno (útil en CI/CD)
```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

### Verificar que las credenciales funcionan
```bash
aws sts get-caller-identity
```
Debe devolver tu `Account`, `UserId` y `Arn`. Si falla, Terraform tampoco podrá conectarse.

> ⚠️ **AWS Academy / Learner Lab:** Las credenciales cambian cada sesión.
> Ve a **AWS Details** → copia las credenciales → pégalas en `~/.aws/credentials` o expórtalas como variables de entorno antes de cada `terraform apply`.

---

## ⚙️ 3. Arquitectura del lab

```
Internet
   │
   ▼
Security Group (puerto 80 HTTP, puerto 22 SSH)
   │
   ▼
EC2 Instance (Amazon Linux 2023 + nginx)
   │
   └── user_data.sh instala y configura nginx al arrancar
```

---

## 🗂️ 3. Estructura del proyecto

```
ec2/
├── main.tf
├── variables.tf
└── user_data.sh
```

---

## 📄 4. Configuración paso a paso

### 4.1 Provider

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

---

### 4.2 Data Source: AMI más reciente

En lugar de hardcodear un AMI ID (que cambia por región), usamos un **data source** para obtenerlo dinámicamente:

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
```

> **¿Por qué es útil?** El mismo código funciona en cualquier región sin modificación.

---

### 4.3 Security Group

```hcl
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Permite HTTP y SSH"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}
```

---

### 4.4 Instancia EC2

```hcl
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = file("${path.module}/user_data.sh")

  tags = {
    Name = "web-server"
  }
}
```

### main.tf completo
```bash
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Permite HTTP y SSH"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data.sh")

  tags = {
    Name = "web-server"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "website_url" {
  value = "http://${aws_instance.web.public_dns}"
}
```

---

### 4.5 Script de arranque (user_data.sh)

```bash
#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl start nginx
systemctl enable nginx

cat > /usr/share/nginx/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Servidor EC2 - Terraform</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background-color: #1a1a2e;
    }
    .card {
      background: white;
      border-radius: 12px;
      padding: 40px 60px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.3);
      text-align: center;
    }
    h1 { color: #232f3e; }
    p  { color: #555; }
    .badge {
      display: inline-block;
      background: #232f3e;
      color: #ff9900;
      padding: 6px 16px;
      border-radius: 20px;
      font-size: 0.85rem;
      margin-top: 16px;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>🖥️ Servidor EC2 con Terraform</h1>
    <p>Esta instancia fue creada y configurada usando <strong>Terraform</strong>.</p>
    <p>nginx instalado automáticamente via <strong>user_data</strong></p>
    <p>Infraestructura como Código — DevOps UTEC</p>
    <span class="badge">AWS EC2 + nginx + Terraform</span>
  </div>
</body>
</html>
EOF
```

---

### 4.6 Outputs

```hcl
output "public_ip" {
  value = aws_instance.web.public_ip
}

output "website_url" {
  value = "http://${aws_instance.web.public_dns}"
}
```

---

## 🚀 5. Ejecución

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

> Después de `apply`, espera ~1 minuto para que `user_data` termine de instalar nginx.

Verifica:
```bash
curl http://<public_ip>
```

---

## 🔍 6. Comparar con el lab de S3

| Aspecto | S3 Static Site | EC2 + nginx |
|---------|---------------|-------------|
| Tipo de recurso | Almacenamiento | Cómputo |
| Servidor web | Gestionado por AWS | Tú lo instalas (nginx) |
| Data sources | No usa | `aws_ami` para AMI dinámica |
| Networking | Política de bucket | Security Group |
| Bootstrap | No aplica | `user_data.sh` |
| Costo Free Tier | Gratuito | t2.micro / t3.micro gratuito |

---

## 🧹 7. Eliminar recursos

```bash
terraform destroy
```

---

## 🧰 8. Variables

### variables.tf
```hcl
variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

---

## 💡 9. Buenas prácticas

- Nunca abrir puerto 22 a `0.0.0.0/0` en producción — usa tu IP específica.
- Usar `t2.micro` o `t3.micro` para mantenerse en Free Tier.
- El `user_data` solo se ejecuta **una vez** al crear la instancia.
- Verificar el AMI ID correcto para la región con el data source.

---

## 🎓 Conclusión

Con este lab aprendiste:
- Usar **data sources** para obtener información dinámica de AWS.
- Crear y asociar **Security Groups** a instancias EC2.
- Automatizar la configuración inicial con **user_data**.
- La diferencia entre infraestructura de **almacenamiento** y **cómputo** en Terraform.

---

> 🧩 **Autor:** Wilson Julca Mejía  
> **Curso:** DevOps  
> **Tema:** Infraestructura como Código — EC2 + Security Group con Terraform  
> **Versión:** 1.0
