import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_routine_screen.dart'; // La pantalla de los videos de YouTube

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
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Saludo superior
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Text(
              '¡Hola!\nEs hora de tu recuperación.',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          // Buscamos la rutina activa del paciente
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('routines')
                  .where('patientId', isEqualTo: currentUserId)
                  .where('isActive', isEqualTo: true)
                  .limit(1) // Solo necesitamos la rutina activa actual
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar tu rutina.'));
                }

                final docs = snapshot.data?.docs ?? [];

                // Si el fisio aún no le asigna una rutina o la desactivó
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

                // Si encontramos la rutina activa, extraemos los datos
                final routineDoc = docs.first;
                final routineData = routineDoc.data() as Map<String, dynamic>;
                final routineId = routineDoc.id;
                final String title = routineData['title'] ?? 'Mi Rutina';
                final List exercises = routineData['exercises'] ?? [];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Tu plan para hoy',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tarjeta de la Rutina
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(Icons.fitness_center, size: 48, color: Colors.teal.shade300),
                              const SizedBox(height: 16),
                              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('${exercises.length} ejercicios asignados', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 24),
                              
                              // Botón gigante para ir a los videos
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PatientRoutineScreen(routineId: routineId),
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
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Placeholder para la bitácora (que haremos cuando envíes el PDF)
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Próximamente: Bitácora diaria del fisio')),
                          );
                        },
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Registrar cómo me siento hoy'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          foregroundColor: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}