import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dashboard_physio/routine_progress_screen.dart';
import '../../services/notification_service.dart';

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
        content: const Text('Esta acción quitará la rutina del celular del paciente inmediatamente. Los registros de los días que ya la completó seguirán a salvo en su bitácora histórica.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
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

  Future<void> _editExercise(BuildContext context, List currentExercises, int index) async {
    final exercise = currentExercises[index];
    final TextEditingController setsCtrl = TextEditingController(text: exercise['sets'].toString());
    final TextEditingController repsCtrl = TextEditingController(text: exercise['reps'].toString());

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajustar Ejercicio', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ejercicio: ${exercise['title'] ?? exercise['name']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 16),
            TextField(controller: setsCtrl, decoration: const InputDecoration(labelText: 'Series', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(controller: repsCtrl, decoration: const InputDecoration(labelText: 'Repeticiones / Tiempo', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar Cambios'),
          ),
        ],
      ),
    );

    if (save == true) {
      List updatedExercises = List.from(currentExercises);
      updatedExercises[index]['sets'] = setsCtrl.text.trim();
      updatedExercises[index]['reps'] = repsCtrl.text.trim();

      await FirebaseFirestore.instance.collection('routines').doc(routineId).update({'exercises': updatedExercises});

      final String patientId = routineData['patientId'] ?? '';
      if (patientId.isNotEmpty) {
        await NotificationService.sendNotification(
          receiverId: patientId,
          title: 'Rutina actualizada 🔄',
          body: 'Tu fisio ha ajustado las series/reps de: ${exercise['title'] ?? exercise['name']}',
        );
      }
      
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio actualizado 👌', style: TextStyle(color: Colors.white)), backgroundColor: Colors.teal));
    }
  }

  Future<void> _removeExercise(BuildContext context, List currentExercises, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar Ejercicio'),
        content: const Text('¿Seguro que quieres quitar este ejercicio de la rutina del paciente? Esto no afectará la plantilla original de la biblioteca.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), 
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      List updatedExercises = List.from(currentExercises);
      updatedExercises.removeAt(index);

      await FirebaseFirestore.instance.collection('routines').doc(routineId).update({'exercises': updatedExercises});

      final String exerciseName = currentExercises[index]['title'] ?? currentExercises[index]['name'] ?? 'un ejercicio';
      final String patientId = routineData['patientId'] ?? '';
      
      if (patientId.isNotEmpty) {
        await NotificationService.sendNotification(
          receiverId: patientId,
          title: 'Rutina aligerada 📉',
          body: 'Tu fisio ha removido: $exerciseName de tu plan.',
        );
      }
      
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio removido 🗑️')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);
    final String title = routineData['title'] ?? 'Detalle de Rutina';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade300,
            tooltip: 'Eliminar Rutina Completa',
            onPressed: () => _deleteRoutine(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('routines').doc(routineId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Esta rutina ha sido eliminada.'));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final bool isActive = data['isActive'] ?? false;
          final List exercises = data['exercises'] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PANEL SUPERIOR: Análisis y Estado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RoutineProgressScreen(routineId: routineId, routineTitle: title, patientName: 'Paciente Activo')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent.shade400, 
                          foregroundColor: darkSlate,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Ver Resultados Analíticos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Estado actual: ', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: isActive ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text(isActive ? 'Activa' : 'Inactiva', style: TextStyle(color: isActive ? Colors.green.shade700 : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ENCABEZADO DE LA LISTA
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text('Ejercicios Asignados (${exercises.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
              ),
              
              // LISTA DE EJERCICIOS EDITABLES
              Expanded(
                child: exercises.isEmpty 
                  ? const Center(child: Text('No hay ejercicios en esta rutina.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index] as Map<String, dynamic>;
                        final bool hasUrl = exercise['youtubeUrl'] != null && exercise['youtubeUrl'].toString().isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(backgroundColor: Colors.teal.shade50, child: Text('${index + 1}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))),
                            title: Text(exercise['title'] ?? exercise['name'] ?? 'Ejercicio', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkSlate)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('${exercise['sets']} Series × ${exercise['reps']}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                if (hasUrl) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [const Icon(Icons.link, size: 12, color: Colors.blue), const SizedBox(width: 4), Expanded(child: Text(exercise['youtubeUrl'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.blue)))])
                                ]
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onSelected: (value) {
                                if (value == 'edit') {_editExercise(context, exercises, index);
                                 } else if (value == 'delete') {_removeExercise(context, exercises, index);
                              }},
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: Colors.teal, size: 20), SizedBox(width: 12), Text('Editar Series/Reps')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('Quitar Ejercicio')])),
                              ],
                            ),
                          ),
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