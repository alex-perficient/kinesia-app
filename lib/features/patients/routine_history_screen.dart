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
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Historial: $routineTitle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha blanca asegurada
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workout_logs')
            .where('routineId', isEqualTo: routineId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el historial.'));
          }

          final logs = snapshot.data?.docs ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'El paciente aún no ha registrado\nentrenamientos para esta rutina.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
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
            padding: const EdgeInsets.all(20),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final data = logs[index].data() as Map<String, dynamic>;
              
              // Formateo básico de fecha
              final Timestamp timestamp = data['date'] ?? Timestamp.now();
              final DateTime date = timestamp.toDate();
              final String formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
              
              final String exerciseName = data['exerciseName'] ?? 'Ejercicio';
              final int rpe = data['rpe'] ?? 0;
              final int? eva = data['eva']; // Puede ser null si es perfil Fitness
              final List sets = data['sets'] ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: -0.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              formattedDate,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32, thickness: 1),
                      
                      // Escalas Clínicas (RPE y EVA)
                      Row(
                        children: [
                          Expanded(child: _buildMetricChip('RPE (Esfuerzo)', rpe.toString(), Colors.blueAccent)),
                          const SizedBox(width: 16),
                          if (eva != null) 
                            Expanded(child: _buildMetricChip('EVA (Dolor)', eva.toString(), eva > 4 ? Colors.redAccent : Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Detalle de las series (Reps y Pesos)
                      const Text('Detalle de Series:', style: TextStyle(fontWeight: FontWeight.bold, color: darkSlate)),
                      const SizedBox(height: 12),
                      ...List.generate(sets.length, (setIndex) {
                        final setInfo = sets[setIndex] as Map<String, dynamic>;
                        final int reps = setInfo['reps'] ?? 0;
                        final double weight = (setInfo['weight'] ?? 0).toDouble();
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Text('${setIndex + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                              ),
                              const SizedBox(width: 12),
                              Text('$reps reps  |  $weight kg/lb', style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 20)),
        ],
      ),
    );
  }
}