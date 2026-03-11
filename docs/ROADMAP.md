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
- [x] Editar/Eliminar Rutinas Asignadas (PENDIENTE REVISAR SI SE REQUIERE EDITAR RUTINAS)
- [ ] Eliminar Notas Clínicas Duplicadas

## 🚧 Fase 6.2: Modelo de Negocio
- [ ] Reglas de control de uso de IA (Contador en Firebase)
- [ ] Bloqueos y pantallas Freemium vs Premium

## 🎨 Fase 7: UI/UX y Retención
- [ ] Estados vacíos (Empty States) ilustrados
- [ ] Shimmer/Skeleton Loaders
- [ ] Gamificación básica (Rachas de días para el paciente)

## 🛡️ Fase de Seguridad y Privacidad de Datos
- [ ] **Reglas de Firebase (Firestore & Storage):** Cerrar el acceso público. Configurar reglas para que un paciente solo pueda leer su propio documento y un fisio solo pueda leer/escribir sobre los pacientes que le pertenecen (`physioId == auth.uid`).
- [ ] **Sanitización de Datos:** Validar desde el código y desde la base de datos que los campos de texto no superen ciertos límites (prevención de inyección masiva de datos).
- [ ] **Cumplimiento Normativo (Expediente Clínico):** Integrar una pantalla de "Aviso de Privacidad / Consentimiento" donde el paciente acepte que sus datos y audios serán procesados por IA.
- [ ] **Bloqueo de Sesiones:** Asegurar el cierre de sesión automático tras inactividad prolongada en el dispositivo del fisio por tratarse de datos sensibles.

## 🚀 Fase 8: Producción
- [ ] Generación de APK/App Bundle final
- [ ] Despliegue en Firebase App Distribution para testers

---

## 🔮 Backlog / Lluvia de Ideas (Futuros Features a evaluar)
*Estas son características de alto impacto que se desarrollarán a mediano/largo plazo para escalar Kines.ia.*

- [ ] **Analítica con IA (Reportes de Evolución):** Prompt para que Gemini lea el historial de un paciente de los últimos 2 meses y redacte un resumen médico de evolución (Ideal para entregar a médicos traumatólogos).
- [ ] **Plantillas de Rutinas:** Guardar rutinas pre-armadas (ej. "Esguince de Tobillo Fase 1") para asignarlas con un clic a múltiples pacientes.
- [ ] **Corrección de Técnica (Video Asíncrono):** Permitir al paciente grabarse 10 segundos haciendo un ejercicio y subirlo para que el Fisio corrija su postura desde la app.
- [ ] **Catálogo de Videos Propios:** Permitir al Fisio enlazar sus propios videos de YouTube o subir videos cortos para sustituir las animaciones genéricas de los ejercicios.
- [ ] **Integración de Hardware (Wearables):** A largo plazo, conectar la app con Apple Health o Google Fit para medir actividad diaria pasiva del paciente.