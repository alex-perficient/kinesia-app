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
    // Obtenemos el ID del paciente que inició sesión
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Rehabilitación', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          NotificationBell(userId: currentUserId),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      // LA MAGIA ARQUITECTÓNICA: Leemos el perfil del paciente primero
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('patients').doc(currentUserId).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          // Extraemos el nombre real de Firestore
          String patientName = 'Paciente';
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            patientName = data['fullName'] ?? 'Paciente';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Saludo superior (¡Ahora personalizado con el nombre!)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Text(
                  '¡Hola $patientName!\nEs hora de tu recuperación.',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Buscamos TODAS las rutinas activas del paciente
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('routines')
                      .where('patientId', isEqualTo: currentUserId)
                      .where('isActive', isEqualTo: true)
                      // .limit(1) <--- ¡ELIMINADO!
                      .snapshots(),
                  builder: (context, routineSnapshot) {
                    if (routineSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (routineSnapshot.hasError) {
                      return const Center(child: Text('Error al cargar tu rutina.'));
                    }

                    final docs = routineSnapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No tienes ninguna rutina activa en este momento.\n\nTu fisioterapeuta te asignará una pronto.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    // AHORA USAMOS UN LISTVIEW PARA SOPORTAR MÚLTIPLES TARJETAS
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: [
                        const Text(
                          'Tus planes activos',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        // Generamos una tarjeta por cada rutina activa
                        ...docs.map((routineDoc) {
                          final routineData = routineDoc.data() as Map<String, dynamic>;
                          final routineId = routineDoc.id;
                          final String title = routineData['title'] ?? 'Mi Rutina';
                          final List exercises = routineData['exercises'] ?? [];

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16), // Espacio entre tarjetas
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Icon(Icons.fitness_center, size: 48, color: Colors.teal.shade300),
                                  const SizedBox(height: 16),
                                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  Text('${exercises.length} ejercicios asignados', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 24),
                                  
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PatientRoutineScreen(
                                              routineId: routineId, 
                                              patientName: patientName, 
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                      ),
                                      icon: const Icon(Icons.play_circle_fill),
                                      label: const Text('Comenzar Ejercicios', style: TextStyle(fontSize: 18)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }), // Fin del mapeo de tarjetas
                        
                        const SizedBox(height: 16),
                        
                        // El botón de la bitácora se queda al final de la lista
                        // El botón de la bitácora
                        OutlinedButton.icon(
                          onPressed: () {
                            // ¡LA NAVEGACIÓN REAL!
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PatientDailyLogScreen()),
                            );
                          },
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Registrar cómo me siento hoy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            foregroundColor: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 32), // Espacio extra al final para que no pegue con el borde
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}