import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'physio_exercise_bank_screen.dart';

class RoutineBuilderScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const RoutineBuilderScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  final TextEditingController _routineNameController = TextEditingController();
  final List<Map<String, dynamic>> _selectedExercises = [];
  bool _isSaving = false;

  // Función para abrir el Banco y esperar el resultado
  Future<void> _openExerciseBank() async {
    final selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PhysioExerciseBankScreen(isSelecting: true),
      ),
    );

    if (selectedExercise != null) {
      // Si el fisio eligió uno, lo agregamos a la lista con valores por defecto
      setState(() {
        _selectedExercises.add({
          'exerciseId': selectedExercise['id'],
          'name': selectedExercise['name'],
          'sets': 3,
          'reps': 10,
        });
      });
    }
  }

  // Función para guardar en Firebase
  Future<void> _saveRoutine() async {
    if (_routineNameController.text.trim().isEmpty ||
        _selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega un nombre y al menos un ejercicio'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('routines').add({
        'patientId': widget.patientId,
        'physioId':
            'FISIO_ID_TEMPORAL', // Sustituiremos con FirebaseAuth despues
        'routineName': _routineNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'exercises': _selectedExercises,
        'isActive': true,
      });

      if (mounted) {
        Navigator.pop(context); // Regresamos al perfil del paciente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina asignada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: darkSlate,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          children: [
            const Text(
              'NUEVA RUTINA',
              style: TextStyle(
                color: Colors.tealAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              'Para ${widget.patientName}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // HEADER: NOMBRE DE LA RUTINA
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: TextField(
              controller: _routineNameController,
              decoration: InputDecoration(
                labelText:
                    'Nombre de la Rutina (Ej. Rehabilitación Rodilla Fase 1)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // LISTA DE EJERCICIOS SELECCIONADOS
          Expanded(
            child: _selectedExercises.isEmpty
                ? Center(
                    child: Text(
                      'Aún no has agregado ejercicios.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _selectedExercises[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            exercise['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Row(
                            children: [
                              Text('Series: ${exercise['sets']}'),
                              const SizedBox(width: 16),
                              Text('Reps: ${exercise['reps']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(
                              () => _selectedExercises.removeAt(index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // BOTONES INFERIORES
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _openExerciseBank,
                  icon: const Icon(Icons.add),
                  label: const Text('BUSCAR EN BANCO DE EJERCICIOS'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    foregroundColor: darkSlate,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveRoutine,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.tealAccent.shade400,
                    foregroundColor: darkSlate,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: darkSlate)
                      : const Text(
                          'GUARDAR Y ASIGNAR RUTINA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
