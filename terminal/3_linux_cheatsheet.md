# Módulo 1 Cheat Sheet - Introducción a Linux

## Consejos para la terminal de Linux
- Usa **tab** para autocompletar nombres de archivos y comandos.
- Usa las flechas **Arriba** y **Abajo** para recorrer el historial de comandos y volver a ejecutar uno ya usado.

---

## Obtener información
Mostrar el manual de referencia para el comando `ls`:
```bash
man ls
```

---

## Navegación de directorios

### Rutas especiales
| Símbolo | Representa la ruta a |
|---------|------------------------|
| `~`     | Directorio home        |
| `/`     | Directorio raíz        |
| `.`     | Directorio actual      |
| `..`    | Directorio padre       |

### Listar archivos y directorios
En el directorio actual:
```bash
ls
```

En un directorio específico:
```bash
ls ruta_al_directorio
```

Mostrar la ruta al directorio actual:
```bash
pwd
```

---

## Cambiar de directorio
A un subdirectorio:
```bash
cd nombre_subdirectorio
```

Un nivel arriba:
```bash
cd ../
```

Al home:
```bash
cd ~
```

A otro directorio:
```bash
cd ruta_al_directorio
```

Cambiar a un directorio hermano:
```bash
cd ../dir_2
```

Volver al directorio anterior:
```bash
cd -
```

---

## Actualizar e instalar paquetes
Actualizar información de paquetes:
```bash
sudo apt update
```

Actualizar un paquete específico (ejemplo: nano):
```bash
sudo apt upgrade nano
```

Instalar Vim:
```bash
sudo apt install vim
```

---

## Crear y editar archivos
Crear un archivo de texto y abrirlo con **nano**:
```bash
nano nombre_archivo.txt
```

> 💡 Si el archivo ya existe, nano simplemente lo abre para editarlo.
