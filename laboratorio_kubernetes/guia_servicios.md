# 🌐 Guía Práctica: **Services** en Kubernetes
**Continuación de las guías:** Pods → ReplicaSets → Deployments → **Services**

---

## 🎯 1. Objetivo
Exponer una aplicación de Kubernetes mediante **Services**, entendiendo:
- Para qué sirven y cómo resuelven IPs efímeras de Pods.
- Tipos de Service: **ClusterIP**, **NodePort**, **LoadBalancer**, **ExternalName**.
- Selectores, `targetPort` vs `port`, *endpoints/EndpointSlice*, DNS interno y pruebas con `curl`/`kubectl`.

> Partiremos del Deployment creado en la guía previa (`dep-test.yaml` con `app: app1` y `type: frontend`, 3–5 réplicas).

---

## 🧠 2. ¿Por qué Services?
- Los **Pods** son **efímeros** y sus **IPs cambian**.
- Un **Service** provee un **punto estable** (nombre DNS/IP virtual) y **balancea** hacia todos los Pods **que coinciden** con su `selector`.
- Bajo el capó, Kubernetes mantiene los destinos en **EndpointSlice** (reemplazo moderno de `Endpoints`).

```
Client → Service (IP y DNS) ──selector──▶ Pods (réplicas del Deployment)
```

---

## 🧱 3. Componentes clave del Service
- `spec.selector`: etiquetas de los Pods destino (deben coincidir con las del Deployment).
- `spec.ports[].port`: **puerto** del Service (visible para el cliente del Service).
- `spec.ports[].targetPort`: **puerto** donde escucha el contenedor del **Pod** (p.ej., 80).
- `type`: `ClusterIP` (default), `NodePort`, `LoadBalancer`, `ExternalName`.

> Buenas prácticas: alinear `selector` con las **labels** del template del Deployment; usar `targetPort` numérico o por **nombre** (recomendado en apps complejas).

---

## 🧩 4. **ClusterIP** (tráfico **dentro** del clúster)
Crea un punto de acceso **interno** con IP virtual y DNS: `svc-name.namespace.svc.cluster.local`.

**Archivo:** `svc-clusterip.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app1-svc
  labels:
    app: app1
spec:
  type: ClusterIP
  selector:
    app: app1
    type: frontend
  ports:
    - name: http
      port: 8080        # puerto del Service
      targetPort: 80    # puerto del contenedor en el Pod
```

**Aplicar y verificar**
```bash
kubectl apply -f svc-clusterip.yaml
kubectl get svc app1-svc
kubectl get endpointslices -l kubernetes.io/service-name=app1-svc
```

**Probar desde dentro del clúster**
```bash
# Opción A: usar un Pod temporal
kubectl run tmp --rm -it --image=busybox:1.36 -- /bin/sh
# ya dentro del pod:
wget -qO- http://app1-svc:8080
# salir con: exit

# Opción B: port-forward para probar desde tu laptop
kubectl port-forward service/app1-svc 8080:8080
# En otra terminal local:
curl http://localhost:8080
```

---

## 🌉 5. **NodePort** (abre un puerto en **cada nodo**)
Útil para **laboratorio** o entornos sin Ingress/Load Balancer. Abre un puerto del rango **30000–32767** en todos los nodos y lo **redirecciona** al Service.

**Archivo:** `svc-nodeport.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app1-svc-nodeport
spec:
  type: NodePort
  selector:
    app: app1
    type: frontend
  ports:
    - name: http
      port: 8080
      targetPort: 80
      nodePort: 30100  # opcional: si omites, se asigna automáticamente
```

**Probar**
```bash
kubectl apply -f svc-nodeport.yaml
kubectl get svc app1-svc-nodeport -o wide

# Desde fuera del clúster (sustituye <NODE_IP>)
curl http://<NODE_IP>:30100
```

> Nota: **NodePort** expone cada nodo; en producción suele preferirse **Ingress** o **LoadBalancer**.

---

## ☁️ 6. **LoadBalancer** (nube pública / metal con LB)
Provisiona un **balanceador externo** (p.ej., en AWS/GCP/Azure o MetalLB on-prem) y apunta al Service.

**Archivo:** `svc-loadbalancer.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app1-svc-lb
  annotations:
    # Ejemplos (varían por proveedor):
    # service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    # cloud.google.com/load-balancer-type: "External"
spec:
  type: LoadBalancer
  selector:
    app: app1
    type: frontend
  ports:
    - name: http
      port: 80
      targetPort: 80
```

**Probar**
```bash
kubectl apply -f svc-loadbalancer.yaml
kubectl get svc app1-svc-lb   # espera EXTERNAL-IP
curl http://<EXTERNAL-IP>/
```

---

## 🔗 7. **ExternalName** (alias DNS **sin** exponer Pods)
No crea IP ni balancea Pods; **mapea** un nombre de Service a un **DNS externo** vía CNAME. Útil para referenciar SaaS o servicios legados desde **dentro** del clúster.

**Archivo:** `svc-externalname.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ext-docs
spec:
  type: ExternalName
  externalName: docs.example.com
```

**Uso (desde Pods)**
```bash
kubectl run tmp --rm -it --image=busybox:1.36 -- /bin/sh
nslookup ext-docs
# devuelve CNAME a docs.example.com
```

---

## 🧪 8. Demostración: balanceo real con **ClusterIP**
1. Asegúrate de tener el Deployment con ≥2 réplicas (`app1-dep`).  
2. Ejecuta varias peticiones al Service y observa respuestas alternadas (Nginx/headers distintos).  
3. **Escala** el Deployment (`kubectl scale deployment app1-dep --replicas=5`) y repite las pruebas: verás más destinos en `EndpointSlice` y el Service **balanceará** automáticamente.

---

## 🧰 9. Utilidades y diagnóstico
```bash
# Listar servicios y puertos
kubectl get svc -o wide

# Ver destinos: preferible EndpointSlice moderno
kubectl get endpointslices -A | head -n 20

# Describir un Service y sus selectores
kubectl describe svc app1-svc

# Resolver DNS interno
kubectl run dns --rm -it --image=busybox:1.36 -- nslookup app1-svc.default.svc.cluster.local

# Trazar tráfico local con port-forward
kubectl port-forward svc/app1-svc 8080:8080
```

**Notas rápidas**
- `sessionAffinity: ClientIP` puede “pegar” un cliente a un Pod (útil para sesiones simples).  
- **Headless Service** (`clusterIP: None`) expone **todas** las IPs de los Pods en DNS (muy usado con **StatefulSet**).  
- Evita `NodePort` en producción salvo necesidad explícita; prefiere **Ingress** + **ClusterIP**.  
- Mantén los `labels`/`selectors` **consistentes** y versiona YAML en Git.

---

## 🧹 10. Limpieza
```bash
kubectl delete -f svc-clusterip.yaml                -f svc-nodeport.yaml                -f svc-loadbalancer.yaml                -f svc-externalname.yaml
```

---

## 📎 11. Archivos de ejemplo incluidos
- `svc-clusterip.yaml`
- `svc-nodeport.yaml`
- `svc-loadbalancer.yaml`
- `svc-externalname.yaml`

> Esta guía continúa tus prácticas previas y prepara el terreno para **Ingress** (ruteo HTTP/HTTPS y TLS) en la siguiente lección.

---

📘 **Autor:**  
Wilson Julca Mejía  
Curso: *DevOps y Kubernetes – Services, Ingress y Exposición de Aplicaciones*  
Universidad de Ingeniería y Tecnología (UTEC)
