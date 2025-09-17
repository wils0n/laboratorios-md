https://awspolicygen.s3.amazonaws.com/policygen.html

# Guía: Subida de imagen a S3 y configuración de acceso público con Policy Generator

**Objetivo:**
- Crear un bucket S3
- Subir una imagen
- Generar y aplicar una política para dar acceso público a la imagen
- Acceder a la imagen desde la web

---

## 1. Crear un bucket S3

1. Ingresa a la consola de AWS S3: https://s3.console.aws.amazon.com/s3/
2. Haz clic en "Crear bucket".
3. Asigna un nombre único (ejemplo: `utec-demo-bucket-<tuusuario>`).
4. Selecciona la región deseada.
5. Deja el resto de opciones por defecto y crea el bucket.

---

## 2. Subir una imagen al bucket

1. Ingresa al bucket recién creado.
2. Haz clic en "Cargar" o "Upload".
3. Selecciona una imagen desde tu computadora (ejemplo: `foto.jpg`).
4. Haz clic en "Cargar" para subir la imagen.

---

## 3. Agregar la política al bucket

1. Ve a la consola de S3 y entra a la configuración de tu bucket.
2. Haz clic en "Permisos" > "Política de bucket" (Bucket Policy).
3. Pega el JSON de la política generada.
4. Guarda los cambios.

---

## 4. Generar una política de acceso público para la imagen

1. Ve al AWS Policy Generator: https://awspolicygen.s3.amazonaws.com/policygen.html
2. Selecciona "S3 Bucket Policy" como tipo de política.
3. En "Effect" selecciona "Allow".
4. En "Principal" pon: `*`
5. En "Actions" selecciona: `GetObject`
6. En "Amazon Resource Name (ARN)" pon la ruta de tu imagen:
   - Formato: `arn:aws:s3:::<nombre-del-bucket>/<nombre-de-la-imagen>`
   - Ejemplo: `arn:aws:s3:::utec-demo-bucket-usuario/foto.jpg`
7. Haz clic en "Add Statement" y luego en "Generate Policy".
8. Copia el JSON generado.

---

## 5. Acceder a la imagen desde la web

1. Ve a la consola de S3, entra a tu bucket y haz clic sobre la imagen subida.
2. Copia la "URL del objeto" (Object URL), que tendrá el formato:
   - `https://<nombre-del-bucket>.s3.<region>.amazonaws.com/<nombre-de-la-imagen>`
3. Pega la URL en tu navegador. Si todo está correcto, deberías ver la imagen.

---

## 6. Consideraciones de seguridad
- Dar acceso público a objetos S3 puede exponer información. Hazlo solo para pruebas o recursos públicos.
- Para restringir el acceso, elimina la política o usa permisos más específicos.

---

## Checklist
- [ ] Bucket creado
- [ ] Imagen subida
- [ ] Política generada y aplicada
- [ ] Imagen accesible vía URL pública

---

¡Listo! Has configurado acceso público a una imagen en S3 usando el Policy Generator.