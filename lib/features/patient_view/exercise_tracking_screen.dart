import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kinesia_app/services/notification_service.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart'; // Para hacer vibrar el celular
import 'dart:math';

class ExerciseTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final String routineId;
  final String patientName;

  const ExerciseTrackingScreen({
    super.key,
    required this.exercise,
    required this.routineId,
    required this.patientName,
  });

  @override
  State<ExerciseTrackingScreen> createState() => _ExerciseTrackingScreenState();
}

class _ExerciseTrackingScreenState extends State<ExerciseTrackingScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? _physioId; 
  bool _isLoadingProfile = true;
  bool _isSaving = false;
  
  // Controlador para la lluvia de confeti
  late ConfettiController _confettiController;

  // Variables para las escalas de la Libreta de Monitoreo
  double _rpeValue = 5; // Esfuerzo (1-10)
  double _evaValue = 0; // Dolor (0-10)

  // Controladores dinámicos para las series
  final List<Map<String, TextEditingController>> _setsControllers = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadPatientProfile();
    _initializeSets();
  }

  Future<void> _loadPatientProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('patients').doc(currentUserId).get();
      if (doc.exists) {
        setState(() {
          _physioId = doc.data()?['physioId'];
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingProfile = false);
    }
  }

  void _initializeSets() {
    // 1. Extraemos el dato crudo de Firebase
    final rawSets = widget.exercise['sets'];
    int targetSets = 1; // Valor por defecto por si algo falla

    // 2. Lo convertimos a número de forma segura, sin importar cómo se haya guardado
    if (rawSets is int) {
      targetSets = rawSets; // Si ya es un número (Rutina manual)
    } else if (rawSets is String) {
      targetSets = int.tryParse(rawSets) ?? 1; // Si es un texto (Plantilla)
    }

    // 3. Dibujamos las filas correspondientes
    for (int i = 0; i < targetSets; i++) {
      _setsControllers.add({
        'reps': TextEditingController(text: widget.exercise['reps'].toString()), 
        'weight': TextEditingController(), 
      });
    }
  }

  Future<void> _saveWorkoutLog() async {
    setState(() => _isSaving = true);

    try {
      // Leemos qué pidió el fisio para este ejercicio específico
      final bool askEVA = widget.exercise['askEVA'] ?? false;
      final bool askRIR = widget.exercise['askRIR'] ?? false;
      final bool askWeight = widget.exercise['askWeight'] ?? false;

      // 1. Recopilamos los datos de las series
      List<Map<String, dynamic>> completedSets = [];
      for (var controllers in _setsControllers) {
        completedSets.add({
          'reps': int.tryParse(controllers['reps']!.text) ?? 0,
          // Solo guardamos el peso si el fisio lo pidió
          'weight': askWeight ? (double.tryParse(controllers['weight']!.text) ?? 0.0) : null,
        });
      }

      // 2. Armamos el documento de la bitácora
      final logData = {
        'patientId': currentUserId,
        'physioId': _physioId,
        'routineId': widget.routineId,
        'exerciseName': widget.exercise['title'] ?? widget.exercise['name'],
        'date': FieldValue.serverTimestamp(),
        'sets': completedSets,
        // MAGIA GRANULAR: Guardamos RPE y EVA solo si el fisio encendió el switch
        'rpe': askRIR ? _rpeValue.toInt() : null,
        'eva': askEVA ? _evaValue.toInt() : null,
      };

      // 3. Guardamos en la colección 'workout_logs'
      await FirebaseFirestore.instance.collection('workout_logs').add(logData);

      // 4. Notificamos al Fisio
      if (_physioId != null) {
        await NotificationService.sendNotification(
          receiverId: _physioId!,
          title: 'Avance de ${widget.patientName} 💪',
          body: '${widget.patientName} ha completado: ${widget.exercise['title'] ?? widget.exercise['name']}.',
        );
      }

      if (mounted) {
        HapticFeedback.heavyImpact();
        _confettiController.play();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Excelente esfuerzo! 🔥 Un paso más cerca de tu meta.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
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

    // Leemos los interruptores del ejercicio
    final bool askEVA = widget.exercise['askEVA'] ?? false;
    final bool askRIR = widget.exercise['askRIR'] ?? false;
    final bool askWeight = widget.exercise['askWeight'] ?? false;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.exercise['title'] ?? widget.exercise['name'] ?? 'Registro'),
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
                        // MAGIA GRANULAR: El campo de peso solo aparece si el fisio lo pidió
                        if (askWeight) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _setsControllers[index]['weight'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Peso (kg/lb)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                const Divider(height: 48, thickness: 2),

                // MAGIA GRANULAR: Escala RPE (Solo si el fisio la pidió)
                if (askRIR) ...[
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
                    children: const [Text('1 (Muy Ligero)'), Text('10 (Máximo)')],
                  ),
                  const SizedBox(height: 32),
                ],

                // MAGIA GRANULAR: Escala EVA (Solo si el fisio la pidió)
                if (askEVA) ...[
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
                    children: const [Text('0 (Nada)'), Text('10 (Peor dolor)')],
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
                ),
              ],
            ),
          ),
        ),
        
        // ¡TU CONFETI INTACTO!
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive, 
            shouldLoop: false,
            colors: const [Colors.teal, Colors.green, Colors.blue, Colors.orange], 
            createParticlePath: drawStar, // Descomenta si tienes tu función drawStar
          ),
        ),
      ],
    );
  }
}

  // Dibuja una estrella para el confeti
  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step), halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep), halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }