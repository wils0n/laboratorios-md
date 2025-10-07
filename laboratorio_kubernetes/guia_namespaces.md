# 🗂️ Guía Práctica: **Namespaces y Contextos en Kubernetes**

**Continuación de la serie:** Pods → ReplicaSets → Deployments → Services → **Namespaces y Contextos**

---

## 🎯 1. Objetivo

Aprender a crear, usar y administrar **Namespaces** y **Contextos** en Kubernetes, para:

* Organizar los recursos del clúster por proyectos, entornos o equipos.
* Aplicar **cuotas de recursos**, **controles de acceso (RBAC)** y **políticas de red**.
* Cambiar fácilmente de un entorno a otro con **contextos** (`kubectl config`).

---

## 🧩 2. ¿Qué es un Namespace?

Un **Namespace** es una agrupación **lógica de recursos** dentro del clúster Kubernetes.

Permite:

* Separar aplicaciones o entornos (e.g. `development`, `staging`, `production`).
* Aplicar políticas de seguridad, límites de CPU/RAM o acceso de usuarios.
* Evitar colisiones de nombres (dos Pods pueden llamarse igual si están en distintos Namespaces).

🔸 *No* aísla completamente el tráfico entre Pods ni usuarios por defecto.
Para lograr aislamiento real se deben aplicar:

* **NetworkPolicies** → para limitar comunicación entre Namespaces.
* **RBAC (Role-Based Access Control)** → para restringir usuarios y permisos.
* **ResourceQuotas** → para limitar recursos consumidos.

---

## ⚙️ 3. Namespaces por defecto en Kubernetes

```bash
kubectl get namespaces
```

Resultado típico:

| Nombre            | Descripción                                                                               |
| ----------------- | ----------------------------------------------------------------------------------------- |
| `default`         | Namespace por defecto (donde se crean los objetos si no se indica otro).                  |
| `kube-system`     | Contiene los componentes internos del clúster (scheduler, controller-manager, DNS, etc.). |
| `kube-public`     | Acceso público de solo lectura (visible por todos los usuarios).                          |
| `kube-node-lease` | Gestiona el *heartbeat* de los nodos (control de salud).                                  |

---

## 🧱 4. Crear y usar un Namespace

### 📘 Crear un Namespace

```bash
kubectl create namespace development
```

Verificar:

```bash
kubectl get ns
```

### 📘 Crear recursos dentro del Namespace

```bash
kubectl run nginx --image=nginx --namespace=development
```

o con abreviatura:

```bash
kubectl run nginx --image=nginx -n development
```

### 📘 Listar Pods de un Namespace específico

```bash
kubectl get pods -n development
```

Si no especificas `-n`, se usa el Namespace `default`.

---

## 🧱 5. Namespaces en proyectos web reales

En entornos empresariales, los Namespaces se estructuran por entorno o función:

| Namespace             | Propósito      | Ejemplo de uso                                          |
| --------------------- | -------------- | ------------------------------------------------------- |
| `dev`                 | Desarrollo     | Pruebas iniciales de features; sin alta disponibilidad. |
| `staging`             | Pre-producción | Validación QA e integración continua.                   |
| `prod`                | Producción     | Entorno estable con tráfico real.                       |
| `monitoring`          | Observabilidad | Prometheus, Grafana, Loki, etc.                         |
| `ingress` o `gateway` | Networking     | Controladores Ingress y TLS.                            |
| `cicd` o `tools`      | Automatización | Jenkins, ArgoCD, GitLab Runner.                         |

### 📁 Ejemplo de estructura real

```
.
├── namespace-dev/
│   ├── app-deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── configmap.yaml
├── namespace-staging/
│   ├── app-deployment.yaml
│   └── service.yaml
├── namespace-prod/
│   ├── app-deployment.yaml
│   ├── hpa.yaml
│   └── ingress.yaml
└── namespace-monitoring/
    ├── prometheus/
    ├── grafana/
    └── loki/
```

### ⚙️ Ventajas

* Aislamiento lógico y control por equipo o entorno.
* Facilita aplicar RBAC, cuotas y políticas.
* Despliegue seguro sin interferir con otros entornos.

### 🧩 YAML recomendado

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: development
    team: frontend
```

Aplicar:

```bash
kubectl apply -f namespace-dev.yaml
```

---

## 💾 6. Ejemplo: Cuotas y límites de recursos por Namespace

Kubernetes permite asignar **ResourceQuotas** y **LimitRanges** a cada Namespace para controlar el uso de recursos (CPU, memoria, objetos creados, etc.).

### 📘 Ejemplo de ResourceQuota

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "10"
    configmaps: "5"
    persistentvolumeclaims: "3"
```

### 📘 Ejemplo de LimitRange

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: dev-limits
  namespace: dev
spec:
  limits:
    - default:
        cpu: 500m
        memory: 512Mi
      defaultRequest:
        cpu: 200m
        memory: 256Mi
      type: Container
```

Aplicar:

```bash
kubectl apply -f dev-quota.yaml
kubectl apply -f dev-limits.yaml
```

📊 Estos objetos garantizan que cada Namespace use los recursos del clúster de manera controlada.

---

## 🧹 7. Eliminar un Namespace

```bash
kubectl delete namespace development
```

> ⚠️ Este comando elimina **todo el contenido** del Namespace: Pods, Services, ConfigMaps, Secrets, etc.
> Verifica antes de ejecutarlo con:

```bash
kubectl get all -n development
```

---

## 🧭 8. Contextos en Kubernetes

Los **contextos** permiten cambiar rápidamente entre:

* Diferentes **clusters**.
* Diferentes **usuarios**.
* Diferentes **namespaces** predeterminados.

Cada contexto se define en el archivo de configuración `~/.kube/config`.

```bash
kubectl config view
```

Muestra la configuración actual (clusters, usuarios y contextos disponibles).

---

## 🔧 9. Cambiar de contexto y Namespace

### 📘 Establecer el Namespace por defecto para el contexto actual

```bash
kubectl config set-context --current --namespace=development
```

Ahora, cualquier comando `kubectl` se ejecutará automáticamente sobre `development`.

Verificar:

```bash
kubectl config view --minify | grep namespace:
```

Volver al Namespace por defecto:

```bash
kubectl config set-context --current --namespace=default
```

---

## 🧠 10. Buenas prácticas

✅ Usa un Namespace **por entorno** o **por aplicación** (p. ej. `dev`, `staging`, `prod`).
✅ Implementa **RBAC** para restringir accesos.
✅ Aplica **ResourceQuotas** para evitar consumo excesivo.
✅ No modifiques Namespaces del sistema (`kube-system`, `kube-public`).
✅ Versiona tus Namespaces y políticas YAML en Git (Infraestructura como Código).
✅ Automatiza la creación de Namespaces en pipelines CI/CD.
✅ Protege `prod` con RBAC y NetworkPolicies.

---

📘 **Autor:**
Wilson Julca Mejía
Curso: *DevOps y Kubernetes – Namespaces y Contextos*
Universidad de Ingeniería y Tecnología (UTEC)
