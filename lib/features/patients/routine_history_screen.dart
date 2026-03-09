import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoutineHistoryScreen extends StatelessWidget {
  final String routineId;
  final String routineTitle;

  const RoutineHistoryScreen({
    super.key,
    required this.routineId,
    required this.routineTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial: $routineTitle'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workout_logs')
            .where('routineId', isEqualTo: routineId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el historial.'));
          }

          final logs = snapshot.data?.docs ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'El paciente aún no ha registrado entrenamientos para esta rutina.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // Ordenamos localmente por fecha (del más reciente al más antiguo)
          logs.sort((a, b) {
            final Timestamp tA = (a.data() as Map)['date'] ?? Timestamp.now();
            final Timestamp tB = (b.data() as Map)['date'] ?? Timestamp.now();
            return tB.compareTo(tA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final data = logs[index].data() as Map<String, dynamic>;
              
              // Formateo básico de fecha
              final Timestamp timestamp = data['date'] ?? Timestamp.now();
              final DateTime date = timestamp.toDate();
              final String formattedDate = '${date.day}/${date.month}/${date.year} a las ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
              
              final String exerciseName = data['exerciseName'] ?? 'Ejercicio';
              final int rpe = data['rpe'] ?? 0;
              final int? eva = data['eva']; // Puede ser null si es perfil Fitness
              final List sets = data['sets'] ?? [];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado: Fecha y Nombre del Ejercicio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              exerciseName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Divider(),
                      
                      // Escalas Clínicas (RPE y EVA)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricChip('RPE (Esfuerzo)', rpe.toString(), Colors.blue),
                          if (eva != null) 
                            _buildMetricChip('EVA (Dolor)', eva.toString(), eva > 4 ? Colors.red : Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Detalle de las series (Reps y Pesos)
                      const Text('Detalle de Series:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...List.generate(sets.length, (setIndex) {
                        final setInfo = sets[setIndex] as Map<String, dynamic>;
                        final int reps = setInfo['reps'] ?? 0;
                        final double weight = (setInfo['weight'] ?? 0).toDouble();
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                                child: Text('${setIndex + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Text('$reps reps  |  $weight kg/lb', style: const TextStyle(fontSize: 15)),
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
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ),
      ],
    );
  }
}