import 'package:flutter/material.dart';
import 'routine_history_screen.dart';

class PhysioRoutineDetailScreen extends StatelessWidget {
  final Map<String, dynamic> routineData;
  final String routineId;

  const PhysioRoutineDetailScreen({
    super.key,
    required this.routineData,
    required this.routineId,
  });

  @override
  Widget build(BuildContext context) {
    final String title = routineData['title'] ?? 'Detalle de Rutina';
    final List exercises = routineData['exercises'] ?? [];
    final bool isActive = routineData['isActive'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Ver Historial de Registros',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoutineHistoryScreen(
                    routineId: routineId,
                    routineTitle: title,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ejercicios Asignados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(isActive ? 'Activa' : 'Inactiva'),
                  backgroundColor: isActive ? Colors.green.shade100 : Colors.grey.shade300,
                  labelStyle: TextStyle(color: isActive ? Colors.green.shade800 : Colors.grey.shade800),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index] as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade50,
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.teal)),
                      ),
                      title: Text(exercise['title'] ?? 'Ejercicio', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${exercise['sets']} Series x ${exercise['reps']} Repeticiones\nURL: ${exercise['youtubeUrl']}'),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}