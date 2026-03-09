import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExerciseTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final String routineId;

  const ExerciseTrackingScreen({
    super.key,
    required this.exercise,
    required this.routineId,
  });

  @override
  State<ExerciseTrackingScreen> createState() => _ExerciseTrackingScreenState();
}

class _ExerciseTrackingScreenState extends State<ExerciseTrackingScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String _profileType = 'fitness'; // Por defecto
  bool _isLoadingProfile = true;
  bool _isSaving = false;

  // Variables para las escalas de la Libreta de Monitoreo
  double _rpeValue = 5; // Esfuerzo (1-10)
  double _evaValue = 0; // Dolor (0-10)

  // Controladores dinámicos para las series
  final List<Map<String, TextEditingController>> _setsControllers = [];

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
    _initializeSets();
  }

  Future<void> _loadPatientProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('patients').doc(currentUserId).get();
      if (doc.exists) {
        setState(() {
          _profileType = doc.data()?['profileType'] ?? 'fitness';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingProfile = false);
    }
  }

  void _initializeSets() {
    // Leemos cuántas series le recetó el fisio y creamos esa cantidad de filas
    int targetSets = widget.exercise['sets'] ?? 1;
    for (int i = 0; i < targetSets; i++) {
      _setsControllers.add({
        'reps': TextEditingController(text: widget.exercise['reps'].toString()), // Sugerimos las reps recetadas
        'weight': TextEditingController(), // El peso siempre empieza en blanco
      });
    }
  }

  Future<void> _saveWorkoutLog() async {
    setState(() => _isSaving = true);

    try {
      // 1. Recopilamos los datos de las series
      List<Map<String, dynamic>> completedSets = [];
      for (var controllers in _setsControllers) {
        completedSets.add({
          'reps': int.tryParse(controllers['reps']!.text) ?? 0,
          'weight': double.tryParse(controllers['weight']!.text) ?? 0.0,
        });
      }

      // 2. Armamos el documento de la bitácora
      final logData = {
        'patientId': currentUserId,
        'routineId': widget.routineId,
        'exerciseName': widget.exercise['title'],
        'date': FieldValue.serverTimestamp(),
        'sets': completedSets,
        'rpe': _rpeValue.toInt(),
        // Solo guardamos el EVA si es un paciente clínico
        'eva': _profileType == 'clinical' ? _evaValue.toInt() : null,
      };

      // 3. Guardamos en una nueva colección maestra llamada 'workout_logs'
      await FirebaseFirestore.instance.collection('workout_logs').add(logData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Excelente! Registro guardado.')),
        );
        Navigator.pop(context); // Regresamos a la rutina
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    for (var controllers in _setsControllers) {
      controllers['reps']!.dispose();
      controllers['weight']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise['title'] ?? 'Registro'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Registra tus series de hoy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Filas dinámicas de las Series
            ...List.generate(_setsControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text('Serie ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _setsControllers[index]['reps'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Reps', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _setsControllers[index]['weight'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Peso (kg/lb)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(height: 48, thickness: 2),

            // ESCALA RPE (Esfuerzo Percibido) - Para todos los perfiles
            const Text('RPE - Esfuerzo Percibido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('¿Qué tan pesado sentiste este ejercicio?', style: TextStyle(color: Colors.grey)),
            Slider(
              value: _rpeValue,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: Colors.blue,
              label: _rpeValue.toInt().toString(),
              onChanged: (val) => setState(() => _rpeValue = val),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('1 (Muy Ligero)'),
                Text('10 (Máximo)'),
              ],
            ),

            const SizedBox(height: 32),

            // ESCALA EVA (Dolor) - ¡SOLO PARA PERFIL CLÍNICO!
            if (_profileType == 'clinical') ...[
              const Text('EVA - Escala de Dolor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              const Text('¿Sentiste algún dolor anormal articular?', style: TextStyle(color: Colors.grey)),
              Slider(
                value: _evaValue,
                min: 0,
                max: 10,
                divisions: 10,
                activeColor: Colors.red,
                label: _evaValue.toInt().toString(),
                onChanged: (val) => setState(() => _evaValue = val),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('0 (Nada)'),
                  Text('10 (Peor dolor)'),
                ],
              ),
              const SizedBox(height: 32),
            ],

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveWorkoutLog,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                label: const Text('Guardar Registro', style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}