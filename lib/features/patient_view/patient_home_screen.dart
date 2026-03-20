import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinesia_app/features/notifications/notification_bell.dart';
import 'patient_routine_screen.dart';
import 'patient_daily_log_screen.dart';
// ¡IMPORTAMOS LA NUEVA PANTALLA DE DIETA!
import 'patient_diet_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          NotificationBell(userId: currentUserId),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').doc(currentUserId).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          String patientName = 'Atleta';
          int streakCount = 0;

          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            patientName = (data['fullName'] ?? 'Atleta').split(' ')[0]; 
            streakCount = data['streakCount'] ?? 0;
          }

          return Stack(
            children: [
              // FONDO HERO
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const NetworkImage('https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.darken),
                  ),
                ),
              ),

              // FRENTE
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'HOLA, ${patientName.toUpperCase()}', 
                                style: const TextStyle(color: Colors.tealAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text('$streakCount', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tu momento\nes ahora.',
                            style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('routines')
                            .where('patientId', isEqualTo: currentUserId)
                            .where('isActive', isEqualTo: true)
                            .snapshots(),
                        builder: (context, routineSnapshot) {
                          if (routineSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));

                          final docs = routineSnapshot.data?.docs ?? [];

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            children: [
                              if (docs.isEmpty)
                                Card(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  child: const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.bedtime_outlined, size: 48, color: Colors.teal),
                                        SizedBox(height: 16),
                                        Text('Día de Recuperación', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        Text('No tienes rutinas activas hoy. Aprovecha para descansar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),

                              ...docs.map((routineDoc) {
                                final routineData = routineDoc.data() as Map<String, dynamic>;
                                final String title = routineData['title'] ?? 'Mi Rutina';
                                final List exercises = routineData['exercises'] ?? [];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                                            Text('${exercises.length} ejercicios', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PatientRoutineScreen(routineId: routineDoc.id, patientName: patientName))),
                                            child: const Text('Comenzar Entrenamiento'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 16),

                              // NUEVA TARJETA: PLAN NUTRICIONAL
                              Card(
                                color: Colors.green.shade50,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.green.shade100)),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.restaurant_menu, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Nutrición', style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Combustible para tu recuperación y rendimiento. Revisa tus macros y comidas.', style: TextStyle(color: Colors.black87)),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PatientDietScreen(patientId: currentUserId))),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                                          child: const Text('Ver mi Dieta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // TARJETA DE BITÁCORA DIARIA
                              Card(
                                color: const Color(0xFF0F172A), 
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Bitácora Diaria', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      const Text('Ayuda a tu fisio a entender cómo responde tu cuerpo.', style: TextStyle(color: Colors.white70)),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientDailyLogScreen())),
                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24, width: 2)),
                                          icon: const Icon(Icons.mood),
                                          label: const Text('Registrar Bienestar'),
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