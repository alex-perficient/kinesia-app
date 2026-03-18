# Notas para no olvidar, y cosas que revisar.

## 🛠️ (Deuda Técnica)
1.- Cuando el usuario abre su pantalla, y tiene mas de 1 rutina asignada, en la app, solo puede ver 1 rutina.
2.- Hay que hacer algo con la calendarización de las actividades, algo así como ver en record cuantas semanas le faltan para terminar una rutina o cuantos días lleva
asi como su racha y agregar fechas visibles en la tarjeta de rutinas.
3.- Preguntar al Fisio sobre las notas del paciente. Donde quiere que las capture, si por día o por otro rango de tiempo. O si quiere dejarlos programados y que cuando los borre, automaticamente aparezca uno nuevo. O que idea le convence mas.
4.- Cambiar pantalla del que tiene versión PREMIUM, hacerle notar que usa una versión PREMIUM.
5.- Quiza cambiar el color de la pantalla del paciente o algo que lo diferencíe del fisio.
6.- En las notificaciones agregar el nombre del paciente.
7.- Al hacer clic sobre la notificacion, que lo lleve a la pantalla del paciente y esa rutina o algun dashboard de avances.
8.- Algunos ejercicios puede que sean REPS y otros puede que sean por minutos, como caminar o hacer bicicleta o ciertos ejercicios.
9.- Cuando un ejercicio sobre pase el EVA u otro parametro, enviar notificación al fisio.
10.- Saludar al paciente por su nombre "Hola NOMBRE_DE_PACIENTE", ¡Es hora de tu rutina! o de hacer ejercicio."
11.- Notificar al fisio cuando la rutina de un paciente este por terminar (3 dias antes o algo similar).
12.- Un dashboard general donde el fisio vea a todos los pacientes en una sola pantalla, con los avances y fechas, muy general, y estadisticas.
13.- Agregar fecha en la que el usuario esta realizando su rutina y quiza validar que no pueda hacer las mismas series en el mismo día o recapturarlas. Pero debo checarlo con el fisio.


✅ Fase 1 Completada: El ADN y las Pantallas Principales
Estas pantallas ya tienen el diseño Premium (SaaS para Fisios / Alto Rendimiento para Pacientes):

✅ main.dart (El Tema Global con los colores base).
✅ login_screen.dart & sign_up_screen.dart (Fondos inmersivos y Glassmorphism).
✅ dashboard_screen.dart (Cabecera oscura Dark Slate, KPIs y búsqueda).
✅ patient_home_screen.dart (Hero Header motivacional B2C).
✅ patient_daily_log_screen.dart (Check-in de bienestar con emojis dinámicos).
✅ exercise_tracking_screen.dart (Modo Oscuro, números gigantes y confeti).


⏳ Fase 2: El Plan de Pulido (Lo que nos falta)
Para que toda la app se sienta como un ecosistema unificado, dividiremos las pantallas restantes en 3 bloques de alto impacto. No haremos cambios estructurales masivos, solo les inyectaremos el ADN visual que ya definimos:

1. El Cascarón del Fisio (Prioridad Alta)

⏳ notification_bell.dart: Pintar la campanita de blanco para que no se pierda en el fondo oscuro.

⏳ main_physio_screen.dart: Es probable que la barra de navegación inferior (BottomNav) siga siendo gris o básica. La haremos elegante y moderna.

⏳ routine_library_screen.dart: Ya arreglamos el estado vacío, pero necesitamos que la lista de plantillas (cuando ya existen) parezca una verdadera biblioteca Premium y no una lista genérica.

2. El Expediente Clínico (Para justificar el cobro)

⏳ patient_profile_screen.dart: Es el perfil del paciente visto por el fisio. Lo transformaremos en un "Expediente Digital" estilo Apple Health, con tarjetas limpias para ver su progreso y adherencia.

⏳ physio_calendar_screen.dart: Darle el toque Dark Slate a la cabecera del calendario para que haga juego con el Dashboard.

3. El Lado del Paciente (Detalles finales)

⏳ patient_routine_screen.dart: La pantalla donde el paciente ve la lista de videos antes de entrenar. Le daremos un toque más deportivo para que coincida con su pantalla de inicio.