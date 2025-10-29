# Tutorial: Provisionar API de Reconocimiento de Imágenes con AWS CloudFormation

## Objetivo

En este laboratorio aprenderás a provisionar una infraestructura completa en AWS utilizando CloudFormation que incluye:

- AWS Lambda (para procesamiento de imágenes)
- Amazon Rekognition (para análisis de imágenes)
- API Gateway (para exponer la funcionalidad como API REST)
- Roles y políticas de IAM (para permisos)

## Prerrequisitos

- Cuenta de AWS activa
- AWS CLI configurado (opcional pero recomendado)
- Postman instalado
- Archivo de imagen para pruebas

## Arquitectura de la Solución

```
Cliente (Postman) → API Gateway → Lambda → Rekognition
                                    ↓
                               CloudWatch Logs
```

## Parte 1: Provisionar la Infraestructura

### Paso 1: Acceder a CloudFormation

1. Inicia sesión en la **Consola de AWS**
2. Busca y selecciona **CloudFormation** en los servicios
3. Haz clic en **"Create stack"** → **"With new resources (standard)"**

### Paso 2: Cargar el Template

1. Selecciona **"Upload a template file"**
2. Haz clic en **"Choose file"** y selecciona `rekognition-template.yml`
3. Haz clic en **"Next"**

### Paso 3: Configurar el Stack

1. **Stack name**: Ingresa un nombre descriptivo (ej: `rekognition-api-stack`)
2. **Parameters**: Este template no requiere parámetros adicionales
3. Haz clic en **"Next"**

### Paso 4: Configurar Opciones del Stack

1. **Tags** (opcional): Puedes agregar tags para organización
   - Key: `Environment`, Value: `Lab`
   - Key: `Project`, Value: `Rekognition-API`
2. **Permissions**: Deja las opciones por defecto
3. Haz clic en **"Next"**

### Paso 5: Revisar y Crear

1. Revisa toda la configuración
2. ✅ Marca la casilla: **"I acknowledge that AWS CloudFormation might create IAM resources"**
3. Haz clic en **"Create stack"**

### Paso 6: Monitorear la Creación

1. Observa la pestaña **"Events"** para ver el progreso
2. El estado debe cambiar de `CREATE_IN_PROGRESS` a `CREATE_COMPLETE`
3. Este proceso toma aproximadamente 2-3 minutos

### Paso 7: Obtener la URL del API

1. Ve a la pestaña **"Outputs"**
2. Copia el valor de **"ApiEndpoint"**
3. Debería verse así: `https://xxxxxxxxxx.execute-api.region.amazonaws.com/prod/detect`

## Parte 2: Preparar Datos de Prueba

### Codificar Imagen en Base64

#### Opción A: Usando línea de comandos (macOS/Linux)

```bash
base64 -i car.jpeg -o imagen_base64.txt
```

#### Opción B: Usando herramientas online

1. Ve a: https://www.base64encode.org/
2. Carga tu imagen
3. Copia el resultado

#### Opción C: Usar la imagen proporcionada

El archivo `imagen_base64.txt` ya contiene una imagen codificada lista para usar.

## Parte 3: Probar con Postman

### Paso 1: Configurar la Petición

1. Abre **Postman**
2. Crea una nueva petición **POST**
3. URL: Pega la URL obtenida del Output de CloudFormation
4. Headers:
   - `Content-Type`: `application/json`

### Paso 2: Configurar el Body

1. Selecciona **"Body"** → **"raw"** → **"JSON"**
2. Ingresa el siguiente JSON:

```json
{
  "image": "AQUÍ_VA_EL_BASE64_DE_TU_IMAGEN"
}
```

**Ejemplo con imagen proporcionada:**

```json
{
  "image": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxMTEhUTExMWFRUXFxcYFxgYGBgWGxcXFRUWFxcWGBcYHSggGB0lHRUXITEiJSkrLi4uFx8zODMtNygtLisBCgoKDg0OGhAQGy0mHyUrLS8tLisuLS0rLS4tLS0rKystLS0vLTUtLS0tLS0tLS0tLS0tLS0rLS0tLS0tLS0rLf/AABEIAI4BYgMBIgACEQEDEQH/xAAcAAABBQEBAQAAAAAAAAAAAAAFAgMEBgcBAAj..."
}
```

### Paso 3: Enviar la Petición

1. Haz clic en **"Send"**
2. Deberías recibir una respuesta exitosa como:

```json
{
  "labels": ["Car", "Vehicle", "Transportation", "Automobile", "Sedan"]
}
```

## Parte 4: Análisis de Resultados

### Respuesta Exitosa (Status 200)

```json
{
  "labels": ["Car", "Vehicle", "Transportation", "Automobile", "Sedan"]
}
```

### Posibles Errores y Soluciones

#### Error 400 - Content-Type Incorrecto

```json
{
  "error": "Unsupported Content-Type. Only application/json is allowed."
}
```

**Solución**: Verificar que el header `Content-Type` sea `application/json`

#### Error 400 - Falta el Campo Image

```json
{
  "error": "Missing 'image' in JSON body."
}
```

**Solución**: Asegurar que el JSON tenga el campo `"image"`

#### Error 400 - Base64 Inválido

```json
{
  "error": "Invalid base64 image data"
}
```

**Solución**: Verificar que el string Base64 esté correctamente codificado

## Parte 5: Explorar la Infraestructura Creada

### Recursos Creados por CloudFormation

1. **IAM Role**: `RekognitionLambdaExecutionRole`

   - Permisos para Lambda, Rekognition y CloudWatch

2. **Lambda Function**: `RekognitionImageLabeler`

   - Runtime: Python 3.12
   - Timeout: 10 segundos
   - Memoria: 256 MB

3. **API Gateway**: `RekognitionApi`

   - Endpoint: `/detect` (POST)
   - Integración con Lambda

4. **CloudWatch Logs**: Automáticamente creados para Lambda

### Verificar los Recursos

#### Ver la Función Lambda

1. Ve a **AWS Lambda** en la consola
2. Busca `RekognitionImageLabeler`
3. Revisa el código y configuración

#### Ver el API Gateway

1. Ve a **API Gateway** en la consola
2. Busca `RekognitionApi`
3. Explora los recursos y métodos

#### Ver los Logs

1. Ve a **CloudWatch** → **Log groups**
2. Busca `/aws/lambda/RekognitionImageLabeler`
3. Revisa los logs de ejecución

## Parte 6: Pruebas Adicionales

### Test 1: Imagen de Persona

Prueba con una imagen que contenga personas para ver etiquetas como:

- `Person`, `Human`, `Face`, `Smile`, etc.

### Test 2: Imagen de Paisaje

Prueba con una imagen de paisaje para ver etiquetas como:

- `Nature`, `Landscape`, `Tree`, `Sky`, etc.

### Test 3: Imagen con Texto

Prueba con una imagen que contenga texto para ver si detecta:

- `Text`, `Document`, `Page`, etc.

## Parte 7: Monitoreo y Troubleshooting

### Ver Métricas en CloudWatch

1. Ve a **CloudWatch** → **Metrics**
2. Explora **AWS/Lambda** y **AWS/ApiGateway**
3. Observa métricas como:
   - Invocations
   - Duration
   - Errors
   - 4XXError, 5XXError

### Debugging Común

#### Si la API no responde:

1. Verificar que el stack se creó correctamente
2. Revisar logs de Lambda en CloudWatch
3. Verificar permisos de IAM

#### Si obtienes errores de Rekognition:

1. Verificar que tienes permisos para usar Rekognition
2. Confirmar que estás en una región que soporta Rekognition
3. Revisar el formato de la imagen (debe ser JPG o PNG)

## Parte 8: Cleanup (Limpiar Recursos)

### Eliminar el Stack

1. Ve a **CloudFormation**
2. Selecciona tu stack
3. Haz clic en **"Delete"**
4. Confirma la eliminación

**⚠️ Importante**: Esto eliminará todos los recursos creados y evitará cargos adicionales.

## Conceptos Clave Aprendidos

1. **Infrastructure as Code (IaC)**: Definir infraestructura mediante código
2. **AWS CloudFormation**: Servicio para provisionar recursos de AWS
3. **Serverless Architecture**: Usar Lambda sin gestionar servidores
4. **API Gateway**: Crear y gestionar APIs REST
5. **Amazon Rekognition**: Análisis de imágenes mediante ML
6. **IAM Roles**: Gestión de permisos y seguridad

## Preguntas de Reflexión

1. ¿Qué ventajas tiene usar CloudFormation vs crear recursos manualmente?
2. ¿Cómo modificarías el template para agregar más funcionalidades?
3. ¿Qué consideraciones de seguridad adicionales implementarías?
4. ¿Cómo escalarías esta solución para manejar más tráfico?

## Recursos Adicionales

- [Documentación de CloudFormation](https://docs.aws.amazon.com/cloudformation/)
- [Documentación de Rekognition](https://docs.aws.amazon.com/rekognition/)
- [Documentación de Lambda](https://docs.aws.amazon.com/lambda/)
- [Documentación de API Gateway](https://docs.aws.amazon.com/apigateway/)

---

## Anexos

### Template CloudFormation Explicado

El template `rekognition-template.yml` contiene:

1. **Rol IAM**: Define permisos necesarios
2. **Función Lambda**: Contiene la lógica de procesamiento
3. **API Gateway**: Expone la funcionalidad como API REST
4. **Outputs**: Proporciona la URL del endpoint

### Flujo de Datos

1. **Cliente** envía imagen (Base64) vía POST
2. **API Gateway** recibe y valida la petición
3. **Lambda** decodifica la imagen y llama a Rekognition
4. **Rekognition** analiza la imagen y retorna etiquetas
5. **Lambda** procesa la respuesta y la retorna
6. **API Gateway** envía la respuesta al cliente

¡Felicidades! Has completado el tutorial de provisión de infraestructura con CloudFormation y pruebas con Postman.
