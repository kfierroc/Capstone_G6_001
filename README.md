# 🚒💧🏘️ Sistema de Gestión de Emergencias - Bomberos, Grifos y Residente

Este proyecto contiene tres aplicaciones Flutter que pueden compartir una base de datos común de usuarios mediante Supabase:

- **Bomberos**: Sistema de información de emergencias
- **Grifos**: Sistema de gestión de grifos de agua
- **Residente**: Sistema de registro de residentes y sus datos

## 📌 Características Principales

✅ **Autenticación compartida** - Una misma cuenta funciona en ambas aplicaciones  
✅ **Base de datos centralizada** - Todos los usuarios en una sola base de datos Supabase  
✅ **Seguridad robusta** - Row Level Security (RLS) en Supabase  
✅ **Validación de RUT chileno** - Validación automática en el registro  
✅ **Recuperación de contraseña** - Por correo electrónico  
✅ **Diseño responsivo** - Funciona en móvil, tablet y desktop  

## 🏗️ Estructura del Proyecto

```
EvidenciasdesistemaAplicacion/
├── Bomberos/                    # Aplicación de Bomberos (Personal de emergencias)
│   ├── lib/
│   │   ├── config/
│   │   │   └── supabase_config.dart
│   │   ├── services/
│   │   │   └── supabase_auth_service.dart  # Servicio de autenticación compartido
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login.dart
│   │   │   │   ├── register.dart
│   │   │   │   └── password.dart
│   │   │   └── home/
│   │   └── main.dart
│   ├── .env                     # Credenciales de Supabase (no incluido en Git)
│   ├── .env.example            # Ejemplo de archivo .env
│   └── pubspec.yaml
│
├── Grifos/                      # Aplicación de Grifos (Gestión de grifos)
│   ├── lib/
│   │   ├── config/
│   │   │   └── supabase_config.dart
│   │   ├── services/
│   │   │   └── supabase_auth_service.dart  # Servicio de autenticación compartido
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login.dart
│   │   │   │   ├── register.dart
│   │   │   │   └── password.dart
│   │   │   └── home/
│   │   └── main.dart
│   ├── .env                     # Credenciales de Supabase (no incluido en Git)
│   ├── .env.example            # Ejemplo de archivo .env
│   └── pubspec.yaml
│
├── Residente/                   # Aplicación de Residente (Ciudadanos)
│   ├── lib/
│   │   ├── config/
│   │   │   └── supabase_config.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart        # Servicio de autenticación
│   │   │   └── database_service.dart    # Servicio de base de datos
│   │   ├── models/
│   │   │   ├── family_member.dart
│   │   │   ├── pet.dart
│   │   │   └── registration_data.dart
│   │   ├── screens/
│   │   │   ├── auth/                    # Login, registro, recuperación
│   │   │   ├── registration_steps/     # Registro por pasos (wizard)
│   │   │   └── home/
│   │   │       └── tabs/                # Familia, mascotas, residencia
│   │   └── main.dart
│   ├── .env                     # Credenciales de Supabase (no incluido en Git)
│   ├── .env.example            # Ejemplo de archivo .env
│   └── pubspec.yaml
│
├── supabase_setup.sql          # Script SQL para configurar la base de datos
├── CONFIGURACION_SUPABASE.md   # Guía detallada de configuración (NO EXISTE)
├── ARQUITECTURA_COMPARTIDA.md  # Arquitectura del sistema compartido
└── README.md                    # Este archivo
```

## 🚀 Inicio Rápido

### 1. Clonar el Repositorio

```bash
git clone <url-del-repositorio>
cd EvidenciasdesistemaAplicacion
```

### 2. Configurar Supabase

Sigue la guía completa en **[CONFIGURACION_SUPABASE.md](./CONFIGURACION_SUPABASE.md)**

**Resumen:**
1. Crea una cuenta en [Supabase](https://supabase.com)
2. Crea un nuevo proyecto
3. Ejecuta el script SQL: `supabase_setup.sql`
4. Obtén tus credenciales (URL y anon key)

### 3. Configurar las Aplicaciones

#### Bomberos:

```bash
cd Bomberos
cp .env.example .env
# Edita .env y agrega tus credenciales de Supabase
flutter pub get
flutter run
```

#### Grifos:

```bash
cd ../Grifos
cp .env.example .env
# Edita .env con las MISMAS credenciales de Supabase
flutter pub get
flutter run
```

#### Residente:

```bash
cd ../Residente
cp .env.example .env
# Edita .env con las MISMAS credenciales (si quieres compartir usuarios)
# O con credenciales DIFERENTES (si quieres BD separada)
flutter pub get
flutter run
```

## 📝 Archivo .env

Ambas aplicaciones necesitan un archivo `.env` en su raíz:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-clave-anon-aqui
```

⚠️ **IMPORTANTE:** 
- Usa las **mismas credenciales** en ambas aplicaciones
- Nunca subas el archivo `.env` a Git (ya está en `.gitignore`)
- Usa `.env.example` como referencia

## 🗄️ Base de Datos

### Tabla `profiles`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | ID del usuario (referencia a auth.users) |
| full_name | TEXT | Nombre completo |
| rut | TEXT | RUT chileno (único) |
| fire_company | TEXT | Nombre de la compañía de bomberos |
| email | TEXT | Email del usuario |
| created_at | TIMESTAMP | Fecha de creación |
| updated_at | TIMESTAMP | Fecha de última actualización |

### Políticas de Seguridad (RLS)

- ✅ Los usuarios pueden ver su propio perfil
- ✅ Los usuarios pueden actualizar su propio perfil
- ✅ Cualquiera puede crear un perfil (durante el registro)

## 🔐 Autenticación

Ambas aplicaciones usan el servicio `SupabaseAuthService` que proporciona:

- **`signInWithPassword()`** - Iniciar sesión
- **`signUp()`** - Registrar nuevo usuario
- **`signOut()`** - Cerrar sesión
- **`resetPassword()`** - Recuperar contraseña
- **`updateProfile()`** - Actualizar perfil

## 🛠️ Tecnologías

- **Flutter** - Framework de desarrollo
- **Supabase** - Backend as a Service
  - PostgreSQL - Base de datos
  - Auth - Autenticación
  - Row Level Security - Seguridad
- **flutter_dotenv** - Variables de entorno
- **supabase_flutter** - Cliente de Supabase

## 🧪 Pruebas

### Registro de Usuario en Bomberos/Grifos:

1. Abre la app Bomberos
2. Haz clic en "Regístrate"
3. Completa el formulario:
   - Nombre: Juan Pérez
   - RUT: 12.345.678-9
   - Compañía: Primera Compañía de Santiago
   - Email: juan@ejemplo.com
   - Contraseña: test123
4. Regístrate

### Registro de Usuario en Residente:

1. Abre la app Residente
2. Haz clic en "Crear Cuenta"
3. Completa el wizard de 4 pasos:
   - Paso 1: Email y contraseña
   - Paso 2: Datos personales
   - Paso 3: Información de residencia
   - Paso 4: Detalles de vivienda
4. Finaliza el registro

### Login Cruzado (si comparten credenciales):

1. Cierra sesión en Bomberos
2. Abre la app Grifos
3. Inicia sesión con juan@ejemplo.com / test123
4. ✅ ¡Debería funcionar!
5. Cierra sesión en Grifos
6. Abre la app Residente
7. Inicia sesión con juan@ejemplo.com / test123
8. ✅ ¡También debería funcionar!

## 📱 Capturas de Pantalla

### App Bomberos
- Pantalla de login con gradiente azul
- Formulario de registro con validación de RUT
- Sistema de recuperación de contraseña
- Interfaz optimizada para personal de emergencias

### App Grifos
- Pantalla de login con gradiente personalizado
- Mismo sistema de autenticación
- Interfaz optimizada para gestión de grifos
- Widgets personalizados y reutilizables

### App Residente
- Registro por pasos (wizard multi-paso)
- Navegación con tabs (Familia, Mascotas, Residencia)
- StreamBuilder para navegación automática
- Logs detallados para debugging

## 🐛 Solución de Problemas

### Error: "Las credenciales de Supabase no están configuradas"

**Solución:** Verifica que el archivo `.env` existe y contiene las variables correctas.

```bash
# Verifica que el archivo existe
ls -la .env

# El contenido debe ser:
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=...
```

### Error: "Invalid login credentials"

**Causas posibles:**
- Usuario no registrado
- Email o contraseña incorrectos
- Confirmación de email pendiente (si está habilitada)

**Solución:** Verifica en el Dashboard de Supabase (Authentication > Users) que el usuario existe.

### Error al ejecutar `flutter pub get`

**Solución:** Asegúrate de tener Flutter instalado y actualizado:

```bash
flutter doctor
flutter pub get
```

## 🤝 Contribución

Si encuentras un bug o tienes una sugerencia:

1. Crea un issue describiendo el problema
2. Si tienes una solución, crea un pull request
3. Asegúrate de probar en ambas aplicaciones

## 📄 Licencia

Este proyecto es de código abierto y está disponible para uso educativo.

## 👥 Autores

- Sistema de Emergencias - Bomberos (Personal de emergencias)
- Sistema de Gestión - Grifos (Gestión de recursos de agua)
- Sistema de Residentes - Residente (Ciudadanos y sus datos)

## 🆘 Soporte

Si necesitas ayuda:

1. Revisa la documentación en `CONFIGURACION_SUPABASE.md`
2. Verifica los logs en la consola de Flutter
3. Revisa los logs de Supabase (Dashboard > Logs)
4. Crea un issue en el repositorio

---

## 🔄 Resumen de Diferencias entre Apps

| Característica | Bomberos | Grifos | Residente |
|----------------|----------|--------|-----------|
| **Navegación** | Manual | Manual | Automática (StreamBuilder) |
| **Registro** | Formulario único | Formulario único | Wizard de 4 pasos |
| **Widgets** | Directos | Personalizados | Personalizados |
| **Servicio Auth** | supabase_auth_service | supabase_auth_service | auth_service |
| **Metadata** | No | No | Sí (nombre, teléfono) |
| **PKCE** | No | No | Sí (más seguro) |
| **Logs** | Básicos | Básicos | Detallados |
| **Tabs** | No | No | Sí (4 tabs) |

---

**¡Gracias por usar nuestro sistema! 🚒💧🏘️**

