# Laboratorio #6.1: Contenedores Docker con Flask – Dockerfile, Docker Hub y AWS ECR

**Asunto:** DevOps – Laboratorio 6.1  
**Deadline:** Viernes hasta las 7:00 p.m.  
**Duración estimada:** 60–90 min  
**Nivel:** Intermedio  

---

## 🎯 Objetivo

- Crear un Dockerfile para una aplicación Flask.  
- Construir una imagen Docker personalizada.  
- Ejecutar el contenedor localmente.  
- Publicar la imagen en **Docker Hub**.  
- Publicar la imagen en **AWS ECR**.  

---

## 📚 Guías de apoyo
- [Guía de laboratorio](https://github.com/wils0n/laboratorios-md/blob/main/laboratorio_docker/laboratorio_6_1_docker_flask.md)  
- [Documentación oficial Flask](https://flask.palletsprojects.com/)  
- [Docker Docs – Get Started](https://docs.docker.com/get-started/)  
- [AWS ECR Docs](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)  

---

## 📦 Entregables

1. **URL del repositorio (GitHub o GitLab)**  
   - Ejemplo:  
     ```
     https://github.com/<usuario>/lab-docker-flask
     ```

2. **Capturas/Archivos obligatorios en el repositorio:**
   - `app.py` y `requirements.txt` creados.  
   - `Dockerfile` implementado.  
   - Captura de image Docker construida (salida de `docker images`).  
   - Captura de Contenedor ejecutándose localmente en puerto `8080` (captura del servidor corriendo en el navegador y captura del contenedor corriendo desde Docker Desktop).
   - Captura de la imagen Docker publicada en **Docker Hub** (captura del repositorio en hub.docker.com que se note la url).  
   - Captura de la imagen publicada en **AWS ECR** (captura del repositorio en la consola AWS con el URI visible).  

---

## ⚠️ Notas importantes

- **No usar la cuenta root de AWS.** Crear un usuario IAM con permisos específicos para ECR.  
- Nombrar la imagen y repositorios con un nombre estándar:  
  ```
  flask-docker-app
  ```
- Mantener el Dockerfile simple y seguro (usar usuario no-root).  
- Subir el proyecto completo (código + Dockerfile + capturas) al repositorio entregable.  

---

## 📌 Ejemplo de URLs de entrega

- Docker Hub:  
  ```
  https://hub.docker.com/r/<usuario>/flask-docker-app
  ```

- AWS ECR (captura de consola):  
  ```
  <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/flask-docker-app:latest
  ```

---

## ✅ Checklist de éxito  

- [ ] Aplicación Flask funcionando localmente  
- [ ] Imagen Docker construida correctamente  
- [ ] Contenedor corriendo en puerto 8080  
- [ ] Imagen publicada en Docker Hub  
- [ ] Imagen publicada en AWS ECR  
- [ ] Capturas archivos en el repositorio
- [ ] Repositorio entregado en GitHub/GitLab  

---
