# 🔐 Guía Práctica (actualizada): **Secrets y ConfigMaps** en Kubernetes
**Continuación de la serie:** Pods → ReplicaSets → Deployments -> **Secrets & ConfigMaps**

> Versión actualizada: incluye **paso cero** para crear `./secrets/` con archivos **`api-token`** y **`db-password`**, **manifiestos YAML completos** (no fragmentos) con **nombre de archivo sugerido**, y una explicación de lo nuevo agregado (env vs volúmenes y claves con guiones).

---

## ✅ Novedades en esta versión
- **Paso 0 obligatorio:** crear carpeta `./secrets` con los archivos `api-token` y `db-password` (se usarán para un Secret).
- **YAMLs completos** con **nombres de archivo** antes de cada bloque, listos para `kubectl apply -f`.
- **Deployment (env + envFrom):** se añade un ejemplo que **mapea claves con guiones** (`api-token`) a **variables de entorno válidas** (`API_TOKEN`) usando `env` + `secretKeyRef` (recomendado cuando usas claves con `-`).  
  > Recordatorio: si usas `envFrom`, las claves del Secret pasan a ser nombres de variables. **Las variables de entorno no permiten guiones** (`-`). Con `env` + `secretKeyRef` puedes mapear `api-token` → `API_TOKEN` sin cambiar el nombre del archivo.

---

## 0) Preparación: Namespace y carpeta de secretos

**📄 archivo:** `00-namespace.yaml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: app-secrets
  labels:
    app: demo
    stage: dev
```
Aplicar y fijar contexto:
```bash
kubectl apply -f 00-namespace.yaml
kubectl config set-context --current --namespace=app-secrets
```

**Crear carpeta y archivos locales de secretos (en tu máquina):**
```bash
mkdir -p ./secrets
echo -n "ABC123TOKEN" > ./secrets/api-token
echo -n "devops123"   > ./secrets/db-password
```

> **Nota:** Estos nombres de archivo se convertirán en **claves del Secret**. Pueden contener guiones, pero **si luego pretendes usarlos como variables de entorno con `envFrom`, no funcionará** (los guiones no son válidos en nombres de variables). Más abajo verás cómo mapearlos correctamente con `env` + `secretKeyRef`.

---

## 1) ConfigMap (configuración no sensible)

**📄 archivo:** `configmap-app.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: app-secrets
data:
  APP_ENV: dev
  APP_PORT: "8080"
  DB_HOST: postgres
```

Aplicar:
```bash
kubectl apply -f configmap-app.yaml
```

---

## 2) Secrets (credenciales)

### 2.1 `db-secret` (usando `stringData` — cómodo para demo/labs)

**📄 archivo:** `secret-db.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: app-secrets
type: Opaque
stringData:
  DB_USER: myapp
  DB_PASSWORD: devops123
```

Aplicar:
```bash
kubectl apply -f secret-db.yaml
```

### 2.2 `api-secret` (equivalente al directorio `./secrets`)

> Si prefieres mantener los archivos locales y crear el Secret desde la carpeta:
> ```bash
> kubectl create secret generic api-secret --from-file=./secrets/ -n app-secrets
> ```
> A continuación, su **equivalente en YAML** usando `stringData` (útil para GitOps con valores *placeholder*).

**📄 archivo:** `secret-api.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-secret
  namespace: app-secrets
type: Opaque
stringData:
  api-token: "ABC123TOKEN"
  db-password: "devops123"
```
Aplicar:
```bash
kubectl apply -f secret-api.yaml
```

---

## 3) Deployments (tres variantes completas)

### 3.1 Deployment con **solo envFrom** (rápido, pero ojo con claves con guiones)
**📄 archivo:** `deployment-demo-envfrom.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: app-secrets
  labels: { app: demo }
spec:
  replicas: 2
  selector:
    matchLabels: { app: demo }
  template:
    metadata:
      labels: { app: demo }
    spec:
      containers:
        - name: app
          image: nginx:1.26-alpine
          ports:
            - containerPort: 8080
          envFrom:
            - secretRef:
                name: db-secret        # DB_USER, DB_PASSWORD (válidos como env vars)
            - configMapRef:
                name: app-config       # APP_ENV, APP_PORT, DB_HOST
          # Nota: No incluimos api-secret aquí porque sus claves llevan guiones.
```

Aplicar:
```bash
kubectl apply -f deployment-demo-envfrom.yaml
kubectl rollout status deploy/demo-app
kubectl get pods -o wide
kubectl exec -it deploy/demo-app -- sh -c 'printenv | grep -E "DB_|APP_"'
```

### Resumen de la configuración anterior

Esta configuración despliega una aplicación llamada `demo-app` usando un Deployment en el namespace `app-secrets`. Sus principales características son:

- **ReplicaSet:** Se crean 2 réplicas del contenedor basado en la imagen `nginx:1.26-alpine`, expuesto en el puerto 8080.
- **Variables de entorno:** El contenedor recibe variables de entorno desde dos fuentes:
  - **Secret `db-secret`:** Proporciona las variables `DB_USER` y `DB_PASSWORD` (credenciales de base de datos).
  - **ConfigMap `app-config`:** Proporciona las variables `APP_ENV`, `APP_PORT` y `DB_HOST` (configuración de la aplicación).
- **Seguridad:** No se incluye el Secret `api-secret` porque sus claves contienen guiones, lo cual no es válido para nombres de variables de entorno en Kubernetes.
- **Namespace:** Todo se despliega en el namespace `app-secrets` para aislar los recursos.

>Esta configuración permite gestionar credenciales y parámetros de configuración de forma segura y centralizada usando recursos nativos de Kubernetes.
---

### 3.2 Deployment **envFrom + env (secretKeyRef)** para mapear claves con guiones → variables válidas
**📄 archivo:** `deployment-demo-envplus.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: app-secrets
  labels: { app: demo }
spec:
  replicas: 2
  selector:
    matchLabels: { app: demo }
  template:
    metadata:
      labels: { app: demo }
    spec:
      containers:
        - name: app
          image: nginx:1.26-alpine
          ports:
            - containerPort: 8080

          # Trae todas las claves de estos objetos como variables (válidas)
          envFrom:
            - secretRef:    { name: db-secret }   # DB_USER, DB_PASSWORD
            - configMapRef: { name: app-config }  # APP_ENV, APP_PORT, DB_HOST

          # Mapea claves con guiones (api-secret) a nombres de variables válidos
          env:
            - name: API_TOKEN
              valueFrom:
                secretKeyRef:
                  name: api-secret
                  key: api-token
            - name: DB_PASSWORD_FILE_SECRET
              valueFrom:
                secretKeyRef:
                  name: api-secret
                  key: db-password
```

Aplicar y validar:
```bash
kubectl apply -f deployment-demo-envplus.yaml
kubectl rollout status deploy/demo-app
kubectl exec -it deploy/demo-app -- sh -c 'printenv | grep -E "DB_|APP_|TOKEN"'
```

### Resumen de la configuración avanzada de Deployment

Esta configuración de Kubernetes despliega la aplicación `demo-app` en el namespace `app-secrets` y permite inyectar variables de entorno tanto desde Secrets y ConfigMaps con nombres válidos, como desde Secrets cuyas claves contienen guiones.

#### Características principales

- **ReplicaSet:** Despliega 2 réplicas del contenedor `nginx:1.26-alpine` en el puerto 8080.
- **Variables de entorno estándar:** Usa `envFrom` para importar todas las claves válidas de:
  - Secret `db-secret` (`DB_USER`, `DB_PASSWORD`)
  - ConfigMap `app-config` (`APP_ENV`, `APP_PORT`, `DB_HOST`)
- **Variables con guiones:** Usa la sección `env` para mapear claves de Secrets que contienen guiones a nombres válidos de variables de entorno:
  - `api-token` (de `api-secret`) se mapea a la variable `API_TOKEN`
  - `db-password` (de `api-secret`) se mapea a la variable `DB_PASSWORD_FILE_SECRET`

#### ¿Cuándo usar esta forma?

Utiliza esta configuración cuando necesitas exponer valores de Secrets o ConfigMaps como variables de entorno en el contenedor, pero algunas claves contienen guiones (`-`) o caracteres no válidos para nombres de variables de entorno. El bloque `env` permite asignar manualmente un nombre válido a cada variable y vincularlo a la clave original del Secret o ConfigMap.

Esto es útil para:
- Cumplir con restricciones de nombres de variables de entorno en el sistema operativo.
- Mantener la seguridad y flexibilidad en la gestión de credenciales y configuraciones sensibles.

---

### 3.3 Deployment con **volúmenes** (archivos en `/etc/secrets` y `/etc/config`)
**📄 archivo:** `deployment-demo-volumes.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: app-secrets
  labels: { app: demo }
spec:
  replicas: 2
  selector:
    matchLabels: { app: demo }
  template:
    metadata:
      labels: { app: demo }
    spec:
      containers:
        - name: app
          image: nginx:1.26-alpine
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
            secretName: api-secret     # Monta archivos: /etc/secrets/api-token, /etc/secrets/db-password
        - name: cfg-vol
          configMap:
            name: app-config           # Monta archivos: /etc/config/APP_ENV, /etc/config/APP_PORT, etc.
```

Aplicar y validar:
```bash
kubectl apply -f deployment-demo-volumes.yaml
kubectl rollout status deploy/demo-app
kubectl exec -it deploy/demo-app -- sh -c 'ls -1 /etc/secrets /etc/config && echo "---"; for f in /etc/secrets/* /etc/config/*; do echo $f:; cat $f; echo; done'
```

### Resumen de configuración: Montaje de Secrets y ConfigMaps como volúmenes

Esta configuración de Kubernetes despliega la aplicación `demo-app` y utiliza volúmenes para exponer los valores de Secrets y ConfigMaps dentro del contenedor.

#### Características principales

- **Montaje de Secrets:** Los datos sensibles (como credenciales) almacenados en un Secret se montan como archivos en el directorio `/etc/secrets` dentro del contenedor.
- **Montaje de ConfigMaps:** Los parámetros de configuración se montan como archivos en el directorio `/etc/config` dentro del contenedor.
- **Acceso seguro:** El contenedor puede leer los valores directamente desde los archivos, lo que es útil para aplicaciones que esperan archivos en vez de variables de entorno.
- **Separación de datos:** Mantiene separados los datos sensibles (Secrets) y los de configuración (ConfigMaps), facilitando la gestión y aumentando la seguridad.

#### ¿Cuándo usar esta forma?

Utiliza esta configuración cuando tu aplicación necesita leer archivos de configuración o credenciales desde el sistema de archivos, en vez de variables de entorno. Es especialmente útil para aplicaciones que requieren rutas específicas para archivos de configuración o certificados.

Esta forma también ayuda a mantener buenas prácticas de seguridad y organización en el manejo de datos sensibles y configuraciones en Kubernetes.


---

## 4) Limpieza del laboratorio
```bash
kubectl delete deployment demo-app --ignore-not-found
kubectl delete secret api-secret db-secret --ignore-not-found
kubectl delete configmap app-config --ignore-not-found
kubectl delete ns app-secrets --ignore-not-found
```

---

## 🧠 Resumen
- **ConfigMap**: config **no sensible** (puertos, hosts).  
- **Secret**: **credenciales/tokens**.  
- **envFrom** es rápido, pero **requiere claves válidas** para variables (sin guiones).  
- **env + secretKeyRef** permite **mapear** claves con guiones a variables válidas.  
- **Volúmenes** montan claves como **archivos** (nombres con guiones sin problema).

¡Listo! Con estos manifiestos completos y el paso cero de `./secrets`, puedes recrear el laboratorio de forma predecible.
