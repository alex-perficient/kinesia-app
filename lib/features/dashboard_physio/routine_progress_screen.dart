import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routine_charts_screen.dart';

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
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Bitácora de Progreso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha blanca asegurada
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart_rounded),
            tooltip: 'Ver Gráficas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoutineChartsScreen(
                    routineId: routineId,
                    patientName: patientName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabecera tipo "Reporte Ejecutivo"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.teal.shade400),
                    const SizedBox(width: 8),
                    Text('Paciente: $patientName', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(routineTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: -0.5)),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: const Text('Registros de Entrenamiento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
          ),

          // 2. Lista de ejercicios completados en tiempo real
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('workout_logs')
                  .where('routineId', isEqualTo: routineId)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }

                if (snapshot.hasError) {
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.query_stats, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'El paciente aún no registra ejercicios\npara este plan de rehabilitación.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    final exerciseName = log['exerciseName'] ?? 'Ejercicio';
                    
                    final Timestamp? timestamp = log['date'] as Timestamp?;
                    String dateStr = 'Fecha desconocida';
                    if (timestamp != null) {
                      final date = timestamp.toDate();
                      dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                    }

                    final int? rpe = log['rpe'];
                    final int? eva = log['eva'];
                    final List sets = log['sets'] ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título y Fecha
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(exerciseName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate))),
                                const Icon(Icons.check_circle, color: Colors.teal),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold)),
                            const Divider(height: 32, thickness: 1),
                            
                            // CHIPS DE GRANULARIDAD (Dolor y Esfuerzo)
                            if (rpe != null || eva != null) ...[
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (rpe != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text('Esfuerzo (RPE): $rpe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                                    ),
                                  if (eva != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text('Dolor (EVA): $eva', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // DETALLE DE SERIES Y PESOS
                            const Text('Detalle de Series:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkSlate)),
                            const SizedBox(height: 12),
                            ...List.generate(sets.length, (setIndex) {
                              final setData = sets[setIndex] as Map<String, dynamic>;
                              final reps = setData['reps'] ?? 0;
                              final weight = setData['weight'];

                              String setDetail = '$reps reps';
                              if (weight != null && weight > 0) {
                                setDetail += '  •  $weight kg/lb';
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                      child: Text('S${setIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(setDetail, style: TextStyle(color: Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.w600)),
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