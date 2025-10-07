# 🧬 Guía: Diferencia entre **Pods Directos**, **Deployments** y **Pods desde YAML** en Kubernetes

## 🌟 1. Conceptos básicos

| Concepto       | Descripción                                                                                                                                                                               |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pod**        | Unidad más pequeña que se puede crear y administrar en Kubernetes. Contiene uno o más contenedores que comparten red y almacenamiento.                                                    |
| **Deployment** | Objeto de Kubernetes que **gestiona automáticamente** la creación, actualización y eliminación de Pods. Usa internamente un **ReplicaSet** para garantizar el número deseado de réplicas. |
| **Pod YAML**   | Objeto definido en un archivo **YAML**, usado para crear Pods de forma declarativa, ideal para automatización e infraestructura como código.                                              |

---

## ⚙️ 2. Crear un Pod directo

Se usa para pruebas simples o demostraciones.

### 📘 Comando

```bash
kubectl run my-nginx --image=nginx --restart=Never
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

## 🚀 3. Crear un Deployment

Se usa en entornos reales o cuando se necesita alta disponibilidad.

### 📘 Comando

```bash
kubectl create deployment my-nginx --image=nginx
```

### 📘 Explicación

* Crea un **Deployment** que a su vez genera un **ReplicaSet** y un **Pod**.
* Kubernetes **asegura que siempre haya las réplicas necesarias**.

### 📊 Resultado

* Se crean **3 objetos**:

  1. Deployment
  2. ReplicaSet
  3. Pod

### 📘 Verificación

```bash
kubectl get all
kubectl describe deployment my-nginx
```

### 📘 Escalar el Deployment

```bash
kubectl scale deployment my-nginx --replicas=3
```

### 📘 Actualizar la imagen

```bash
kubectl set image deployment/my-nginx nginx=nginx:latest
```

### 📘 Eliminación

```bash
kubectl delete deployment my-nginx
```

### ✅ Ventajas

* Tolerancia a fallos (los Pods se recrean automáticamente).
* Permite **escalar, actualizar y revertir versiones**.
* Ideal para **producción** o servicios persistentes.

### ⚠️ Desventajas

* Menos directo para pruebas rápidas.
* Involucra más recursos (ReplicaSet, controladores).

---

## 🗾️ 4. Crear Pods desde un archivo YAML

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

| Característica        | **Pod directo**                 | **Deployment**                      | **Pod por YAML**                |
| --------------------- | ------------------------------- | ----------------------------------- | ------------------------------- |
| **Creación**          | `kubectl run … --restart=Never` | `kubectl create deployment …`       | `kubectl apply -f archivo.yaml` |
| **Controlador**       | Ninguno                         | ReplicaSet y Deployment             | Ninguno (definido manualmente)  |
| **Auto-recuperación** | ❌ No se recrea                  | ✅ Se recrea automáticamente         | ❌ No se recrea                  |
| **Escalabilidad**     | Manual                          | Automática (`--replicas`)           | Manual (editando YAML)          |
| **Actualización**     | Manual                          | Controlada (`set image`, `rollout`) | Manual (editando YAML)          |
| **Uso recomendado**   | Pruebas rápidas                 | Producción                          | Infraestructura como código     |

---

## 🧠 6. Recomendaciones prácticas

* Usa **Pods directos** para **probar imágenes o comandos simples**.
* Usa **Deployments** para **entornos productivos o con escalado**.
* Usa **YAML** para **infraestructura como código**, reutilizable y versionable en Git.

---

## 🧪 7. Comandos útiles de repaso

```bash
# Crear un Pod directo
kubectl run test-pod --image=nginx --restart=Never

# Crear un Deployment
kubectl create deployment web-deploy --image=nginx

# Crear un Pod desde YAML
kubectl apply -f pod-test.yaml

# Ver objetos
kubectl get all

# Describir detalles
kubectl describe pod test-pod
kubectl describe deployment web-deploy

# Escalar un Deployment
kubectl scale deployment web-deploy --replicas=3

# Eliminar recursos
kubectl delete pod test-pod
kubectl delete deployment web-deploy
kubectl delete -f pod-test.yaml
```

---

📘 **Autor:**
Wilson Julca Mejía
Curso: *DevOps y Kubernetes – Práctica de Pods, Deployments y YAML*
Universidad de Ingeniería y Tecnología (UTEC)
