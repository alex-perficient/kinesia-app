import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dashboard_physio/routine_progress_screen.dart';
import '../../services/notification_service.dart'; // Ajusta la ruta a tu estructura

class PhysioRoutineDetailScreen extends StatelessWidget {
  final Map<String, dynamic> routineData;
  final String routineId;

  const PhysioRoutineDetailScreen({
    super.key,
    required this.routineData,
    required this.routineId,
  });

  // Función original intacta para eliminar toda la rutina
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
        await FirebaseFirestore.instance.collection('routines').doc(routineId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rutina eliminada correctamente.')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  // NUEVO: Función para editar las series o repeticiones de un ejercicio
  Future<void> _editExercise(BuildContext context, List currentExercises, int index) async {
    final exercise = currentExercises[index];
    final TextEditingController setsCtrl = TextEditingController(text: exercise['sets'].toString());
    final TextEditingController repsCtrl = TextEditingController(text: exercise['reps'].toString());

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajustar Ejercicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ejercicio: ${exercise['title'] ?? exercise['name']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 16),
            TextField(
              controller: setsCtrl,
              decoration: const InputDecoration(labelText: 'Series', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repsCtrl,
              decoration: const InputDecoration(labelText: 'Repeticiones / Tiempo', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar Cambios'),
          ),
        ],
      ),
    );

    if (save == true) {
      // Modificamos solo ese ejercicio en la lista local
      List updatedExercises = List.from(currentExercises);
      updatedExercises[index]['sets'] = setsCtrl.text.trim();
      updatedExercises[index]['reps'] = repsCtrl.text.trim();

      // Guardamos la nueva lista en Firebase
      await FirebaseFirestore.instance.collection('routines').doc(routineId).update({
        'exercises': updatedExercises,
      });

      // ¡NUEVO: Notificamos al paciente de la edición!
      final String patientId = routineData['patientId'] ?? '';
      if (patientId.isNotEmpty) {
        await NotificationService.sendNotification(
          receiverId: patientId,
          title: 'Rutina actualizada 🔄',
          body: 'Tu fisio ha ajustado las series/reps de: ${exercise['title'] ?? exercise['name']}',
        );
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio actualizado 👌')));
      }
    }
  }

  // NUEVO: Función para eliminar un solo ejercicio de la rutina
  Future<void> _removeExercise(BuildContext context, List currentExercises, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar Ejercicio'),
        content: const Text('¿Seguro que quieres quitar este ejercicio de la rutina del paciente? Esto no afectará la plantilla original de la biblioteca.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red), 
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Extraemos el ejercicio de la lista local
      List updatedExercises = List.from(currentExercises);
      updatedExercises.removeAt(index);

      // Guardamos la nueva lista en Firebase sin ese ejercicio
      await FirebaseFirestore.instance.collection('routines').doc(routineId).update({
        'exercises': updatedExercises,
      });

      // ¡NUEVO: Notificamos al paciente de la eliminación!
      final String exerciseName = currentExercises[index]['title'] ?? currentExercises[index]['name'] ?? 'un ejercicio';
      final String patientId = routineData['patientId'] ?? '';
      
      if (patientId.isNotEmpty) {
        await NotificationService.sendNotification(
          receiverId: patientId,
          title: 'Rutina aligerada 📉',
          body: 'Tu fisio ha removido: $exerciseName de tu plan.',
        );
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio removido 🗑️')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = routineData['title'] ?? 'Detalle de Rutina';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade300,
            tooltip: 'Eliminar Rutina Completa',
            onPressed: () => _deleteRoutine(context),
          ),
        ],
      ),
      
      // AHORA USAMOS STREAMBUILDER PARA VER LOS CAMBIOS EN TIEMPO REAL
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('routines').doc(routineId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Esta rutina ha sido eliminada.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final bool isActive = data['isActive'] ?? false;
          final List exercises = data['exercises'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BOTÓN DE ANALÍTICA (Intacto)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RoutineProgressScreen(
                              routineId: routineId,
                              routineTitle: title,
                              patientName: 'Paciente Activo', 
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, 
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.analytics),
                      label: const Text('Ver Resultados del Paciente', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),

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
                
                // LISTA DE EJERCICIOS CON BOTONES DE EDICIÓN
                Expanded(
                  child: exercises.isEmpty 
                    ? const Center(child: Text('No hay ejercicios en esta rutina.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index] as Map<String, dynamic>;
                          final String urlText = (exercise['youtubeUrl'] != null && exercise['youtubeUrl'].toString().isNotEmpty) 
                              ? '\nURL: ${exercise['youtubeUrl']}' 
                              : '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade50,
                                child: Text('${index + 1}', style: const TextStyle(color: Colors.teal)),
                              ),
                              title: Text(exercise['title'] ?? exercise['name'] ?? 'Ejercicio', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${exercise['sets']} Series x ${exercise['reps']} Repeticiones$urlText'),
                              isThreeLine: urlText.isNotEmpty,
                              
                              // LA MAGIA DE LA EDICIÓN: El menú de 3 puntitos
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editExercise(context, exercises, index);
                                  } else if (value == 'delete') {
                                    _removeExercise(context, exercises, index);
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar Series/Reps'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('Quitar Ejercicio'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}