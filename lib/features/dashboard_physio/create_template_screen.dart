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
  final List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = false;

  void _showAddExerciseDialog() async {
    final newExerciseData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ExerciseConfigDialog(),
    );

    if (newExerciseData != null) {
      setState(() {
        _exercises.add({
          'name': newExerciseData['title'], 
          'youtubeUrl': newExerciseData['youtubeUrl'],
          'sets': newExerciseData['sets'],
          'reps': newExerciseData['reps'],
          'askEVA': newExerciseData['askEVA'],
          'askRIR': newExerciseData['askRPE'], 
          'askWeight': newExerciseData['askWeight'],
        });
      });
    }
  }

  Future<void> _saveTemplate() async {
    if (_titleController.text.trim().isEmpty || _exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ponle un título y agrega al menos un ejercicio.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String physioId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('routine_templates').add({
        'physioId': physioId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'exercises': _exercises, 
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plantilla guardada con éxito 📚')));
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Nueva Plantilla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha blanca asegurada
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. CABECERA BLANCA (Título y Descripción)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkSlate),
                  decoration: InputDecoration(
                    hintText: 'Ej. Fase 1: Rodilla',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                    border: InputBorder.none,
                    icon: const Icon(Icons.library_books, color: Colors.teal, size: 28),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Añade indicaciones generales o notas para esta plantilla...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          
          // 2. ENCABEZADO DE LISTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ejercicios Base', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
                OutlinedButton.icon(
                  onPressed: _showAddExerciseDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.teal, side: BorderSide(color: Colors.teal.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),

          // 3. LISTA DE EJERCICIOS (SaaS Bubbles)
          Expanded(
            child: _exercises.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.list_alt, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), const Text('Plantilla vacía.\nAñade el primer ejercicio.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _exercises[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(backgroundColor: Colors.teal.shade50, child: Text('${index + 1}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))),
                          title: Text(exercise['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkSlate)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${exercise['sets']} series × ${exercise['reps']} reps', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: [
                                  if (exercise['askEVA'] == true) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)), child: Text('Dolor', style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold))),
                                  if (exercise['askRIR'] == true) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)), child: Text('Esfuerzo', style: TextStyle(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.bold))),
                                  if (exercise['askWeight'] == true) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)), child: Text('Peso', style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => setState(() => _exercises.removeAt(index)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      
      // 4. BOTÓN INFERIOR GIGANTE
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTemplate,
            style: ElevatedButton.styleFrom(backgroundColor: darkSlate, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 4),
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Guardar en Biblioteca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}