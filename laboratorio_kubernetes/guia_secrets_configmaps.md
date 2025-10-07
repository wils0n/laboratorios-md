# 🔐 Guía Práctica: **Secrets y ConfigMaps** en Kubernetes
**Continuación de la serie:** Pods → ReplicaSets → Deployments → Services → Namespaces → **Secrets & ConfigMaps**

> Basado en el tutorial del curso y buenas prácticas actuales de Kubernetes (v1.30+).

---

## 🎯 Objetivo
Aprender a **proteger datos sensibles** y **parametrizar configuración** de tus aplicaciones con:
- **Secrets**: credenciales, tokens, claves TLS, etc.
- **ConfigMaps**: variables no sensibles (puertos, hosts, flags).
- Consumo por **variables de entorno** y por **volúmenes**.
- Buenas prácticas (RBAC, encryption at rest, rotación, GitOps).

---

## 🧠 Conceptos clave
- Ambos son objetos *namespaced* (viven dentro de un **Namespace**).
- **Secrets** almacenan datos **codificados en Base64** (⚠️ no es cifrado). Activa **encryption at rest** y aplica **RBAC**.
- **ConfigMaps** almacenan pares **clave/valor** no sensibles.
- Se montan en Pods como **env vars** o **archivos** (volúmenes).
- Puedes referenciarlos desde **Deployments** / **StatefulSets** / **Jobs**, etc.

---

## 🧱 Estructura de laboratorio
Usaremos el namespace `app-secrets` y un Deployment de ejemplo:

```bash
kubectl create namespace app-secrets
kubectl config set-context --current --namespace=app-secrets
```

---

## 🔑 1) Crear **Secrets**

### A. `generic` desde literales
```bash
kubectl create secret generic db-secret   --from-literal=DB_USER=myapp   --from-literal=DB_PASSWORD=devops123
```

### B. `generic` desde archivo(s)
```bash
# Ejemplos: ./secrets/password.txt, ./secrets/api-token
kubectl create secret generic api-secret --from-file=./secrets/
```

### C. `docker-registry` (pull de imágenes privadas)
```bash
kubectl create secret docker-registry regcred   --docker-server=REGISTRY_URL   --docker-username=USER   --docker-password=TOKEN_OR_PASSWORD   --docker-email=email@org.com
```

### D. `tls` (para Ingress HTTPS)
```bash
kubectl create secret tls site-tls   --cert=fullchain.pem --key=privkey.pem
```

**Ver y describir**
```bash
kubectl get secrets
kubectl describe secret db-secret
kubectl get secret db-secret -o yaml   # datos en base64
```

**Decodificar (para entender la codificación, no para exponer en prod)**:
```bash
# Ejemplo en bash
echo -n "ZGV2b3BzMTIz" | base64 --decode
```

> 💡 En YAML puedes usar `stringData:` para escribir valores **en claro** (K8s los convertirá a `data` base64 al guardar).

---

## ⚙️ 2) Crear **ConfigMaps**

### A. Desde literales
```bash
kubectl create configmap app-config   --from-literal=APP_ENV=dev   --from-literal=APP_PORT=8080   --from-literal=DB_HOST=postgres
```

### B. Desde archivos o directorios
```bash
kubectl create configmap nginx-conf --from-file=./nginx/
```

**Ver y describir**
```bash
kubectl get configmaps
kubectl describe configmap app-config
kubectl get configmap app-config -o yaml
```

---

## 🧪 3) Consumo en Pods (env vars y volúmenes)

### A. Deployment con **envFrom** (carga todo el Secret/ConfigMap)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  labels: { app: demo }
spec:
  replicas: 2
  selector: { matchLabels: { app: demo } }
  template:
    metadata:
      labels: { app: demo }
    spec:
      containers:
        - name: app
          image: nginx:1.26-alpine
          ports: [{ containerPort: 8080 }]
          envFrom:
            - secretRef:    { name: db-secret }   # DB_USER, DB_PASSWORD
            - configMapRef: { name: app-config }  # APP_ENV, APP_PORT, DB_HOST
```

### B. Deployment con **env** (clave puntual)
```yaml
# Fragmento dentro del container
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: DB_PASSWORD
  - name: APP_PORT
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: APP_PORT
```

### C. Montaje como **volumen** (archivos)
```yaml
# Fragmento dentro del Pod spec
volumes:
  - name: secret-vol
    secret:
      secretName: db-secret
  - name: cfg-vol
    configMap:
      name: app-config

containers:
  - name: app
    image: nginx:1.26-alpine
    volumeMounts:
      - name: secret-vol
        mountPath: /etc/secrets        # crea ficheros por cada clave (p.ej. /etc/secrets/DB_PASSWORD)
        readOnly: true
      - name: cfg-vol
        mountPath: /etc/config         # (p.ej. /etc/config/APP_PORT)
        readOnly: true
```

**Aplicar y validar**
```bash
kubectl apply -f deployment-demo.yaml
kubectl get pods
kubectl describe pod <pod-name>
kubectl exec -it <pod-name> -- sh

# Dentro del contenedor:
printenv | grep -E 'DB_|APP_'
ls -1 /etc/secrets /etc/config
```

> 🔁 Cambios en Secrets/ConfigMaps **no recargan automáticamente** los procesos. Suele requerir **restart/rollout** del pod (`kubectl rollout restart deploy demo-app`).

---

## 🧰 4) Integración con imágenes privadas
En el `PodSpec` puedes usar el Secret `regcred` para pulls privados:
```yaml
imagePullSecrets:
  - name: regcred
```

---

## 🔒 5) Buenas prácticas
- **RBAC**: limita quién puede leer/crear **Secrets** (más restrictivo que ConfigMaps).
- **Encryption at rest**: habilita cifrado de Secrets en etcd (en clústeres gestionados suele venir activado o configurable).
- **Rotación**: rota credenciales; usa `rollout restart` para propagar cambios.
- **GitOps**: guarda ConfigMaps en Git; para Secrets, evita texto plano. Considera:
  - **Sealed Secrets** (Bitnami) o **External Secrets Operator** (AWS/GCP/Azure).
- **Namespacing**: separa por entornos (`dev`, `staging`, `prod`) y aplica **ResourceQuota** / **LimitRange** por namespace.
- **Auditoría**: `kubectl get events -A`, *audit logs* del clúster, OPA/Gatekeeper si necesitas políticas.
- **No** pongas secretos en imágenes ni en logs.

---

## 🧹 6) Limpieza
```bash
kubectl delete deployment demo-app
kubectl delete secret db-secret api-secret regcred site-tls --ignore-not-found
kubectl delete configmap app-config nginx-conf --ignore-not-found
kubectl delete ns app-secrets
```

---

## 📎 Apéndice A — YAMLs mínimos

### Secret con `stringData` (más cómodo al escribir)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  DB_USER: myapp
  DB_PASSWORD: devops123
```

### ConfigMap sencillo
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: dev
  APP_PORT: "8080"
  DB_HOST: postgres
```

### Deployment completo de ejemplo
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  labels: { app: demo }
spec:
  replicas: 2
  selector: { matchLabels: { app: demo } }
  template:
    metadata:
      labels: { app: demo }
    spec:
      imagePullSecrets:
        - name: regcred   # opcional si usas registry privado
      containers:
        - name: app
          image: nginx:1.26-alpine
          ports:
            - containerPort: 8080
          envFrom:
            - secretRef:    { name: db-secret }
            - configMapRef: { name: app-config }
          volumeMounts:
            - name: secret-vol
              mountPath: /etc/secrets
              readOnly: true
            - name: cfg-vol
              mountPath: /etc/config
              readOnly: true
      volumes:
        - name: secret-vol
          secret:
            secretName: db-secret
        - name: cfg-vol
          configMap:
            name: app-config
```

---

**¡Listo!** Ya puedes gestionar configuración y secretos de forma segura y repetible en Kubernetes, integrándolos con tus Deployments y flujos CI/CD.
