# Hoja de trucos de Bash (Bash Cheat Sheet)

Una hoja de referencia para comandos de **bash**.

## Navegación de directorios

```bash
pwd                       # Imprime la ruta del directorio actual
ls                        # Lista archivos y directorios
ls -a|--all               # Incluye archivos/directorios ocultos
ls -l                     # Muestra en formato detallado (long)
ls -l -h|--human-readable # Formato detallado con tamaños legibles
ls -t                     # Ordena por fecha de modificación, más reciente primero
stat foo.txt              # Tamaño, creación y modificación de un archivo
stat foo                  # Tamaño, creación y modificación de un directorio
tree                      # Muestra el árbol de directorios y archivos
tree -a                   # Incluye ocultos
tree -d                   # Solo el árbol de directorios
cd foo                    # Ir al subdirectorio foo
cd                        # Ir al directorio home
cd ~                      # Ir al directorio home
cd -                      # Volver al último directorio
pushd foo                 # Ir a foo y apilar el directorio previo
popd                      # Volver al directorio apilado por `pushd`
```

## Crear directorios

```bash
mkdir foo                        # Crear un directorio
mkdir foo bar                    # Crear múltiples directorios
mkdir -p|--parents foo/bar       # Crear un directorio anidado
mkdir -p|--parents {foo,bar}/baz # Crear múltiples directorios anidados

mktemp -d|--directory            # Crear un directorio temporal
```

## Mover/copiar directorios

```bash
cp -R|--recursive foo bar                               # Copiar directorio
mv foo bar                                              # Mover/renombrar directorio

rsync -z|--compress -v|--verbose /foo /bar              # Copiar (sobrescribe destino)
rsync -a|--archive -z|--compress -v|--verbose /foo /bar # Copiar (sin sobrescribir)
rsync -avz /foo username@hostname:/bar                  # Copiar local -> remoto
rsync -avz username@hostname:/foo /bar                  # Copiar remoto -> local
```

## Eliminar directorios

```bash
rmdir foo                        # Eliminar directorio vacío
rm -r|--recursive foo            # Eliminar directorio y su contenido
rm -r|--recursive -f|--force foo # Eliminar forzando (sin preguntar)
```

## Crear archivos

```bash
touch foo.txt          # Crear archivo o actualizar fecha de modificación
touch foo.txt bar.txt  # Crear múltiples archivos
touch {foo,bar}.txt    # Crear múltiples archivos con expansión de llaves
touch test{1..3}       # Crea test1, test2 y test3
touch test{a..c}       # Crea testa, testb y testc

mktemp                 # Crear un archivo temporal
```

## Salida estándar, error estándar y entrada estándar

```bash
echo "foo" > bar.txt       # Sobrescribir archivo con contenido
echo "foo" >> bar.txt      # Añadir contenido al final

ls exists 1> stdout.txt    # Redirigir salida estándar a archivo
ls noexist 2> stderror.txt # Redirigir error estándar a archivo
ls 2>&1 > out.txt          # Redirigir salida y error a un archivo
ls > /dev/null             # Descartar salida (y error con 2>&1)
# ls > /dev/null 2>&1

read foo                   # Leer de stdin y guardar en variable foo
```

## Mover/copiar archivos

```bash
cp foo.txt bar.txt                                # Copiar archivo
mv foo.txt bar.txt                                # Mover/renombrar archivo

rsync -z|--compress -v|--verbose /foo.txt /bar    # Copiar rápido si no cambió
rsync -z|--compress -v|--verbose /foo.txt /bar.txt # Copiar y renombrar rápido si no cambió
```

## Eliminar archivos

```bash
rm foo.txt            # Eliminar archivo
rm -f|--force foo.txt # Eliminar forzando (sin preguntar)
```

## Leer archivos

```bash
cat foo.txt            # Imprimir contenido completo
less foo.txt           # Ver por páginas (g: inicio, G: fin, /foo: buscar)
head foo.txt           # Primeras 10 líneas
tail foo.txt           # Últimas 10 líneas
open foo.txt           # Abrir en el editor predeterminado (macOS)
wc foo.txt             # Número de líneas, palabras y caracteres
```

## Permisos de archivos

| #   | Permiso                  | rwx | Binario |
| --- | ------------------------ | --- | ------- |
| 7   | leer, escribir, ejecutar | rwx | 111     |
| 6   | leer y escribir          | rw- | 110     |
| 5   | leer y ejecutar          | r-x | 101     |
| 4   | solo leer                | r-- | 100     |
| 3   | escribir y ejecutar      | -wx | 011     |
| 2   | solo escribir            | -w- | 010     |
| 1   | solo ejecutar            | --x | 001     |
| 0   | ninguno                  | --- | 000     |

Para un **directorio**, _ejecutar_ significa que puedes **entrar** al directorio.

| Usuario | Grupo | Otros | Descripción                                                                  |
| ------: | ----: | ----: | ---------------------------------------------------------------------------- |
|       6 |     4 |     4 | Usuario lee/escribe; otros solo leen (permiso por defecto de archivo)        |
|       7 |     5 |     5 | Usuario lee/escribe/ejecuta; otros leen/ejecutan (por defecto en directorio) |

- **u** - Usuario (owner)
- **g** - Grupo
- **o** - Otros
- **a** - Todos

```bash
ls -l /foo.sh            # Listar permisos
chmod +100 foo.sh        # Sumar 1 al permiso del usuario
chmod -100 foo.sh        # Restar 1 al permiso del usuario
chmod u+x foo.sh         # Dar permiso de ejecución al usuario
chmod g+x foo.sh         # Dar permiso de ejecución al grupo
chmod u-x,g-x foo.sh     # Quitar ejecución a usuario y grupo
chmod u+x,g+x,o+x foo.sh # Dar ejecución a todos
chmod a+x foo.sh         # Dar ejecución a todos
chmod +x foo.sh          # Dar ejecución a todos
```

## Buscar binarios y archivos

Buscar binarios de un comando.

```bash
type wget                                  # Dónde está el binario
which wget                                 # Dónde está el binario
whereis wget                               # Binario, código fuente y páginas de manual
```

`locate` usa un índice y es rápido.

```bash
updatedb                                   # Actualizar índice (requiere permisos)
locate foo.txt                             # Encontrar un archivo
locate --ignore-case foo.txt               # Ignorar mayúsculas/minúsculas
locate f*.txt                              # Archivos .txt que empiezan por 'f'
```

`find` no usa índice y es más lento pero muy flexible.

```bash
find /path -name foo.txt                   # Buscar un archivo
find /path -iname foo.txt                  # Búsqueda insensible a mayúsculas
find /path -name "*.txt"                   # Todos los .txt
find /path -name foo.txt -delete           # Buscar y eliminar
find /path -name "*.png" -exec pngquant {} \; # Ejecutar comando sobre cada resultado
find /path -type f -name foo.txt           # Solo archivos
find /path -type d -name foo               # Solo directorios
find /path -type l -name foo.txt           # Solo enlaces simbólicos
find /path -type f -mtime +30              # Archivos sin modificar hace 30+ días
find /path -type f -mtime +30 -delete      # Eliminar los anteriores
```

## Buscar dentro de archivos

```bash
grep 'foo' /bar.txt                         # Buscar 'foo' en bar.txt
grep 'foo' /bar -r|--recursive              # Buscar 'foo' en el dir 'bar'
grep 'foo' /bar -R|--dereference-recursive  # Igual, siguiendo enlaces simbólicos
grep 'foo' /bar -l|--files-with-matches     # Solo nombres de archivos que coinciden
grep 'foo' /bar -L|--files-without-match    # Solo archivos que NO coinciden
grep 'Foo' /bar -i|--ignore-case            # Insensible a mayúsculas
grep 'foo' /bar -x|--line-regexp            # Coincidir línea completa
grep 'foo' /bar -C|--context 1              # Añadir N líneas de contexto
grep 'foo' /bar -v|--invert-match           # Mostrar líneas que NO coinciden
grep 'foo' /bar -c|--count                  # Contar coincidencias
grep 'foo' /bar -n|--line-number            # Numerar líneas
grep 'foo' /bar --colour                    # Colorear salida
grep 'foo\|bar' /baz -R                    # 'foo' O 'bar'
grep --extended-regexp|-E 'foo|bar' /baz -R # Usar regex extendidas
egrep 'foo|bar' /baz -R                     # (equivalente, heredado)
```

### Reemplazar en archivos

```bash
sed 's/fox/bear/g' foo.txt               # Reemplazar y mostrar en consola
sed 's/fox/bear/gi' foo.txt              # Reemplazo insensible a mayúsculas
sed 's/red fox/blue bear/g' foo.txt      # Reemplazos múltiples
sed 's/fox/bear/g' foo.txt > bar.txt     # Guardar en otro archivo
sed -i|--in-place 's/fox/bear/g' foo.txt # Reemplazar en el mismo archivo
```

## Enlaces simbólicos

```bash
ln -s|--symbolic foo bar            # Crear enlace 'bar' que apunta a 'foo'
ln -s|--symbolic -f|--force foo bar # Sobrescribir enlace simbólico existente
ls -l                               # Ver a dónde apuntan los enlaces
```

## Comprimir archivos

### zip

Comprime uno o varios archivos en _.zip_.

```bash
zip foo.zip /bar.txt                # Comprimir bar.txt en foo.zip
zip foo.zip /bar.txt /baz.txt       # Comprimir varios
zip foo.zip /{bar,baz}.txt          # Con expansión de llaves
zip -r|--recurse-paths foo.zip /bar # Comprimir directorio bar
```

### gzip

Comprime un solo archivo en _.gz_.

```bash
gzip /bar.txt                 # Comprime y elimina el original
gzip -k|--keep /bar.txt       # Comprime y mantiene el original
mv bar.txt.gz foo.gz          # Renombrar resultado (opcional)
```

### tar -c

Combina y (opcionalmente) comprime en _.tar_, _.tar.gz_, _.tpz_ o _.tgz_.

```bash
tar -c|--create -z|--gzip -f|--file=foo.tgz /bar.txt /baz.txt
tar -c|--create -z|--gzip -f|--file=foo.tgz /{bar,baz}.txt
tar -c|--create -z|--gzip -f|--file=foo.tgz /bar
```

## Descomprimir archivos

### unzip

```bash
unzip foo.zip          # Descomprimir en directorio actual
```

### gunzip

```bash
gunzip foo.gz           # Descomprimir y eliminar .gz
gunzip -k|--keep foo.gz # Descomprimir y mantener .gz
```

### tar -x

```bash
tar -x|--extract -z|--gzip -f|--file=foo.tar.gz # Extraer .tar.gz
tar -x|--extract -f|--file=foo.tar              # Extraer .tar
```

## Uso de disco

```bash
df                     # Discos, tamaño, usado y disponible
df -h|--human-readable # Formato legible

du                     # Tamaño de directorio actual y subdirectorios
du /foo/bar            # Tamaño de un directorio específico
du -h|--human-readable # Formato legible
du -d|--max-depth      # Profundidad máxima
du -d 0                # Solo el tamaño del directorio actual
```

## Uso de memoria

```bash
free                   # Memoria usada/libre
free -h|--human        # Formato legible
free -h|--human --si   # Potencias de 1000 en vez de 1024
free -s|--seconds 5    # Actualiza cada 5 segundos
```

## Paquetes (APT)

```bash
apt update                   # Actualiza el índice de repositorios
apt search wget              # Busca un paquete
apt show wget                # Información del paquete
apt list --all-versions wget # Todas las versiones disponibles
apt install wget             # Instalar última versión
apt install wget=1.2.3       # Instalar versión específica
apt remove wget              # Eliminar paquete
apt upgrade                  # Actualizar paquetes actualizables
```

## Apagado y reinicio

```bash
shutdown                     # Apagar en 1 minuto
shutdown now "Hasta luego"   # Apagar ahora
shutdown +5 "Hasta luego"    # Apagar en 5 minutos

shutdown --reboot            # Reiniciar en 1 minuto
shutdown -r now "Reiniciar"  # Reiniciar ahora
shutdown -r +5 "Reiniciar"   # Reiniciar en 5 minutos

shutdown -c                  # Cancelar apagado/reinicio

reboot                       # Reiniciar ahora
reboot -f                    # Forzar reinicio
```

## Identificar procesos

```bash
top                    # Procesos de forma interactiva
htop                   # (Requiere instalación) interfaz mejorada
ps all                 # Listar procesos
pidof foo              # Obtener PID(s) del proceso foo

CTRL+Z                 # Suspender proceso en primer plano
bg                     # Reanudar en segundo plano
fg                     # Traer último proceso en segundo plano al frente
fg 1                   # Traer el job con ID 1 al frente

sleep 30 &             # Enviar proceso al segundo plano
jobs                   # Listar jobs en segundo plano
jobs -p                # Listar jobs con su PID

lsof                   # Archivos abiertos y procesos
lsof -itcp:4000        # Proceso escuchando en el puerto 4000
```

## Finalizar procesos

```bash
CTRL+C                 # Terminar proceso en primer plano
kill PID               # Terminar por PID (señal TERM)
kill -9 PID            # Forzar terminación (SIGKILL)
pkill foo              # Terminar por nombre (TERM)
pkill -9 foo           # Forzar terminación por nombre (SIGKILL)
killall foo            # Terminar todos los procesos con ese nombre
```

## Fecha y hora

```bash
date                   # Imprimir fecha y hora
date --iso-8601        # Fecha en ISO8601
date --iso-8601=ns     # Fecha y hora con nanosegundos

time tree              # Medir duración de ejecución de un comando
```

## Tareas programadas

```pre
   *      *         *         *           *
Minuto, Hora, Día del mes, Mes, Día de la semana
```

```bash
crontab -l                 # Ver crontab
crontab -e                 # Editar crontab (Vim por defecto)
crontab /ruta/crontab      # Cargar crontab desde archivo
crontab -l > /ruta/crontab # Guardar crontab a archivo

* * * * * foo              # Ejecutar cada minuto
*/15 * * * * foo           # Cada 15 minutos
0 * * * * foo              # Cada hora
15 6 * * * foo             # Diario a las 6:15 AM
44 4 * * 5 foo             # Viernes a las 4:44 AM
0 0 1 * * foo              # A medianoche el día 1 de cada mes
0 0 1 1 * foo              # A medianoche el 1 de enero

at -l                      # Ver tareas programadas (at)
at -c 1                    # Mostrar tarea con ID 1
at -r 1                    # Eliminar tarea con ID 1
at now + 2 minutes         # Crear tarea para dentro de 2 min
at 12:34 PM next month     # Crear tarea para la fecha indicada
at tomorrow                # Crear tarea para mañana
```

## Solicitudes HTTP

```bash
curl https://example.com                               # Solo cuerpo de respuesta
curl -i|--include https://example.com                  # Incluir código y cabeceras
curl -L|--location https://example.com                 # Seguir redirecciones
curl -o|--remote-name foo.txt https://example.com      # Guardar en archivo
curl -H|--header "User-Agent: Foo" https://example.com # Añadir cabecera HTTP
curl -X|--request POST -H "Content-Type: application/json" -d|--data '{"foo":"bar"}' https://example.com # POST JSON
curl -X POST --data-urlencode foo="bar" http://example.com # POST URL Form Encoded

wget https://example.com/file.txt                      # Descargar archivo al directorio actual
wget -O|--output-document foo.txt https://example.com/file.txt # Guardar con nombre específico
```

## Diagnóstico de red

```bash
ping example.com            # Enviar pings ICMP múltiples
ping -c 10 -i 5 example.com # 10 intentos, cada 5 segundos

ip addr                     # IPs del sistema
ip route show               # Rutas

netstat -i|--interfaces     # Interfaces y uso
netstat -l|--listening      # Puertos abiertos

traceroute example.com      # Saltos de red hasta el destino

mtr -w|--report-wide example.com                                    # Trazado continuo
mtr -r|--report -w|--report-wide -c|--report-cycles 100 example.com # Reporte de 100 ciclos

nmap 0.0.0.0                # 1000 puertos comunes en localhost
nmap 0.0.0.0 -p1-65535      # Puertos 1–65535 en localhost
nmap 192.168.4.3            # 1000 puertos comunes en IP remota
nmap -sP 192.168.1.1/24     # Descubrir máquinas en la red por ping
```

## DNS

```bash
host example.com            # Direcciones IPv4 e IPv6
dig example.com             # Información DNS completa
cat /etc/resolv.conf        # Lista de nameservers
```

## Hardware

```bash
lsusb                  # Dispositivos USB
lspci                  # Hardware PCI
lshw                   # Todo el hardware
```

## Multiplexores de terminal

Iniciar múltiples sesiones de terminal. Persisten tras reinicio. `tmux` es más moderno que `screen`.

```bash
tmux             # Nueva sesión (CTRL-b luego d para desprender)
tmux ls          # Listar sesiones
tmux attach -t 0 # Reanudar sesión

screen           # Nueva sesión (CTRL-a luego d para desprender)
screen -ls       # Listar sesiones
screen -R 31166  # Reanudar sesión

exit             # Salir de una sesión
```

## SSH (Secure Shell)

```bash
ssh hostname                 # Conectar usando el usuario actual (puerto 22)
ssh -i foo.pem hostname      # Conectar usando archivo de identidad
ssh user@hostname            # Conectar especificando usuario
ssh user@hostname -p 8765    # Conectar por puerto personalizado
ssh ssh://user@hostname:8765 # URL de conexión con puerto personalizado
```

Configurar usuario y puerto por defecto en `~/.ssh/config`:

```bash
$ cat ~/.ssh/config
Host name
  User foo
  Hostname 127.0.0.1
  Port 8765
$ ssh name
```

## Copia segura (SCP)

```bash
scp foo.txt ubuntu@hostname:/home/ubuntu # Copiar archivo a directorio remoto
```

## Perfil de Shell

- bash — `.bashrc`
- zsh — `.zshrc`

```bash
# Ejecutar siempre ls después de cd
function cd {
  builtin cd "$@" && ls
}

# Confirmar antes de sobrescribir
alias cp='cp --interactive'
alias mv='mv --interactive'
alias rm='rm --interactive'

# Mostrar uso de disco en formato legible
alias df='df -h'
alias du='du -h'
```

## Scripts en Bash

### Variables

```bash
#!/bin/bash

foo=123                # Inicializa variable foo con 123
declare -i foo=123     # Inicializa entero foo con 123
declare -r foo=123     # Inicializa variable solo lectura
echo "$foo"            # Imprimir variable foo
echo "${foo}_bar"      # foo seguido de _bar
echo "${foo:-default}" # foo si existe; si no, 'default'

export foo             # Hacer foo visible a procesos hijos
unset foo              # Eliminar variable del entorno
```

### Variables de entorno

```bash
#!/bin/bash

env            # Listar variables de entorno
echo "$PATH"   # Mostrar PATH
export FOO=Bar # Establecer variable de entorno
```

### Funciones

```bash
#!/bin/bash

greet() {
  local world="World"
  echo "$1 $world"
}
greet "Hello"
greeting=$(greet "Hello")
```

### Códigos de salida

```bash
#!/bin/bash

exit 0   # Salir correctamente
exit 1   # Salir con error
echo $?  # Último código de salida
```

### Condicionales

#### Operadores booleanos

- `$foo` — Verdadero si no está vacío
- `! $foo` — Negación (falso si estaba verdadero)

#### Operadores numéricos

- `-eq` — Igual
- `-ne` — Distinto
- `-gt` — Mayor que
- `-ge` — Mayor o igual
- `-lt` — Menor que
- `-le` — Menor o igual
- `-e foo.txt` — Existe el archivo
- `-z foo` — Variable vacía

#### Operadores de cadena

- `=` — Igual
- `==` — Igual
- `-z` — Nula/vacía
- `-n` — No nula
- `<` — Menor (orden ASCII)
- `>` — Mayor (orden ASCII)

#### If

```bash
#!/bin/bash

if [[ $foo = 'bar' ]]; then
  echo 'one'
elif [[ $foo = 'bar' ]] || [[ $foo = 'baz' ]]; then
  echo 'two'
elif [[ $foo = 'ban' ]] && [[ $USER = 'bat' ]]; then
  echo 'three'
else
  echo 'four'
fi
```

#### If en línea

```bash
#!/bin/bash

[[ $USER = 'rehan' ]] && echo 'yes' || echo 'no'
```

#### Bucles while

```bash
#!/bin/bash

declare -i counter
counter=10
while [[ $counter -gt 2 ]]; do
  echo "The counter is $counter"
  counter=$((counter-1))
done
```

#### Bucles for

```bash
#!/bin/bash

for i in {0..10..2}; do
  echo "Index: $i"
done

for filename in file1 file2 file3; do
  echo "Content: " >> "$filename"
done

for filename in *; do
  echo "Content: " >> "$filename"
done
```

#### Case

```bash
#!/bin/bash

echo "What's the weather like tomorrow?"
read -r weather

case "$weather" in
  sunny|warm ) echo "Nice weather: $weather" ;;
  cloudy|cool ) echo "Not bad weather: $weather" ;;
  rainy|cold ) echo "Terrible weather: $weather" ;;
  * ) echo "Don't understand" ;;
esac
```
