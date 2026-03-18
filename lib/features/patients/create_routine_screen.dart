import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exercise_config_dialog.dart'; // Importamos nuestro panel maestro

class CreateRoutineScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const CreateRoutineScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final TextEditingController _titleController = TextEditingController();
  
  // Lista dinámica para guardar los ejercicios antes de enviarlos a Firebase
  final List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = false;

  // Llamamos al panel granular exactamente igual que en las plantillas
  void _addNewExercise() async {
    final newExerciseData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ExerciseConfigDialog(),
    );

    if (newExerciseData != null) {
      setState(() {
        _exercises.add({
          'name': newExerciseData['title'], // Usamos 'name' por compatibilidad con tu BD
          'youtubeUrl': newExerciseData['youtubeUrl'],
          'sets': newExerciseData['sets'],
          'reps': newExerciseData['reps'],
          'askEVA': newExerciseData['askEVA'],
          'askRIR': newExerciseData['askRPE'], // Mapeamos RPE a RIR para tu tracking
          'askWeight': newExerciseData['askWeight'],
        });
      });
    }
  }

  // Guardamos la rutina en la base de datos
  Future<void> _saveRoutine() async {
    if (_titleController.text.trim().isEmpty || _exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un título y agrega al menos un ejercicio.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String physioId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('routines').add({
        'patientId': widget.patientId,
        'physioId': physioId,
        'title': _titleController.text.trim(),
        'exercises': _exercises,
        'isActive': true, // Por defecto al crearla manual, entra activa
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina asignada exitosamente al paciente 🚀', style: TextStyle(color: Colors.white)), backgroundColor: Colors.teal),
        );
        Navigator.pop(context); // Regresamos a la pantalla anterior
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Rutina: ${widget.patientName}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Cabecera (Título)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título de la Rutina (ej. Post-Op Rodilla)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
          ),

          const Divider(thickness: 2),

          // 2. Encabezado de la lista con el botón de agregar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ejercicios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addNewExercise, // ¡CONECTADO AL NUEVO DIÁLOGO!
                  icon: const Icon(Icons.add_circle, color: Colors.teal),
                  label: const Text('Agregar', style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
          ),

          // 3. Lista dinámica de ejercicios
          Expanded(
            child: _exercises.isEmpty
                ? const Center(
                    child: Text(
                      'Sin ejercicios.\nToca "Agregar" para usar el panel avanzado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _exercises[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade50,
                            child: Text('${index + 1}', style: const TextStyle(color: Colors.teal)),
                          ),
                          title: Text(exercise['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${exercise['sets']} series x ${exercise['reps']}'),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: [
                                  if (exercise['askEVA'] == true)
                                    const Text('• Dolor', style: TextStyle(color: Colors.red, fontSize: 12)),
                                  if (exercise['askRIR'] == true)
                                    const Text('• Esfuerzo', style: TextStyle(color: Colors.orange, fontSize: 12)),
                                  if (exercise['askWeight'] == true)
                                    const Text('• Peso', style: TextStyle(color: Colors.blue, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setState(() => _exercises.removeAt(index));
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 4. Botón inferior para guardar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveRoutine,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar Rutina e Iniciar Rehabilitación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}