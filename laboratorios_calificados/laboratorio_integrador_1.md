# Laboratorio 1: Laboratorio Integradorde Control de Versiones y Automatización de Despliegue

**Fecha:** 12/09/25.
**Modalidad:** Exposición y demo práctica

---

## Objetivo

Demostrar el dominio de control de versiones profesional con Git (usando Conventional Commits) y la automatización del despliegue local de una aplicación mediante scripts.

---

## Requerimientos

### 1. Creación y gestión del repositorio

- Crea un repositorio nuevo en GitHub para tu proyecto (puede ser privado o público).
- Sube tu proyecto (puede ser una app Django, Flask, Node.js, etc.) al repositorio.
- Utiliza **Conventional Commits** en todos tus mensajes de commit ([guía aquí](https://www.conventionalcommits.org/)).
  - Ejemplo:
    ```
    feat: agrega autenticación de usuarios
    fix: corrige error en el formulario de registro
    docs: actualiza el README con instrucciones de despliegue
    ```

### 2. Automatización del despliegue local

- Crea un script Bash (`deploy_local.sh`) que:
  1. Verifique si las dependencias principales están instaladas (por ejemplo, Python, pip, Node, npm, etc.).
  2. Cree y active un entorno virtual si es Python.
  3. Instale todas las dependencias del proyecto.
  4. Ejecute las migraciones (si aplica, por ejemplo en Django).
  5. Levante el servidor de desarrollo local.
- El script debe mostrar mensajes claros de avance y errores.
- El script debe funcionar con un solo comando desde la terminal.

### 3. Presentación y demo (10 - 15 minutos de presentación y 5 minutos de preguntas)

- Explica de qué se trata el proyecto
- Explica el stack de tecnologías que usa el proyecto (python, django / nodejs, react.js, etc)
- Explica cómo usaste Conventional Commits y muestra el historial de commits.
- Ejecuta el script en vivo y muestra la aplicación corriendo localmente.
- Responde preguntas del docente y compañeros.

---

## Entregables

- Repositorio en GitHub con el código y el script.
- Slides breves para la exposición.

---

## Criterios de evaluación

- Uso correcto de Conventional Commits.
- Automatización funcional y robusta del despliegue local.
- Claridad y calidad del script.
- Presentación y demo funcional.

---

## Recursos recomendados

- [Conventional Commits](https://www.conventionalcommits.org/)
- Laboratorios previos de Bash y Git.

---

¡Éxito
