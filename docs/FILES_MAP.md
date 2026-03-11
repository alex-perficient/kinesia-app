# Documentación de Arquitectura y Pantallas - Kines.ia (Mon TI Labs)

## 📁 `lib/features/` (Las Pantallas y Funcionalidades Visuales)

### 📂 `auth/`
*(Aquí seguramente irán o están los archivos para el inicio de sesión y registro de usuarios).*

### 📂 `dashboard_physio/`
* **`dashboard_screen.dart`**: **La Casa del Fisio.** Es la pantalla principal que ve el fisioterapeuta al abrir la app. Normalmente aquí ve su lista de pacientes activos o su resumen del día.

### 📂 `notifications/`
* **`notification_bell.dart`**: **El Widget Visual.** Es el ícono de la campanita con el punto rojo dinámico.
* **`notifications_screen.dart`**: **El Buzón.** La pantalla donde cualquier usuario (fisio o paciente) entra a leer sus mensajes acumulados.

### 📂 `patient_view/` (El lado del Paciente)
* **`patient_home_screen.dart`**: **La Casa del Paciente.** Lo primero que ve el paciente al entrar. Aquí es donde pusimos su campanita exitosamente.
* **`patient_routine_screen.dart`**: **La Lista de Tareas.** Donde el paciente ve los ejercicios que le tocan hoy.
* **`exercise_tracking_screen.dart`**: **El Gimnasio.** La pantalla activa donde el paciente está marcando "Completado" en cada ejercicio o reportando si sintió dolor.

### 📂 `patients/` (Las herramientas del Fisio para administrar pacientes)
* **`create_patient_screen.dart`**: El formulario para dar de alta a un paciente nuevo en el sistema.
* **`patient_profile_screen.dart`**: **El Centro de Mando del Paciente.** Es el perfil individual que ve el fisio, desde donde puede decidir si ver su expediente o crearle rutinas.
* **`clinical_evaluation_screen.dart`**: **La Grabadora de IA.** Aquí es donde el fisio graba su nota de voz, Gemini extrae los datos y disparamos la notificación de "Nuevo Expediente".
* **`clinical_history_list_screen.dart`**: **El Expediente Médico.** La lista cronológica donde el fisio puede leer las notas pasadas y reproducir los audios de Firebase Storage.
* **`create_routine_screen.dart`**: **El Armador de Rutinas.** La pantalla donde el fisio selecciona qué ejercicios le tocan al paciente esta semana.
* **`physio_routine_detail_screen.dart`**: Pantalla para que el fisio revise los detalles exactos de una rutina específica que ya asignó.
* **`routine_history_screen.dart`**: El historial para ver qué rutinas se le han puesto al paciente en el pasado.

---

## 📁 `lib/services/` (Los Motores Invisibles)

* **`notification_service.dart`**: **El Cartero.** El motor lógico que se conecta a Firebase para enviar y leer notificaciones. No tiene interfaz gráfica, solo hace el trabajo duro.

---

## 📁 `lib/` (La Raíz del Proyecto)

* **`firebase_options.dart`**: El archivo autogenerado que conecta la app con el proyecto en la nube.
* **`main.dart`**: **El Interruptor Principal.** El archivo que arranca toda la aplicación al darle "Play".