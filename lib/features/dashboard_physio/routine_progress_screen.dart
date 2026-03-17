import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoutineProgressScreen extends StatelessWidget {
  final String routineId;
  final String routineTitle;
  final String patientName;

  const RoutineProgressScreen({
    super.key,
    required this.routineId,
    required this.routineTitle,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitácora de Progreso'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabecera con los datos del paciente
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.teal.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paciente: $patientName', style: const TextStyle(fontSize: 16, color: Colors.teal)),
                const SizedBox(height: 4),
                Text(routineTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
          ),
          
          // 2. Lista de ejercicios completados en tiempo real
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('workout_logs')
                  .where('routineId', isEqualTo: routineId)
                  .orderBy('date', descending: true) // Los más recientes primero
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }

                if (snapshot.hasError) {
                  // Como usamos where + orderBy, Firebase nos pedirá crear un índice.
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error al cargar. Revisa la consola para crear el índice de Firebase: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final logs = snapshot.data?.docs ?? [];

                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'El paciente aún no registra ejercicios\npara este plan de rehabilitación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    final exerciseName = log['exerciseName'] ?? 'Ejercicio';
                    
                    // Convertimos el Timestamp de Firebase a una fecha legible
                    final Timestamp? timestamp = log['date'] as Timestamp?;
                    String dateStr = 'Fecha desconocida';
                    if (timestamp != null) {
                      final date = timestamp.toDate();
                      dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                    }

                    // Extraemos las métricas granulares
                    final int? rpe = log['rpe'];
                    final int? eva = log['eva'];
                    final List sets = log['sets'] ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título y Fecha
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(exerciseName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                const Icon(Icons.check_circle, color: Colors.green),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const Divider(height: 24),
                            
                            // CHIPS DE GRANULARIDAD (Dolor y Esfuerzo)
                            if (rpe != null || eva != null) ...[
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (rpe != null)
                                    Chip(
                                      label: Text('Esfuerzo (RPE): $rpe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                      backgroundColor: Colors.blue.shade50,
                                      side: BorderSide(color: Colors.blue.shade200),
                                    ),
                                  if (eva != null)
                                    Chip(
                                      label: Text('Dolor (EVA): $eva', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                                      backgroundColor: Colors.red.shade50,
                                      side: BorderSide(color: Colors.red.shade200),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // DETALLE DE SERIES Y PESOS
                            const Text('Detalle de Series:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            ...List.generate(sets.length, (setIndex) {
                              final setData = sets[setIndex] as Map<String, dynamic>;
                              final reps = setData['reps'] ?? 0;
                              final weight = setData['weight'];

                              // Construimos el texto dinámicamente si hay peso o no
                              String setDetail = 'Serie ${setIndex + 1}: $reps reps';
                              if (weight != null && weight > 0) {
                                setDetail += ' @ $weight kg/lb';
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.fitness_center, size: 16, color: Colors.teal.shade300),
                                    const SizedBox(width: 8),
                                    Text(setDetail, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}