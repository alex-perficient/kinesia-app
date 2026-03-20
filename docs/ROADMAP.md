# Roadmap de Kines.ia (Mon TI Labs)

## ✅ Fase 1-5: Completadas
- [x] Autenticación y Arquitectura Base
- [x] Creación de Pacientes y Perfiles
- [x] Evaluaciones Clínicas con IA Multimodal (Audio/Texto)
- [x] Reproductor de Audio desde Firebase Storage
- [x] Asignación y Registro de Rutinas (RPE/EVA)

## ✅ Fase 6.1: Comunicación
- [x] Notificaciones In-App Bidireccionales (Cartero Service)

## 🛠️ Fase de Estabilización (Deuda Técnica)
- [x] Archivar/Desactivar Pacientes (Soft Delete)
- [x] Editar/Eliminar Rutinas Asignadas (*PENDIENTE REVISAR SI SE REQUIERE EDITAR RUTINAS*)
- [x] Eliminar Notas Clínicas Duplicadas

## 🚧 Fase 6.2: Modelo de Negocio
- [x] Reglas de control de uso de IA (Contador en Firebase)
- [x] Bloqueos y pantallas Freemium vs Premium *Revisar si manda los whatsapps y empezar a subirlo a Playstore*

## 🎨 Fase 7: UI/UX y Retención
- [x] Estados vacíos (Empty States) ilustrados
- [x] Shimmer/Skeleton Loaders
- [ ] Gamificación básica (Rachas de días para el paciente)
- [ ] Rachas (Streaks) al estilo Duolingo (Rachas de días para el paciente)
- [ ] Sistema de Logros (Badges): Insignias visuales que se desbloquean al cumplir hitos. Ej: "Rodilla de Titanio" (10 ejercicios de pierna completados) o "Guerrero del RPE" (registrar 5 rutinas con esfuerzo máximo).
- [ ] Recompensas y Lealtad: Un sistema donde la constancia se traduce en puntos. Al llegar a cierta meta, la app les genera un cupón digital válido por un descuento en su próxima terapia presencial o descarga muscular.
- [x] Micro-interacciones (Para Fase 7): Lluvia de confeti en la pantalla y una vibración (haptic feedback) en el celular justo en el instante en que le dan "Guardar" a su bitácora de entrenamiento.



## 🛡️ Fase de Seguridad y Privacidad de Datos
- [ ] **Reglas de Firebase (Firestore & Storage):** Cerrar el acceso público. Configurar reglas para que un paciente solo pueda leer su propio documento y un fisio solo pueda leer/escribir sobre los pacientes que le pertenecen (`physioId == auth.uid`).
- [ ] **Sanitización de Datos:** Validar desde el código y desde la base de datos que los campos de texto no superen ciertos límites (prevención de inyección masiva de datos).
- [ ] **Cumplimiento Normativo (Expediente Clínico):** Integrar una pantalla de "Aviso de Privacidad / Consentimiento" donde el paciente acepte que sus datos y audios serán procesados por IA.
- [ ] **Bloqueo de Sesiones:** Asegurar el cierre de sesión automático tras inactividad prolongada en el dispositivo del fisio por tratarse de datos sensibles.

## 🚀 Fase 8: Producción Interna (MVP)
- [x] Generación de APK para distribución directa (WhatsApp/Email).
- [x] Pruebas de campo con el primer fisioterapeuta real.
- [ ] Recopilación de feedback y ajuste de flujos.
- [ ] Borrado masivo de base de datos (Wipe) para limpiar datos de prueba.
- [x] Generación de APK/App Bundle final
- [x] Despliegue en Firebase App Distribution para testers
- [ ] Login de Google y Apple

## 📋 BACKLOG DE PRODUCTO: Feedback del Fisioterapeuta (Sprint Actual)

### 🏗️ Épica 1: Reestructuración de la Interfaz (Fundación UI)
*Prioridad: ALTA | Status: En Progreso*
- [x] **1.1 Navegación Principal (Bottom Nav):** Separar los módulos de la app en pestañas (Pacientes, Calendario, Biblioteca, Perfil) para mejor organización espacial.
- [x] **1.2 Filtros de Pacientes:** Agregar "Chips" o botones de filtro rápido en el Dashboard para alternar entre pacientes de "Rehabilitación" y "Fitness".

### 🧠 Épica 2: Evolución del Modelo de Datos (Core)
*Prioridad: ALTA | Status: Pendiente (Requiere migración de base de datos)*
- [x] **2.1 Flexibilidad de Días:** Reemplazar el esquema rígido de días de la semana (Lunes, Martes) por "Día 1, Día 2, etc.".
- [ ] **2.2 Tracking de Adherencia:** Implementar pop-up de seguimiento si el paciente salta un día en el orden establecido, requiriendo justificación.
- [x] **2.3 Métricas Granulares por Ejercicio:** Mover las escalas (EVA, RPE, RIR) y parámetros (tiempo, peso, reps) de un modelo "por rutina" a un modelo "por ejercicio", soportando variables dinámicas (fuerza vs cardio).

### 🚀 Épica 3: Nuevos Módulos Mayores (Features Premium)
*Prioridad: MEDIA | Status: Pendiente*
- [x] **3.1 Biblioteca de Rutinas (Templates):** Crear una colección guardada por el fisio para clonar y asignar rutinas base a múltiples pacientes con ligeras variaciones.
- [ ] **3.2 Calendario de Asignaciones (Vista Global):** Un dashboard diario para el fisio donde visualice todas las actividades y pacientes programados para la fecha actual.
----------------------------------------------------------------------------------------------------------------
# 📋 Backlog de Producto: Kines.ia (Mon TI Labs)

## 🛡️ Épica 4: Seguridad, Privacidad y Autenticación
- [ ] **Reglas de Firebase (Firestore & Storage):** Cerrar el acceso público. Configurar reglas estrictas (`request.auth.uid`) para que un paciente solo lea su documento y el fisio solo interactúe con los pacientes asignados a su `physioId`.
- [ ] **Sanitización y Validación:** Implementar validadores de texto en formularios y base de datos para limitar caracteres y prevenir inyección masiva de datos.
- [ ] **Cumplimiento Normativo Clínico:** Pantalla obligatoria de "Aviso de Privacidad / Consentimiento" para el paciente, aceptando el procesamiento de sus datos de salud y multimedia por motores de IA.
- [ ] **Bloqueo de Sesiones Sensibles:** Auto-cierre de sesión o bloqueo por PIN/Biometría tras inactividad prolongada en el dispositivo del fisio.
- [ ] **Autenticación:** Integrar inicio de sesión rápido con Google (Google Sign-In) para ambos roles.

## 🧠 Épica 5: Monetización y Motor de Inteligencia Artificial
- [ ] **Lógica de Suscripción (Freemium):** Implementar contadores de volumen (pacientes/rutinas). Validar que al superar la cuota gratuita, el fisio deba pagar la mensualidad de 100 MXN o, de lo contrario, restringir el acceso a funcionalidades avanzadas y de IA.
- [ ] **Motor de Resúmenes IA (Arquitectura de Cero Costos):** Desarrollar una cola de tareas en el servidor que procese el historial del paciente en segundo plano. 
- [ ] **Notificación de Análisis:** Avisar al fisio mediante *push notification* únicamente cuando el resumen generado por la IA esté listo para su lectura.

## 📅 Épica 6: Control Clínico Avanzado (Dashboard)
- [x] **Calendario Mensual del Fisio:** Expandir la cinta horizontal a una vista de mes completo. Permitir programación de citas futuras y revisiones con indicadores visuales (código de colores) para días con eventos especiales.
- [x] **Línea de Tiempo Unificada:** Fusionar la captura de rutinas (`workout_logs`) y los reportes de bienestar emocional/físico (`daily_logs`) en una sola vista cronológica dentro del día seleccionado para dar contexto completo al fisio.
- [ ] **Métricas Granulares Dinámicas:** Extender la captura actual (EVA, RPE, Peso) a un modelo completamente "por ejercicio", soportando campos condicionales según el tipo de ejercicio (ej. RIR, tiempo bajo tensión, repeticiones efectivas vs. cardio).

## ✨ Épica 7: "Facelift" UI/UX y Retención (Capa Visual)
- [x] **Pulido de Interfaz Profesional:** Homologar radios de bordes, sombras, paleta cromática de la marca y estados vacíos (empty states) con ilustraciones para garantizar una experiencia de usuario *Premium*.
- [x] **Soporte Multimedia Libre:** Asegurar que el fisio pueda enviar fácilmente links de YouTube sugeridos o cargar sus propios videos explicativos.
- [ ] **Gamificación (Low Priority):** Sistema de rachas o recompensas visuales para pacientes con alta adherencia al tratamiento.


----------------------------------------------------------------------------------------------------------------

## 🏛️ Fase 9: Preparación para Google Play Store (Lanzamiento Oficial)
*Requisitos obligatorios de Google antes de publicar la app al público.*

**Seguridad y Legal:**
- [ ] **Reglas de Firebase:** Bloquear Firestore y Storage para que nadie pueda acceder sin autenticación ni leer expedientes ajenos.
- [ ] **Landing Page y Aviso de Privacidad:** Crear una página web sencilla de Mon TI Labs alojando el aviso de privacidad legal (Exigencia de Google para apps de salud).
- [ ] **Consentimiento de IA:** Pantalla obligatoria dentro de la app donde el paciente acepta que su voz y datos serán procesados por Inteligencia Artificial.

**Modelo de Negocio y Políticas:**
- [ ] **Pasarela de Pagos (Cumplimiento):** Reemplazar el botón de WhatsApp por un enlace externo a Stripe (fuera de la app) o integrar Google Play Billing (pagando el 15% de comisión) para evitar bloqueos por venta de bienes digitales.

**Consola de Google Play:**
- [ ] **Material Promocional (Store Listing):** Diseñar el ícono en alta resolución (512x512), capturas de pantalla promocionales y banner principal.
- [ ] **Pruebas Cerradas (Regla de los 20 Testers):** Registrar a 20 personas con cuenta de Google para que tengan la app instalada y opt-in durante 14 días continuos.
- [ ] **Compilación Final (.aab):** Generar el archivo Android App Bundle (`.aab`), que es el formato moderno y obligatorio que exige Google, reemplazando al `.apk`.

## 🔮 Backlog / Lluvia de Ideas (Futuros Features a evaluar)
*Estas son características de alto impacto que se desarrollarán a mediano/largo plazo para escalar Kines.ia.*

- [ ] **Analítica con IA (Reportes de Evolución):** Prompt para que Gemini lea el historial de un paciente de los últimos 2 meses y redacte un resumen médico de evolución (Ideal para entregar a médicos traumatólogos).
- [x] **Plantillas de Rutinas:** Guardar rutinas pre-armadas (ej. "Esguince de Tobillo Fase 1") para asignarlas con un clic a múltiples pacientes.
- [ ] **Corrección de Técnica (Video Asíncrono):** Permitir al paciente grabarse 10 segundos haciendo un ejercicio y subirlo para que el Fisio corrija su postura desde la app.
- [ ] **Catálogo de Videos Propios:** Permitir al Fisio enlazar sus propios videos de YouTube o subir videos cortos para sustituir las animaciones genéricas de los ejercicios.
- [ ] **Integración de Hardware (Wearables):** A largo plazo, conectar la app con Apple Health o Google Fit para medir actividad diaria pasiva del paciente.




# Feedback de Testers
Análisis del Feedback y Plan de Ataque (Backlog)
Tus testers acaban de darte la hoja de ruta exacta para escalar tu software y expandir el paraguas de Mon TI Labs. Aquí tienes el Backlog organizado por prioridades para que mantengamos el enfoque.

📦 **SPRINT 1: Victorias Rápidas (Lo que podemos atacar hoy/mañana)**
Estas son fricciones visuales y operativas que resolvemos rápido y dan mucho valor.

1. **Optimización del Dashboard (UI/UX):** 
- [x] Reducir el tamaño de la cabecera Dark Slate en celulares para que la lista de pacientes ocupe el 70% de la pantalla. Haremos las tarjetas de pacientes más compactas. 

2. **Semáforo Clínico (Retención B2B):** 
- [x] Conectar la lógica para que los dolores altos disparen alertas en la campanita del fisio.

3. **Formularios Dinámicos en Evaluación Asistida:** 
- [x] Rediseñar la pantalla para que el fisio capture datos demográficos primero, y agregar un botón de "+ Agregar Campo Personalizado" (ej. Alergias, Dieta) igual que como agregan ejercicios a una rutina.

4. **Racha Diaria (Gamificación B2C):** 
- [x] Un simple contador numérico en la vista del paciente que premie la constancia.

🚀 **SPRINT 2: Expansión de Valor (Próxima semana)**
Estas tareas requieren crear nuevas colecciones en Firebase y rediseñar flujos.

5. **El Banco Maestro de Ejercicios:** 
- [x] Dividir la biblioteca en dos pestañas: "Mis Ejercicios Personalizados" y "Banco Kines.ia" (una base de datos global pre-cargada y agrupada por músculo/máquina).

6. **El Perfil Profesional vs. Usuario:** 
- [x] Terminar la pantalla de "Construcción". Aquí crearemos un switch (modo Dios) para que el especialista alterne entre su vista de "Clínica" (para trabajar) y su vista de "Paciente" (para hacer sus propias rutinas). Además, generaremos una "Tarjeta de Presentación Digital" pública para que consigan clientes.

🎯 **SPRINT 3: Nuevas Verticales y Monetización High-Ticket (Futuro)**
Esto es expansión de negocio pura.

7. **Módulo de Nutrición y Tracking GPS:** 
- [ ] Abrir el sistema para nutriólogos. Para la parte de registrar rutas al salir a correr, será ideal aprovechar la arquitectura y la infraestructura de geolocalización que ya estás desarrollando para Gula Maps. Podemos integrar esos módulos para que convivan en el mismo ecosistema.

8. **Marca Blanca (White-Labeling):** 
- [ ] El modelo de negocio definitivo. Un fisio te paga $500 - $1,000 USD mensuales o un setup fee alto. Tú clonas el código, cambias los colores, pones su logo, y le compilas su propia app en la App Store bajo la infraestructura de Mon TI Labs. Es un servicio "Premium VIP" que no requiere programar la app de cero, solo cambiar variables de entorno.