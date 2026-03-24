import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinesia_app/features/notifications/notification_bell.dart';
import 'patient_routine_screen.dart';
import 'patient_daily_log_screen.dart';
import 'patient_diet_screen.dart';
import '../../features/dashboard_physio/routine_library_screen.dart';
import '../../services/exercise_seeder.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          NotificationBell(userId: currentUserId),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.grey),
            onPressed: () async {
              await ExerciseSeeder.seedDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Ejercicios inyectados a Firebase! 🚀'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          String patientName = 'Atleta';
          int streakCount = 0;
          String patientType = 'Clínica';

          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            patientName = (data['fullName'] ?? 'Atleta').split(' ')[0];
            streakCount = data['streakCount'] ?? 0;
            patientType = data['patientType'] ?? 'Clínica';
          }

          final bool isB2C = patientType == 'B2C';

          return Stack(
            children: [
              // FONDO HERO INMERSIVO (INTACTO)
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/fondo_atleta.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.6),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),

              // CONTENIDO PRINCIPAL FLOTANTE
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CABECERA (HOLA, NOMBRE) (INTACTO)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'HOLA, ${patientName.toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orangeAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      '🔥',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$streakCount',
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isB2C
                                ? 'Supera tus\nlímites.'
                                : 'Tu momento\nes ahora.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // LISTA DE TARJETAS
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('routines')
                            .where('patientId', isEqualTo: currentUserId)
                            .where('isActive', isEqualTo: true)
                            .snapshots(),
                        builder: (context, routineSnapshot) {
                          if (routineSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          }
                          final docs = routineSnapshot.data?.docs ?? [];

                          return ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            children: [
                              // ---- LA MAGIA DEL B2C / B2B EMPIEZA AQUÍ (INTACTO) ----
                              if (docs.isEmpty && !isB2C)
                                Card(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.bedtime_outlined,
                                          size: 48,
                                          color: Colors.teal,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Día de Recuperación',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'No tienes rutinas activas hoy. Aprovecha para descansar o espera las indicaciones de tu especialista.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (docs.isEmpty && isB2C)
                                Card(
                                  color: darkSlate,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 8,
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.bolt,
                                            size: 48,
                                            color: Colors.amber,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          '¿Qué entrenamos hoy?',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Explora cientos de ejercicios o pide a nuestra IA que arme una rutina perfecta para tus objetivos de hoy.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 55,
                                          child: ElevatedButton.icon(
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const RoutineLibraryScreen(),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.auto_awesome,
                                            ),
                                            label: const Text(
                                              'Explorar Biblioteca Kines.ia',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.tealAccent.shade400,
                                              foregroundColor: darkSlate,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // SI TIENE RUTINAS (INTACTO)
                              ...docs.map((routineDoc) {
                                final routineData =
                                    routineDoc.data() as Map<String, dynamic>;
                                final String title =
                                    routineData['title'] ?? 'Mi Rutina';
                                final List exercises =
                                    routineData['exercises'] ?? [];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Icon(
                                              Icons.local_fire_department,
                                              color: Colors.deepOrange,
                                            ),
                                            Text(
                                              '${exercises.length} ejercicios',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 55,
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PatientRoutineScreen(
                                                      routineId: routineDoc.id,
                                                      patientName: patientName,
                                                    ),
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: darkSlate,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: const Text(
                                              'Comenzar Entrenamiento',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 16),

                              // 👇 LA MAGIA INYECTADA: TARJETA DE NUTRICIÓN DINÁMICA
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('nutrition_plans')
                                    .where(
                                      'patientId',
                                      isEqualTo: currentUserId,
                                    )
                                    .where('isActive', isEqualTo: true)
                                    .snapshots(),
                                builder: (context, dietSnapshot) {
                                  String dietDescription = isB2C
                                      ? 'Registra tus comidas y mantén tus macros bajo control.'
                                      : 'Revisa el plan nutricional que tu especialista diseñó para ti.';

                                  // Si encontramos un plan activo, actualizamos el texto dinámicamente
                                  if (dietSnapshot.hasData &&
                                      dietSnapshot.data!.docs.isNotEmpty) {
                                    final dietData =
                                        dietSnapshot.data!.docs.first.data()
                                            as Map<String, dynamic>;
                                    final objective =
                                        dietData['objective'] ??
                                        'Mantenimiento';
                                    final calories = dietData['calories'] ?? 0;
                                    dietDescription =
                                        'Plan Activo: $objective • $calories kcal diarias.';
                                  }

                                  return Card(
                                    color: Colors.green.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      side: BorderSide(
                                        color: Colors.green.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.restaurant_menu,
                                                color: Colors.green,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Nutrición',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            dietDescription,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ), // Texto Dinámico
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 55,
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PatientDietScreen(
                                                        patientId:
                                                            currentUserId,
                                                      ),
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: const Text(
                                                'Ver mi Dieta',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // TARJETA: BITÁCORA DIARIA (INTACTO)
                              Card(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Bitácora Diaria',
                                        style: TextStyle(
                                          color: darkSlate,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isB2C
                                            ? 'Lleva un registro de tu progreso, dolor y descanso.'
                                            : 'Ayuda a tu fisio a entender cómo responde tu cuerpo a las terapias.',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 55,
                                        child: OutlinedButton.icon(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const PatientDailyLogScreen(),
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: darkSlate,
                                            side: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          icon: const Icon(Icons.mood),
                                          label: const Text(
                                            'Registrar Bienestar',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
