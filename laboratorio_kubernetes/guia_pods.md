# 🧬 Guía: Diferencia entre **Pods Directos** y **Pods desde YAML** en Kubernetes

## 🌟 1. Conceptos básicos

| Concepto       | Descripción                                                                                                                                                                               |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pod**        | Unidad más pequeña que se puede crear y administrar en Kubernetes. Contiene uno o más contenedores que comparten red y almacenamiento.                                                    |
| **Pod YAML**   | Objeto definido en un archivo **YAML**, usado para crear Pods de forma declarativa, ideal para automatización e infraestructura como código.                                              |

---

## ⚙️ 2. Crear un Pod directo

Se usa para pruebas simples o demostraciones.

### 📘 Comando

```bash
kubectl run my-nginx --image=nginx --restart=Never
```
o 

```bash
kubectl run my-nginx --image=nginx --restart=Never -n default
```

### 📘 Explicación

* `run` → crea un objeto ejecutable (por defecto, un Pod).
* `--image=nginx` → especifica la imagen del contenedor.
* `--restart=Never` → indica que **no debe recrearse automáticamente** (sin ReplicaSet ni Deployment).

### 📊 Resultado

* Se crea **solo un Pod**.
* No hay controladores asociados.

### 📘 Verificación

```bash
kubectl get pods
kubectl get all
```

### 📘 Eliminación

```bash
kubectl delete pod my-nginx
```

### ✅ Ventajas

* Rápido para pruebas o laboratorios.
* Ideal para ejecutar una app temporal.

### ⚠️ Desventajas

* Si el Pod falla o se elimina, **no se recrea automáticamente**.
* No permite actualizaciones ni escalado automático.

---


## 🗾️ 3. Crear Pods desde un archivo YAML

Kubernetes utiliza **archivos YAML** como entrada para crear objetos como Pods, Deployments o Services. Estos archivos definen la estructura del objeto de forma **declarativa**.

### 📘 Estructura básica de un Pod en YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app1-pod
  labels:
    app: app1
    type: frontend
spec:
  containers:
    - name: nginx-container
      image: nginx
```

### 📘 Campos principales

| Campo          | Descripción                                                                  |
| -------------- | ---------------------------------------------------------------------------- |
| **apiVersion** | Versión de la API de Kubernetes. Para Pods es `v1`.                          |
| **kind**       | Tipo de objeto a crear (`Pod`, `Service`, `Deployment`, etc.).               |
| **metadata**   | Contiene información del objeto como `name` y `labels`.                      |
| **spec**       | Define el comportamiento del objeto (contenedores, imágenes, puertos, etc.). |

### 🧠 Conceptos clave

* `metadata` y `spec` son **diccionarios**, mientras que `containers` es una **lista**.
* Cada contenedor dentro de `containers` tiene propiedades como `name` e `image`.
* Las **labels** permiten identificar y filtrar Pods fácilmente.

### 🤪 Crear un Pod desde YAML

```bash
kubectl create -f pod-test.yaml
```

O también:

```bash
kubectl apply -f pod-test.yaml
```

> `apply` es el método más usado porque sirve tanto para **crear** como para **actualizar** objetos.

### 📘 Verificación

```bash
kubectl get pods
kubectl describe pod app1-pod
kubectl get all
```

### 📘 Eliminación

```bash
kubectl delete pod app1-pod
```

### 💡 Validación del archivo YAML

Puedes usar la herramienta **[Code Beautify YAML Validator](https://codebeautify.org/yaml-validator)** para verificar la estructura de tus archivos YAML antes de aplicarlos.

---

## 📊 5. Comparación rápida

| Característica        | **Pod directo**                 | **Pod por YAML**                |
| --------------------- | ------------------------------- | ------------------------------- |
| **Creación**          | `kubectl run … --restart=Never` | `kubectl apply -f archivo.yaml` |
| **Controlador**       | Ninguno                         | Ninguno (definido manualmente)  |
| **Auto-recuperación** | ❌ No se recrea                 | ❌ No se recrea                  |
| **Escalabilidad**     | Manual                          | Manual (editando YAML)          |
| **Actualización**     | Manual                          | Manual (editando YAML)          |
| **Uso recomendado**   | Pruebas rápidas                 | Infraestructura como código     |

---

## 🧠 6. Recomendaciones prácticas

* Usa **Pods directos** para **probar imágenes o comandos simples**.
* Usa **YAML** para **infraestructura como código**, reutilizable y versionable en Git.

---

## 🧪 7. Comandos útiles de repaso

```bash
# Crear un Pod directo
kubectl run test-pod --image=nginx --restart=Never

# Crear un Pod desde YAML
kubectl apply -f pod-test.yaml

# Ver objetos
kubectl get all

# Describir detalles
kubectl describe pod test-pod

# Eliminar recursos
kubectl delete pod test-pod
kubectl delete -f pod-test.yaml
```

---

📘 **Autor:**
Wilson Julca Mejía
Curso: *DevOps y Kubernetes – Práctica de Pods, Deployments y YAML*
Universidad de Ingeniería y Tecnología (UTEC)
