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
- [ ] Editar/Eliminar Rutinas Asignadas (*PENDIENTE REVISAR SI SE REQUIERE EDITAR RUTINAS*)
- [x] Eliminar Notas Clínicas Duplicadas

## 🚧 Fase 6.2: Modelo de Negocio
- [x] Reglas de control de uso de IA (Contador en Firebase)
- [ ] Bloqueos y pantallas Freemium vs Premium *Revisar si manda los whatsapps y empezar a subirlo a Playstore*

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
- [ ] Pruebas de campo con el primer fisioterapeuta real.
- [ ] Recopilación de feedback y ajuste de flujos.
- [ ] Borrado masivo de base de datos (Wipe) para limpiar datos de prueba.
- [ ] Generación de APK/App Bundle final
- [ ] Despliegue en Firebase App Distribution para testers
- [ ] Login de Google y Apple

## 📋 BACKLOG DE PRODUCTO: Feedback del Fisioterapeuta (Sprint Actual)

### 🏗️ Épica 1: Reestructuración de la Interfaz (Fundación UI)
*Prioridad: ALTA | Status: En Progreso*
- [ ] **1.1 Navegación Principal (Bottom Nav):** Separar los módulos de la app en pestañas (Pacientes, Calendario, Biblioteca, Perfil) para mejor organización espacial.
- [ ] **1.2 Filtros de Pacientes:** Agregar "Chips" o botones de filtro rápido en el Dashboard para alternar entre pacientes de "Rehabilitación" y "Fitness".

### 🧠 Épica 2: Evolución del Modelo de Datos (Core)
*Prioridad: ALTA | Status: Pendiente (Requiere migración de base de datos)*
- [ ] **2.1 Flexibilidad de Días:** Reemplazar el esquema rígido de días de la semana (Lunes, Martes) por "Día 1, Día 2, etc.".
- [ ] **2.2 Tracking de Adherencia:** Implementar pop-up de seguimiento si el paciente salta un día en el orden establecido, requiriendo justificación.
- [ ] **2.3 Métricas Granulares por Ejercicio:** Mover las escalas (EVA, RPE, RIR) y parámetros (tiempo, peso, reps) de un modelo "por rutina" a un modelo "por ejercicio", soportando variables dinámicas (fuerza vs cardio).

### 🚀 Épica 3: Nuevos Módulos Mayores (Features Premium)
*Prioridad: MEDIA | Status: Pendiente*
- [ ] **3.1 Biblioteca de Rutinas (Templates):** Crear una colección guardada por el fisio para clonar y asignar rutinas base a múltiples pacientes con ligeras variaciones.
- [ ] **3.2 Calendario de Asignaciones (Vista Global):** Un dashboard diario para el fisio donde visualice todas las actividades y pacientes programados para la fecha actual.

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
- [ ] **Plantillas de Rutinas:** Guardar rutinas pre-armadas (ej. "Esguince de Tobillo Fase 1") para asignarlas con un clic a múltiples pacientes.
- [ ] **Corrección de Técnica (Video Asíncrono):** Permitir al paciente grabarse 10 segundos haciendo un ejercicio y subirlo para que el Fisio corrija su postura desde la app.
- [ ] **Catálogo de Videos Propios:** Permitir al Fisio enlazar sus propios videos de YouTube o subir videos cortos para sustituir las animaciones genéricas de los ejercicios.
- [ ] **Integración de Hardware (Wearables):** A largo plazo, conectar la app con Apple Health o Google Fit para medir actividad diaria pasiva del paciente.