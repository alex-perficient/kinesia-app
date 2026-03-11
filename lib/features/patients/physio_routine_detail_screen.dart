import 'package:flutter/material.dart';
import 'routine_history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhysioRoutineDetailScreen extends StatelessWidget {
  final Map<String, dynamic> routineData;
  final String routineId;

  const PhysioRoutineDetailScreen({
    super.key,
    required this.routineData,
    required this.routineId,
  });

  Future<void> _deleteRoutine(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta rutina?'),
        content: const Text(
          'Esta acción quitará la rutina del celular del paciente inmediatamente. Los registros de los días que ya la completó seguirán a salvo en su bitácora histórica.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Asumiendo que recibes el ID de la rutina en tu pantalla como widget.routineId
        await FirebaseFirestore.instance
            .collection('routines')
            .doc(routineId) 
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rutina eliminada correctamente.')),
          );
          // Regresamos a la pantalla anterior (El historial del paciente)
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  

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
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade300,
            tooltip: 'Eliminar Rutina',
            onPressed: () => _deleteRoutine(context),
          ),
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