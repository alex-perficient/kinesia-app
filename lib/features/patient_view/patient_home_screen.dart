import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinesia_app/features/notifications/notification_bell.dart';
import 'patient_routine_screen.dart';
import 'patient_daily_log_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      // 1. EL TRUCO MAGICO: Permite que el contenido suba hasta atrás de la barra de estado
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Barra transparente
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Íconos blancos para resaltar sobre la foto
        actions: [
          NotificationBell(userId: currentUserId),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('patients').doc(currentUserId).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          String patientName = 'Atleta';
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            // Tomamos solo el primer nombre para un saludo más personal y fuerte
            patientName = (data['fullName'] ?? 'Atleta').split(' ')[0]; 
          }

          // 2. STACK: Capas superpuestas (Foto al fondo, contenido al frente)
          return Stack(
            children: [
              // --- CAPA 1: EL HERO HEADER (Fondo) ---
              Container(
                height: MediaQuery.of(context).size.height * 0.45, // Ocupa el 45% de la pantalla
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    // Fotografía de alto rendimiento (atleta amarrándose las agujetas)
                    image: const NetworkImage('https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                    // Filtro oscuro para que el texto blanco sea súper legible
                    colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.darken),
                  ),
                ),
              ),

              // --- CAPA 2: EL CONTENIDO (Frente) ---
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SALUDO MOTIVACIONAL
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOLA, ${patientName.toUpperCase()}', 
                            style: const TextStyle(color: Colors.tealAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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

                    // LISTA DE RUTINAS FLOTANTE
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('routines')
                            .where('patientId', isEqualTo: currentUserId)
                            .where('isActive', isEqualTo: true)
                            .snapshots(),
                        builder: (context, routineSnapshot) {
                          if (routineSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.white));
                          }

                          final docs = routineSnapshot.data?.docs ?? [];

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            children: [
                              // Si no hay rutinas, mostramos una tarjeta de "Descanso"
                              if (docs.isEmpty)
                                Card(
                                  color: Colors.white.withValues(alpha: 0.95), // Ligeramente translúcida
                                  child: const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.bedtime_outlined, size: 48, color: Colors.teal),
                                        SizedBox(height: 16),
                                        Text('Día de Recuperación', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        Text('No tienes rutinas activas hoy. Aprovecha para descansar o espera las indicaciones de tu fisioterapeuta.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),

                              // Tarjetas de Rutinas
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
                                            onPressed: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => PatientRoutineScreen(routineId: routineDoc.id, patientName: patientName)));
                                            },
                                            child: const Text('Comenzar Entrenamiento'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 16),

                              // LA BITÁCORA DE BIENESTAR (Diseño Premium)
                              Card(
                                color: const Color(0xFF0F172A), // Slate Dark
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Bitácora Diaria', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      const Text('Ayuda a tu fisio a entender cómo responde tu cuerpo al tratamiento.', style: TextStyle(color: Colors.white70)),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientDailyLogScreen()));
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(color: Colors.white24, width: 2),
                                          ),
                                          icon: const Icon(Icons.mood),
                                          label: const Text('Registrar Bienestar'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40), // Espacio final
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