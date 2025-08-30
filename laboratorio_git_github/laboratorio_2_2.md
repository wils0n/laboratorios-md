# Lab: Trunk-Based Development con Feature Flags \*\*

**Duración estimada:** 45--60 min\
**Nivel:** Intermedio\
**Contexto:** Implementarás **Trunk-Based Development (TBD)** con **feature flags** y **conventional commits** usando LaunchDarkly. Trabajarás sobre el proyecto Galaxy Marketplace Example App para aplicar TBD con feature flags reales.\
**Prerequisito:** Cuenta de LaunchDarkly (trial gratuito de 14 días) y conocimientos básicos de Git

---

## Objetivos de aprendizaje

Al finalizar, podrás:

- Implementar **Trunk-Based Development** con ramas de corta duración.
- Usar **conventional commits** de forma consistente.
- Aplicar **feature flags con LaunchDarkly** para desacoplar deployment de release.
- Realizar **commits frecuentes** directamente a `main`.
- Gestionar **feature toggles** para funcionalidades en desarrollo.
- Configurar **funnel experiments** para medir impacto de cambios.
- Usar **métricas y eventos** para análisis de experimentos.

---

## Conceptos clave de TBD

### Trunk-Based Development (TBD)

- **Trunk (main)**: Rama principal donde todos los desarrolladores integran código frecuentemente.
- **Ramas de corta duración**: Máximo 2-3 días antes de merge.
- **Commits pequeños y frecuentes**: Integración continua para evitar conflictos.
- **Feature flags**: Ocultar funcionalidades no terminadas sin bloquear deployment.

### LaunchDarkly Feature Flags

LaunchDarkly es una plataforma de feature flags que permite:

- **Desacoplamiento**: Deploy código sin activar funcionalidades.
- **Rollback instantáneo**: Desactivar features sin redeploy.
- **Targeting**: Activar features para usuarios específicos.
- **Experimentos**: A/B testing y análisis de impacto.

### Conventional Commits

Formato estándar para mensajes de commit:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Tipos principales:**

- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `chore`: Tareas de mantenimiento
- `docs`: Documentación
- `style`: Formato de código
- `refactor`: Refactoring sin cambio funcional
- `test`: Agregar o modificar tests

---

## Requisitos del laboratorio

- **Node.js y NPM** instalados en tu máquina.
- **Git** configurado.
- Terminal.
- Cuenta de **LaunchDarkly** (trial gratuito de 14 días).
- Cuenta de **GitHub**.

---

## Introducción a Feature Flags

### ¿Qué son los Feature Flags?

Los feature flags son simplemente **condicionales (if statements)** que nos permiten activar o desactivar funcionalidades en tiempo de ejecución, sin necesidad de hacer un nuevo deploy de la aplicación.

**Ejemplo básico:**

```javascript
import express from "express";

const app = express();
const port = 3000;

// Feature flag básico
const feature_flag = false; // ⬅️ Esta variable controla la funcionalidad

app.get("/", (req, res) => {
  if (feature_flag) {
    res.send("Feature flag is ON - Nueva funcionalidad activa!");
  } else {
    res.send("Feature flag is OFF - Funcionalidad original");
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
```

### ¿Por qué usar Feature Flags?

1. **Desacoplamiento**: Deploy código sin activar funcionalidades
2. **Rollback instantáneo**: Desactivar features sin redeploy
3. **Testing gradual**: Activar para ciertos usuarios primero
4. **Trunk-Based Development**: Permite commits frecuentes a main
5. **Experimentación**: A/B testing y análisis de impacto

### De Feature Flags básicos a LaunchDarkly

Mientras que el ejemplo anterior usa una variable simple, en producción necesitamos:

- **Control externo**: Cambiar flags sin tocar código
- **Targeting**: Activar para usuarios específicos
- **Experimentos**: Métricas y análisis automático
- **Rollback instantáneo**: Interface web para emergencias

LaunchDarkly nos proporciona todas estas capacidades profesionales.

---

## Conceptos clave de TBD

---

## Ejercicio 1: Configurar LaunchDarkly y servidor básico

### Tarea 1: Configurar LaunchDarkly

1. Crea una cuenta en [LaunchDarkly](https://launchdarkly.com) (trial gratuito de 14 días).

2. Crea un nuevo proyecto llamado **TBD Feature Flags Lab**:

   - Ve a **Account Settings** → **Projects** → **Create project**
   - **Name**: TBD Feature Flags Lab
   - **Key**: tbd-feature-flags-lab (auto-generado)

3. Obtén las claves SDK:
   - Ve a **Account Settings** → **Projects** → **TBD Feature Flags Lab**
   - Copia el **SDK Key** del entorno **Production**
   - Copia el **Client-side ID** del entorno **Production**

### Tarea 2: Configurar servidor Node.js con feature flags

1. Clona el repositorio del servidor básico:

   ```bash
   git clone https://github.com/wils0n/server-nodejs-ff.git
   cd server-nodejs-ff
   ```

2. Instala las dependencias:

   ```bash
   npm install
   ```

3. Configura las variables de entorno:

   ```bash
   # Renombrar el archivo de ejemplo
   cp .env.example .env
   ```

4. Edita el archivo `.env` con tus claves de LaunchDarkly:

   ```bash
   # Backend SDK Key
   LD_SDK_KEY=sdk-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   LD_EVENT_KEY=tbd-lab
   ```

5. Inicia el servidor:

   ```bash
   node server.mjs
   ```

   Accede a [http://localhost:3000](http://localhost:3000) para verificar que funciona.

### Tarea 3: Crear tu primer feature flag

1. En tu dashboard de LaunchDarkly, ve a **Feature flags** → **Create flag**:

   - **Name**: New Menu Features
   - **Key**: `feat-new-menu`
   - **Flag type**: Boolean
   - **Description**: "Activa nuevos features de menú en el servidor"
   - **Tags**: `backend`, `menu`, `experiment`

2. Configura las variaciones:

   - **True**: Mostrar nuevo menú
   - **False**: Mantener menú original

3. **Activa el flag** en el entorno **Test** pero **déjalo en false** inicialmente.

4. Realiza tu primer commit con TBD:

   ```bash
   git add .env
   git commit -m "feat(config): configure LaunchDarkly integration

   - Add SDK keys for backend feature flags
   - Enable feat-new-menu flag evaluation
   - Ready for trunk-based development workflow"
   git push origin main
   ```

---

## Ejercicio 2: Implementar feature flag en el servidor

### Tarea 1: Entender el código del servidor

1. Revisa el archivo `server.mjs` en tu proyecto:

   ```javascript
   import * as LaunchDarkly from "@launchdarkly/node-server-sdk";
   import express from "express";
   import dotenv from "dotenv";

   dotenv.config();

   const app = express();
   const port = 3000;

   // Inicializar cliente de LaunchDarkly
   const client = LaunchDarkly.init(process.env.LD_SDK_KEY);

   // Contexto del usuario para evaluación de flags
   const context = {
     kind: "user",
     key: "user-key-123abcde",
     email: "test@example.com",
   };

   client.once("ready", function () {
     console.log("SDK successfully initialized!");

     app.get("/", async (req, res) => {
       // Tracking de eventos
       client.track(process.env.LD_EVENT_KEY, context);

       // Evaluación del feature flag
       client.variation(
         "feat-new-menu",
         context,
         false, // Valor por defecto si el flag no existe
         function (err, showFeature) {
           if (showFeature) {
             console.log("feature true");
             res.send("🎉 Feature flag is ON - New menu active!");
           } else {
             console.log("feature false");
             res.send("Feature flag is OFF - Original menu");
           }
         }
       );
     });

     app.listen(port, () => {
       console.log(`Server is running on port ${port}`);
     });
   });
   ```

### Tarea 2: Probar el feature flag

1. Con el flag **desactivado** (false) en LaunchDarkly:

   - Visita [http://localhost:3000](http://localhost:3000)
   - Deberías ver: "Feature flag is OFF - Original menu"

2. En LaunchDarkly, **activa** el flag `feat-new-menu`:

   - **Targeting**: ON
   - **Default rule**: Serve **true**
   - **Save changes**

3. Refresca la página:

   - Ahora deberías ver: "🎉 Feature flag is ON - New menu active!"

4. Commit del test:

   ```bash
   git add server.mjs
   git commit -m "test(flag): validate feat-new-menu flag behavior

   - Confirm flag evaluation works correctly
   - Test both ON and OFF states
   - LaunchDarkly integration functioning properly"
   git push origin main
   ```

### Tarea 3: Iteración con TBD - Mejorar el servidor

1. Agrega más funcionalidad con el mismo flag:

   ```javascript
   // Agregar después de la ruta existente
   app.get("/menu", (req, res) => {
     client.variation(
       "feat-new-menu",
       context,
       false,
       function (err, showFeature) {
         if (showFeature) {
           res.json({
             menu: [
               { id: 1, name: "🍔 Premium Burger", price: 15.99 },
               { id: 2, name: "🍕 Artisan Pizza", price: 18.5 },
               { id: 3, name: "🥗 Gourmet Salad", price: 12.99 },
             ],
             features: ["new-recipes", "nutritional-info", "customization"],
           });
         } else {
           res.json({
             menu: [
               { id: 1, name: "Burger", price: 10.99 },
               { id: 2, name: "Pizza", price: 14.5 },
             ],
           });
         }
       }
     );
   });
   ```

2. Commit inmediato (TBD):

   ```bash
   git add server.mjs
   git commit -m "feat(menu): add /menu endpoint with feature flag

   - New endpoint returns enhanced menu when flag is ON
   - Maintains backward compatibility when flag is OFF
   - Safe to deploy - hidden behind existing flag"
   git push origin main
   ```

3. Prueba la nueva ruta:
   - Visita [http://localhost:3000/menu](http://localhost:3000/menu)
   - Cambia el flag en LaunchDarkly y ve las diferencias

---

## Ejercicio 3: Configurar Galaxy Marketplace con feature flags

### Tarea 1: Clonar y configurar Galaxy Marketplace

1. En una nueva terminal, clona el repositorio de Galaxy Marketplace:

   ```bash
   git clone https://github.com/wils0n/Galaxy-Marketplace-Example-App.git
   cd Galaxy-Marketplace-Example-App
   ```

2. Instala las dependencias:

   ```bash
   npm install
   ```

3. Configura las variables de entorno:

   ```bash
   # Copiar archivo de ejemplo
   cp .env.example .env
   ```

4. Edita el archivo `.env` con las mismas claves de LaunchDarkly:

   ```bash
   # Backend SDK Key (para server-node/server.mjs)
   LD_SDK_KEY=sdk-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   LD_EVENT_KEY=tbd-lab

   # Frontend Client Key (para Next.js)
   NEXT_PUBLIC_LD_CLIENT_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

5. Inicia la aplicación:

   ```bash
   npm run dev
   ```

   Accede a [http://localhost:3000](http://localhost:3000) para verificar que funciona.

### Tarea 2: Implementar feature flag en frontend (marketplace.tsx)

1. Revisa el código en `pages/marketplace.tsx` para entender la implementación:

   ```tsx
   import { useFlags, useLDClient } from "launchdarkly-react-client-sdk";

   export default function Marketplace() {
     // Obtener flags de LaunchDarkly
     const { featNewMenu } = useFlags();
     const LDClient = useLDClient();

     // Renderizado condicional basado en feature flag
     {
       featNewMenu && (
         <div className="mt-4 sm:mt-6 gap-x-2 gap-y-4 sm:gap-y-0 grid grid-cols-3 sm:flex sm:grid-cols-0">
           <Badge className="text-lg border-2 bg-transparent border-gray-500 text-ldlightgray">
             Accessories
           </Badge>
           <Badge className="text-lg border-2 bg-transparent border-gray-500 text-ldlightgray">
             Gifts for devs
           </Badge>
           <Badge className="text-lg border-2 bg-transparent border-gray-500 text-ldlightgray">
             Popular shops
           </Badge>
           <Badge className="text-lg border-2 bg-transparent border-gray-500 text-ldlightgray">
             Best sellers
           </Badge>
           <Badge className="text-lg border-2 bg-transparent border-gray-500 text-ldlightgray">
             Newest
           </Badge>
           <Badge className="text-lg border-2 bg-transparent border-gray-500 text-ldlightgray">
             Top deals
           </Badge>
         </div>
       );
     }
   }
   ```

2. Observa el tracking de eventos para experimentos:

   ```tsx
   const addToCart = (item: any) => {
     // Tracking cuando se agrega item al carrito
     LDClient?.track("item-added", LDClient.getContext(), 1);
     setCart([...cart, item]);
   };

   const storeAccessed = () => {
     // Tracking cuando se accede a una tienda
     LDClient?.track("item-accessed", LDClient.getContext(), 1);
   };
   ```

### Tarea 3: Probar la integración completa

1. Con el flag **desactivado** en LaunchDarkly:

   - Los badges del menú NO deberían aparecer en la página

2. **Activa** el flag `feat-new-menu` en LaunchDarkly:

   - Refresca la página
   - Los badges del menú deberían aparecer

3. Commit de la configuración:

   ```bash
   git add .env
   git commit -m "feat(config): configure LaunchDarkly for Galaxy Marketplace

   - Add SDK keys for frontend and backend integration
   - Enable feat-new-menu flag in marketplace
   - Ready for A/B testing and experiments"
   git push origin main
   ```

---

## Comandos útiles para TBD con LaunchDarkly (referencia rápida)

```bash
# Flujo básico TBD
git pull origin main         # Sincronizar frecuentemente
git add .
git commit -m "feat(scope): small incremental change"
git push origin main         # Push inmediato

# Conventional commits ejemplos
git commit -m "feat(auth): add OAuth2 login support"
git commit -m "fix(api): handle null response in user service"
git commit -m "chore(deps): update security dependencies"
git commit -m "docs(readme): update deployment instructions"
git commit -m "test(user): add unit tests for dashboard service"
git commit -m "refactor(config): extract feature flags to service"

# Feature flags management
npm run dev                     # Start Galaxy Marketplace locally
curl http://localhost:3000      # Test backend flag evaluation
grep -r "useFlags" pages/       # Find frontend flag usage
grep -r "track" pages/          # Find event tracking calls

# LaunchDarkly operations
# (Done via web UI)
# - Enable/disable flags instantly
# - View experiment results
# - Monitor flag usage and events
# - Set targeting rules and rollout percentages

# Hotfix rápido
git add -A
git commit -m "fix(critical): resolve production issue"
git push origin main

# Rollback de feature flag
# (Via LaunchDarkly web UI - instant rollback)
# En caso de emergencia, hacer via código:
sed -i 's/= true/= false/' .env
git commit -m "fix(emergency): disable feat-new-menu flag"

# Experimentos y análisis
# Comandos para simular análisis local
echo '{"experiment": "feat-new-menu", "result": "success"}' > results.json
git commit -m "test(experiment): record experiment results"
```

---

## Criterios de éxito (Checklist)

- [ ] **Conceptos básicos**: Entiendes qué son los feature flags (if statements)
- [ ] **LaunchDarkly configurado**: Cuenta y proyecto creados correctamente
- [ ] **Servidor backend**: server-nodejs-ff funcionando con feature flags
- [ ] **Frontend marketplace**: Galaxy Marketplace con flags integrados
- [ ] **TBD implementado**: Commits frecuentes directamente a main
- [ ] **Conventional commits**: Todos los commits siguen el estándar

---

## Mejores prácticas de TBD con Feature Flags

### ✅ Hacer:

- **Commits pequeños y frecuentes** (varias veces al día)
- **Feature flags** para ocultar trabajo en progreso
- **Integración continua** con cada push
- **Tests automatizados** que se ejecuten rápido
- **Rollback rápido** con feature flags si hay problemas
- **Experimentos A/B** para validar cambios

### ❌ Evitar:

- Ramas de larga duración (más de 2-3 días)
- Commits grandes que cambien muchas cosas
- Desarrollar sin feature flags para funcionalidades grandes
- Push sin ejecutar tests localmente
- Merge conflicts por falta de sincronización
- Releases sin experimentación previa
- Cambios directos en producción sin flags
- Mantener flags obsoletos por mucho tiempo

### 🔄 Flujo TBD con LaunchDarkly:

1. `git pull origin main` (sincronizar)
2. Hacer cambio pequeño con feature flag
3. `git add` + `git commit` con conventional commit
4. `git push origin main` (inmediatamente)
5. Verificar CI pasa
6. Configurar experimento en LaunchDarkly
7. Habilitar flag para % de usuarios
8. Monitorear métricas y resultados
9. Rollout gradual o rollback según resultados
10. Repetir

---

## Diferencias clave con GitHub Flow y feature flags tradicionales

| Aspecto                   | GitHub Flow              | TBD + LaunchDarkly                     |
| ------------------------- | ------------------------ | -------------------------------------- |
| **Ramas**                 | Feature branches largas  | Solo main + ramas muy cortas           |
| **Pull Requests**         | Obligatorios             | Opcionales, solo para cambios grandes  |
| **Frecuencia de commits** | Al final de feature      | Múltiples veces al día                 |
| **Feature toggles**       | No necesarios            | Esenciales con plataforma externa      |
| **Tiempo de integración** | Al final del desarrollo  | Continuo durante desarrollo            |
| **Conflictos**            | Más probables            | Minimizados por integración frecuente  |
| **Rollbacks**             | Requiere redeploy        | Instantáneo via LaunchDarkly UI        |
| **Experimentos**          | Difíciles de implementar | Built-in A/B testing y métricas        |
| **Targeting**             | No disponible            | Por usuario, región, dispositivo, etc. |

---

## Solución de problemas frecuentes

- **"No puedo hacer push a main"**: Verifica permisos del repositorio
- **"LaunchDarkly no conecta"**: Verifica SDK keys en archivo .env
- **"Feature flag no funciona"**: Verifica que el flag esté activado en LaunchDarkly
- **"Conventional commit inválido"**: Revisa el formato: `type(scope): description`
- **"Merge conflicts"**: Sincroniza más frecuentemente con `git pull origin main`
- **"No veo métricas"**: Verifica que los eventos se estén enviando correctamente
- **"Experimento sin resultados"**: Asegúrate de tener suficiente tráfico y tiempo
- **"Flag evaluation lenta"**: Verifica conexión a LaunchDarkly y considera caching
