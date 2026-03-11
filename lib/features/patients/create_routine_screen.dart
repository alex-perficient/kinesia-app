import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kinesia_app/services/notification_service.dart';

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
  final TextEditingController _routineTitleController = TextEditingController();
  
  // Lista de controladores para los ejercicios dinámicos
  List<Map<String, TextEditingController>> _exercises = [];

  @override
  void initState() {
    super.initState();
    _addExerciseField(); // Iniciar con un ejercicio vacío
  }

  // Función para añadir un nuevo bloque de ejercicio al formulario
  void _addExerciseField() {
    setState(() {
      _exercises.add({
        'title': TextEditingController(),
        'url': TextEditingController(),
        'sets': TextEditingController(),
        'reps': TextEditingController(),
      });
    });
  }

  // Función para quitar un ejercicio de la lista
  void _removeExerciseField(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<void> _saveRoutine() async {
    if (_routineTitleController.text.isEmpty || _exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, agrega un título y al menos un ejercicio.')),
      );
      return;
    }

    try {
      final String physioId = FirebaseAuth.instance.currentUser!.uid;

      // Transformamos los controladores en una lista de Mapas para Firestore
      List<Map<String, dynamic>> exercisesData = _exercises.map((e) {
        return {
          'title': e['title']!.text.trim(),
          'youtubeUrl': e['url']!.text.trim(),
          'sets': int.tryParse(e['sets']!.text) ?? 0,
          'reps': int.tryParse(e['reps']!.text) ?? 0,
        };
      }).toList();

      // Guardamos la rutina en Firestore
      await FirebaseFirestore.instance.collection('routines').add({
        'physioId': physioId,
        'patientId': widget.patientId,
        'title': _routineTitleController.text.trim(),
        'exercises': exercisesData,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // NUEVO: Disparador de Notificación
      await NotificationService.sendNotification(
        receiverId: widget.patientId, // Asegúrate de que esta variable exista en tu pantalla
        title: 'Nueva Rutina Asignada 🏋️',
        body: 'Tu fisioterapeuta te ha enviado nuevos ejercicios para trabajar.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina creada con éxito ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nueva Rutina: ${widget.patientName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _routineTitleController,
              decoration: const InputDecoration(
                labelText: 'Título de la Rutina (ej. Post-Op Rodilla)',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Lista dinámica de ejercicios
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ejercicio #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeExerciseField(index),
                            )
                          ],
                        ),
                        TextField(
                          controller: _exercises[index]['title'],
                          decoration: const InputDecoration(labelText: 'Nombre del ejercicio'),
                        ),
                        TextField(
                          controller: _exercises[index]['url'],
                          decoration: const InputDecoration(labelText: 'URL de YouTube'),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _exercises[index]['sets'],
                                decoration: const InputDecoration(labelText: 'Series'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _exercises[index]['reps'],
                                decoration: const InputDecoration(labelText: 'Reps'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            TextButton.icon(
              onPressed: _addExerciseField,
              icon: const Icon(Icons.add),
              label: const Text('Añadir otro ejercicio'),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveRoutine,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                child: const Text('Guardar Rutina e Iniciar Rehabilitación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}