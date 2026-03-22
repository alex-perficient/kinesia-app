---
config:
  layout: elk
---
graph TD
  classDef auth fill:#1e293b,stroke:#0f172a,stroke-width:2px,color:#fff;
  classDef physio fill:#f0fdf4,stroke:#22c55e,stroke-width:2px,color:#0f172a;
  classDef patient fill:#f0f9ff,stroke:#0ea5e9,stroke-width:2px,color:#0f172a;
  classDef action fill:#fffbeb,stroke:#f59e0b,stroke-width:2px,color:#0f172a;
  Main[main.dart<br>Punto de Arranque] --> AuthGate{auth_gate.dart<br>El Guardia Fantasma}
  
  AuthGate -- "No hay sesión" --> Login[login_screen.dart]
  Login -. "¿Es nuevo?" .-> SignUp[sign_up_screen.dart]
  Login -- "Inicia Sesión" --> AuthGate
  SignUp -- "Se Registra" --> AuthGate

  class Main,AuthGate,Login,SignUp auth;
  AuthGate -- "Rol: Fisio" --> MainPhysio[main_physio_screen.dart<br>Nav Bar Inferior]
  
  MainPhysio --> DashPhysio[dashboard_screen.dart<br>Lista de Pacientes]
  MainPhysio --> CalPhysio[physio_calendar_screen.dart]
  MainPhysio --> LibPhysio[routine_library_screen.dart]
  MainPhysio --> ProfPhysio[physio_profile_screen.dart<br>Código QR]

  DashPhysio -- "Toca un Paciente" --> PatientProfile[patient_profile_screen.dart<br>Expediente 3 Pestañas]
  PatientProfile -- "Botón + Crear Rutina" --> BottomMenu((Menú Inferior))
  
  BottomMenu -- "1. Plantilla" --> SelectTemplate[select_template_screen.dart]
  BottomMenu -- "2. Desde Banco" --> RoutineBuilder[routine_builder_screen.dart<br>El Constructor]
  BottomMenu -- "3. Manual" --> CreateManual[create_routine_screen.dart]

  RoutineBuilder -- "+ Agregar Ejercicio" --> ExerciseBank[physio_exercise_bank_screen.dart<br>Catálogo Global]
  PatientProfile -. "Pestaña Nutrición" .-> CreateDiet[create_diet_screen.dart]
  
  class MainPhysio,DashPhysio,CalPhysio,LibPhysio,ProfPhysio,PatientProfile,SelectTemplate,RoutineBuilder,CreateManual,ExerciseBank,CreateDiet physio;
  class BottomMenu action;
  AuthGate -- "Rol: Paciente" --> MainPatient[main_patient_screen.dart<br>Nav Bar Inferior]
  
  MainPatient --> HomePatient[patient_home_screen.dart<br>Inicio]
  MainPatient --> RunTracker[patient_run_tracker_screen.dart<br>Módulo GPS]
  MainPatient --> DietPatient[patient_diet_screen.dart<br>Ver su dieta]
  
  HomePatient -- "Toca una rutina" --> RoutineDetail[patient_routine_screen.dart<br>Lista de Ejercicios]
  RoutineDetail -- "Play" --> Tracking[exercise_tracking_screen.dart<br>Ejecución]

  class MainPatient,HomePatient,RunTracker,DietPatient,RoutineDetail,Tracking patient;