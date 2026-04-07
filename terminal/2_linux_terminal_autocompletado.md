# Consejos del Terminal de Linux - Autocompletado con Tab y Historial de Comandos

## Objetivos de aprendizaje
Después de completar esta lectura, podrás:
- Usar el **autocompletado con Tab** para completar comandos automáticamente
- Usar el **historial de comandos** para navegar rápidamente entre comandos previos

---

## Uso del Autocompletado con Tab en el Shell
La mayoría de entornos modernos de shell soportan una característica útil llamada **autocompletado con Tab**.  
Esta función permite completar de manera rápida y eficiente comandos, nombres de archivos o directorios mientras escribes en el terminal.

### ¿Qué es el autocompletado con Tab?
- Presiona **Tab** mientras escribes un comando o ruta de archivo para completar automáticamente el resto de la palabra (si existe una coincidencia única).  
- Si hay múltiples coincidencias, al presionar **Tab** dos veces se mostrarán todas las opciones disponibles.

### Ejemplo práctico
Supongamos que estás en tu **directorio personal (~)**, que contiene:  
- `Pictures`  
- `Videos`  
- `Documents`  
- `Downloads`  

Además, `Documents` contiene una carpeta: `python-examples`.

#### Caso 1: Coincidencia única
```bash
~ $ cd P
# Presiona Tab
~ $ cd Pictures/
```

#### Caso 2: Múltiples coincidencias
```bash
~ $ cd Do
# Presiona Tab → No ocurre nada (¿Documents o Downloads?)
```

#### Caso 3: Entrada más específica
```bash
~ $ cd Doc
# Presiona Tab
~ $ cd Documents/
```

#### Caso 4: Autocompletando rutas más largas
```bash
~ $ cd Documents/
# Presiona Tab otra vez
~ $ cd Documents/python-examples/
```

---

## Historial de Comandos
El historial de comandos te permite navegar entre los comandos anteriores usando las teclas de **Flecha Arriba** y **Flecha Abajo**.

Ejemplo: Supongamos que ejecutaste:
```bash
~ $ cd ~/Documents/python-examples
~/Documents/python-examples $ python3 myprogram.py
Hello, World!
~/Documents/python-examples $ cd /
/ $
```

### Ejecutando el último comando
- Presiona **Flecha Arriba** una vez:
```bash
/ $ cd /
```

### Ejecutando un comando anterior
- Presiona **Flecha Arriba** tres veces:
```bash
/ $ cd ~/Documents/python-examples
```

💡 Nota: Solo se registran los comandos escritos (no las salidas como `Hello, World!`).

### Consejo
- Si te desplazas demasiado atrás con la Flecha Arriba, usa **Flecha Abajo** para avanzar de nuevo.

---

## Resumen
🎉 ¡Felicidades! Ahora conoces algunos atajos útiles para acelerar tu uso del terminal.

En esta lectura aprendiste a:
- Usar el **autocompletado con Tab** para completar comandos
- Usar el **historial de comandos** para navegar rápidamente entre comandos previos
