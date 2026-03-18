import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exercise_config_dialog.dart'; 

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
  final List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = false;

  void _addNewExercise() async {
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

  Future<void> _saveRoutine() async {
    if (_titleController.text.trim().isEmpty || _exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ponle un título y agrega al menos un ejercicio.')));
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
        'isActive': true, 
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rutina asignada exitosamente 🚀'), backgroundColor: Colors.teal));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Rutina: ${widget.patientName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha blanca asegurada
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. CABECERA BLANCA (Título)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkSlate),
              decoration: InputDecoration(
                hintText: 'Ej. Fase 1: Rodilla',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                border: InputBorder.none,
                icon: const Icon(Icons.edit_document, color: Colors.teal, size: 28),
              ),
            ),
          ),
          
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // 2. ENCABEZADO DE LISTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ejercicios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
                OutlinedButton.icon(
                  onPressed: _addNewExercise,
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
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.list_alt, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), const Text('Lista vacía.\nAñade el primer ejercicio.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))]))
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
            onPressed: _isLoading ? null : _saveRoutine,
            style: ElevatedButton.styleFrom(backgroundColor: darkSlate, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 4),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Asignar al Paciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}