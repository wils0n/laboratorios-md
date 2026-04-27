# 🧩 Guía Práctica: ReplicaSet en Kubernetes

**Continuación de la guía anterior: Pods, Deployments y YAML**

---

## 🎯 1. Objetivo de la práctica

Aprender a crear, validar, escalar y administrar un **ReplicaSet**, el recurso moderno que reemplaza al **ReplicationController** en Kubernetes.

---

## ⚙️ 2. Preparación del entorno

1. Abrir **Visual Studio Code**.
2. Abrir la carpeta del proyecto `kubernetes` en tu directorio de usuario.
3. Crear un nuevo archivo llamado:

   ```bash
   rs-test.yaml
   ```
4. Abrir dos editores en paralelo (**Split Editor Right**) para ver el archivo del Pod anterior y este nuevo.

---

## 📘 3. Crear el archivo ReplicaSet

En el archivo `rs-test.yaml`, define la siguiente estructura base:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: app1-rs
  labels:
    app: app1
    type: frontend
spec:
  replicas: 4
  selector:
    matchLabels:
      app: app1
      type: frontend
  template:
    metadata:
      labels:
        app: app1
        type: frontend
    spec:
      containers:
        - name: nginx-container
          image: nginx
          ports:
            - containerPort: 80
```

### 🔍 Explicación

| Campo | Descripción |
|-------|--------------|
| **apiVersion** | `apps/v1`, versión moderna para controladores. |
| **kind** | Indica el tipo de objeto: `ReplicaSet`. |
| **metadata** | Nombre y etiquetas identificadoras. |
| **spec.replicas** | Número de réplicas deseadas (Pods). |
| **selector** | Filtro obligatorio que indica qué Pods controla. |
| **template** | Plantilla del Pod que se replicará. |

---

## ✅ 4. Validación del YAML

1. Copiar el contenido en [Code Beautify YAML Validator](https://codebeautify.org/yaml-validator).
2. Validar que no existan errores de indentación ni estructura.

---

## 🚀 5. Crear el ReplicaSet en Kubernetes

Desde la terminal:

```bash
kubectl apply -f rs-test.yaml
```

Verifica su creación:

```bash
kubectl get replicaset
kubectl get pods
```

Deberías ver algo como:

```
NAME       DESIRED   CURRENT   READY   AGE
app1-rs    4         4         4       10s
```

---

## 🔎 6. Describir el ReplicaSet

```bash
kubectl describe replicaset app1-rs
```

Esto mostrará:
- Nombre, etiquetas y selector.
- Eventos de creación.
- Pods asociados.

---

## 🔄 7. Probar la autorreparación

1. Eliminar uno de los Pods creados:

   ```bash
   kubectl delete pod <nombre-del-pod>
   ```

2. Verifica que Kubernetes crea uno nuevo automáticamente:

   ```bash
   kubectl get pods
   ```

> 💡 **ReplicaSet asegura que el número de réplicas siempre se mantenga.**

---

## ⚙️ 8. Escalar el ReplicaSet

### 🔼 Escalar desde el archivo YAML

1. Editar el valor de `replicas` a `6`.
2. Guardar y aplicar cambios:

   ```bash
   kubectl apply -f rs-test.yaml
   ```

### 🔽 Escalar desde la terminal

```bash
kubectl scale --replicas=2 -f rs-test.yaml
```

Verifica los cambios:

```bash
kubectl get replicaset
kubectl get pods
```

> ⚠️ Nota: el comando `scale` **no actualiza el archivo YAML**, solo el estado en el clúster.

---

## 🧹 9. Eliminar recursos

```bash
kubectl delete replicaset app1-rs
kubectl delete -f rs-test.yaml
```

---

## 🧠 10. Recomendaciones finales

- Usa siempre **ReplicaSet** o **Deployment** en lugar de ReplicationController.  
- Mantén tus YAMLs **validados y versionados** (Git).  
- Para producción, **usa Deployments**, ya que gestionan los ReplicaSets automáticamente.  
- ReplicaSet es ideal para **entender el funcionamiento interno de Deployments**.

---

📘 **Autor:**  
Wilson Julca Mejía  
Curso: *DevOps y Kubernetes – Práctica de ReplicaSets*  
Universidad de Ingeniería y Tecnología (UTEC)
