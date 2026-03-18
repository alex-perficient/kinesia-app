import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../patients/exercise_config_dialog.dart';

class CreateTemplateScreen extends StatefulWidget {
  const CreateTemplateScreen({super.key});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Lista dinámica para guardar los ejercicios de esta plantilla
  final List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = false;

  // Función para abrir nuestro nuevo panel de configuración externa
  void _showAddExerciseDialog() async {
    final newExerciseData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ExerciseConfigDialog(),
    );

    // Si el fisio le dio a "Guardar" y no a "Cancelar"
    if (newExerciseData != null) {
      setState(() {
        // Mapeamos los datos del diálogo a tu lista local
        _exercises.add({
          'name': newExerciseData['title'], // Tu lista abajo espera 'name'
          'youtubeUrl': newExerciseData['youtubeUrl'],
          'sets': newExerciseData['sets'],
          'reps': newExerciseData['reps'],
          'askEVA': newExerciseData['askEVA'],
          'askRIR': newExerciseData['askRPE'], // Tu lista abajo usa 'askRIR'
          'askWeight': newExerciseData['askWeight'],
        });
      });
    }
  }


  // Función para guardar toda la plantilla en Firebase
  Future<void> _saveTemplate() async {
    if (_titleController.text.trim().isEmpty || _exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un título y agrega al menos un ejercicio.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String physioId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('routine_templates').add({
        'physioId': physioId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'exercises': _exercises, // Guardamos la lista completa de ejercicios
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla guardada con éxito 📚')),
        );
        Navigator.pop(context); // Regresamos a la biblioteca
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
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Plantilla'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Cabecera de la Plantilla
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título de la Plantilla (ej. Fase 1 - Rodilla)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción o indicaciones generales (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(thickness: 2),
          
          // 2. Título de la lista y botón de agregar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ejercicios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _showAddExerciseDialog,
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
                    child: Text('Sin ejercicios.\nToca "Agregar" para comenzar.', 
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
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
                              // Dibujamos pequeños indicadores si las métricas están activas
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
      
      // 4. Botón inferior para guardar toda la plantilla
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTemplate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar Plantilla en Biblioteca', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}