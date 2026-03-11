# Kines.ia - Documento de Requerimientos Técnicos

## 1. Información General
* **Proyecto:** Kines.ia (Aplicación SaaS de Rehabilitación Física)
* **Ecosistema:** Mon TI Labs
* **Arquitecto/Lead Developer:** Alejandro Pedrero Montiel
* **Stack Tecnológico:**
  * **Frontend:** Flutter (Dart) - Android, iOS, Web
  * **Backend/BaaS:** Firebase (Auth, Firestore NoSQL, Cloud Storage)
  * **Inteligencia Artificial:** Google Gemini (Modelo: gemini-3-flash-preview)
* **Modelo de Negocio:** Freemium (Cuota base mensual por volumen de uso de IA).

---

## 2. Descripción del Sistema (Overview)
Kines.ia es una plataforma bidireccional diseñada para modernizar la atención en fisioterapia. Elimina las rutinas estáticas en PDF permitiendo a los fisioterapeutas (Fisios) gestionar expedientes clínicos mediante IA multimodal (voz a texto y extracción de datos) y asignar rutinas interactivas. Los pacientes usan la app para reportar su progreso (series, peso, esfuerzo y dolor), generando un bucle de retroalimentación en tiempo real.

---

## 3. Actores del Sistema
1. **Fisioterapeuta (Admin):**
   * Perfil profesional encargado de la atención clínica.
   * Capacidades: Dar de alta pacientes, grabar notas de evolución, usar IA para estructurar el expediente, asignar rutinas personalizadas y monitorear adherencia.
2. **Paciente (Usuario Final):**
   * Perfil enfocado en la ejecución y reporte.
   * Tipos de perfil: *Clinical* (Reporta dolor EVA) y *Fitness* (Reporta solo esfuerzo RPE).
   * Capacidades: Visualizar rutinas activas, registrar series/repeticiones completadas, y reportar síntomas post-entrenamiento.

---

## 4. Funcionalidades Core (Estado Actual)
* **Autenticación:** Login y registro independiente para ambos actores vía Firebase Auth.
* **Motor Multimodal IA:** Captura de audio (.m4a) subido a Firebase Storage, procesado por Gemini para devolver transcripción literal, diagnóstico, objetivos y zonas de dolor en formato JSON.
* **Gestor de Expedientes:** Visualización cronológica de notas clínicas con reproductor nativo de audio alojado en la nube.
* **Sistema de Rutinas:** Creación dinámica de bloques de ejercicios con repeticiones, series y peso.
* **Libreta de Monitoreo:** Captura de datos post-entrenamiento (RPE y EVA) almacenados en una colección maestra `workout_logs`.
* **Motor de Notificaciones (In-App):** Sistema de comunicación en tiempo real tipo "buzón" para alertar sobre nuevas rutinas y entrenamientos completados.

---

## 5. Arquitectura de Base de Datos (Firestore)
* `physiotherapists`: Colección base de profesionales.
* `patients`: Colección de usuarios finales, vinculados a su Fisio a través del campo `physioId`.
* `clinical_histories`: Documentos de evolución médica generados manual o vía IA.
* `routines`: Bloques de ejercicios asignados.
* `workout_logs`: Bitácora inmutable de entrenamientos realizados.
* `notifications`: Buzón centralizado para el motor de alertas.

---

## 6. Constantes, Validaciones y Reglas de Negocio (Próximas implementaciones)
* **Límites de Storage:** Los audios clínicos deben grabarse en formato AAC ligero (`AudioEncoder.aacLc`) para minimizar costos de almacenamiento.
* **Modelo Freemium (Pendiente):**
  * Limite de extracciones IA gratuitas mensuales por Fisio.
  * Costo por cuota excedida: $100 MXN / mes.
  * Desactivación de funciones (Micrófono bloqueado) en caso de impago.
* **Deuda Técnica Funcional (Pendiente):**
  * Soft Delete (Archivado) de pacientes inactivos.
  * CRUD completo (Edición y Eliminación) de rutinas activas y notas de evolución.
* **Notificaciones:** Actualmente operan In-App. Migración a Push Notifications (FCM) proyectada para fase de madurez financiera.