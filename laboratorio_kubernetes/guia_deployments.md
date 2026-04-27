# 🚀 Guía Práctica: Deployments en Kubernetes

**Continuación de la guía anterior: ReplicaSets y Pods**

---

## 🎯 1. Objetivo de la práctica

Aprender a crear, validar, escalar y administrar un **Deployment**, el controlador más usado en Kubernetes para desplegar aplicaciones de manera confiable, con actualizaciones continuas (*rolling updates*) y reversión de cambios (*rollback*).

---

## ⚙️ 2. Preparación del entorno

1. Abre **Visual Studio Code**.
2. Asegúrate de tener abierta la carpeta `kubernetes` en tu directorio de usuario.
3. Crea un nuevo archivo llamado:

   ```bash
   dep-test.yaml
   ```

4. Abre el archivo anterior `rs-test.yaml` en una pestaña lateral (**Split Editor Right**) para comparar.

---

## 📘 3. Crear el archivo Deployment

En el archivo `dep-test.yaml`, define la siguiente estructura base:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1-dep
  labels:
    app: app1
    type: frontend
spec:
  replicas: 5
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
          image: nginx:latest
          ports:
            - containerPort: 80
```

### 🔍 Explicación

| Campo | Descripción |
|-------|--------------|
| **apiVersion** | `apps/v1`, versión moderna para Deployments. |
| **kind** | Especifica el tipo de objeto: `Deployment`. |
| **metadata** | Nombre y etiquetas del Deployment. |
| **spec.replicas** | Número de réplicas (Pods) que se desean ejecutar. |
| **selector** | Define las etiquetas que el Deployment usará para gestionar los Pods. |
| **template** | Plantilla del Pod que será replicado automáticamente. |

---

## ✅ 4. Validación del YAML

1. Copia el contenido en [Code Beautify YAML Validator](https://codebeautify.org/yaml-validator).
2. Asegúrate de que no existan errores de indentación o estructura.

---

## 🚀 5. Crear el Deployment en Kubernetes

Ejecuta en la terminal:

```bash
kubectl apply -f dep-test.yaml
```

Verifica que el Deployment, ReplicaSet y Pods se hayan creado correctamente:

```bash
kubectl get all
```

Deberías ver algo como:

```
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/app1-dep       5/5     5            5           15s
replicaset.apps/app1-dep-xyz   5       5            5           15s
pod/app1-dep-xyz-abc12         1/1     Running       0          15s
```

---

## 🔎 6. Describir el Deployment

```bash
kubectl describe deployment app1-dep
```

Podrás ver:
- Etiquetas y selector
- Réplicas disponibles y deseadas
- Estrategia de actualización (RollingUpdate)
- Eventos recientes (creación, escalado, etc.)

---

## 🔄 7. Escalar el Deployment

### 🔼 Escalar desde la terminal

```bash
kubectl scale deployment app1-dep --replicas=2
```

### 🔽 Escalar desde el archivo YAML

1. Cambia `replicas: 5` por `replicas: 2`.
2. Guarda el archivo y aplica los cambios:

   ```bash
   kubectl apply -f dep-test.yaml
   ```

Verifica el resultado:

```bash
kubectl get deployment app1-dep
kubectl get pods
```

> ⚠️ Recuerda: el comando `scale` no modifica tu archivo YAML, solo el estado en el clúster.

---

## ♻️ 8. Actualizar la imagen (Rolling Update)

```bash
kubectl set image deployment/app1-dep nginx-container=nginx:1.27
```

Verifica el progreso:

```bash
kubectl rollout status deployment/app1-dep
```

Y si ocurre un error:

```bash
kubectl rollout undo deployment/app1-dep
```

> 💡 Kubernetes reemplaza los Pods de forma gradual para mantener disponibilidad (cero downtime).

---

## ⏸️ 9. Pausar y reanudar un despliegue

```bash
kubectl rollout pause deployment/app1-dep
# Realiza cambios (por ejemplo, actualiza imagen o réplicas)
kubectl rollout resume deployment/app1-dep
```

Esta práctica es útil para aplicar múltiples cambios controladamente.

---

## 🧹 10. Eliminar recursos

```bash
kubectl delete deployment app1-dep
kubectl delete -f dep-test.yaml
```

Verifica que solo quede el servicio del clúster:

```bash
kubectl get all
```

---

## 🧠 11. Recomendaciones finales

- En **producción**, los *Deployments* son la **forma estándar** de desplegar aplicaciones.
- Usan internamente un **ReplicaSet**, lo que permite **rolling updates** y **rollback** sin downtime.
- Versiona tus archivos YAML en Git para mantener trazabilidad.
- Combina Deployments con **Services** y **Ingress** para exponer tus apps.

---

📘 **Autor:**  
Wilson Julca Mejía  
Curso: *DevOps y Kubernetes – Práctica de Deployments*  
Universidad de Ingeniería y Tecnología (UTEC)
