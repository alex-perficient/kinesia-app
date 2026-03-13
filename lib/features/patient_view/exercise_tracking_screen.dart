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
  String? _physioId; // NUEVO: Aquí guardaremos el ID del fisioterapeuta
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
    // Inicializamos el controlador (duración de 2 segundos)
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadPatientProfile();
    _initializeSets();
  }

  Future<void> _loadPatientProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(currentUserId)
          .get();
      if (doc.exists) {
        setState(() {
          _profileType = doc.data()?['profileType'] ?? 'fitness';
          _physioId = doc.data()?['physioId'];
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
        'reps': TextEditingController(
          text: widget.exercise['reps'].toString(),
        ), // Sugerimos las reps recetadas
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

      // NUEVO: Disparamos la notificación de regreso al Fisio
      if (_physioId != null) {
        await NotificationService.sendNotification(
          receiverId: _physioId!,
          title: 'Ejercicio Registrado 💪',
          body:
              'Tu paciente ha completado el ejercicio: ${widget.exercise['title']}.',
        );
      }

      if (mounted) {
        // 1. Hacemos vibrar el celular (sensación de impacto táctil)
        HapticFeedback.heavyImpact();
        
        // 2. Disparamos el confeti
        _confettiController.play();

        // 3. Mensaje motivacional
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Excelente esfuerzo! 🔥 Un paso más cerca de tu meta.'),
            backgroundColor: Colors.green, // Color positivo
            duration: Duration(seconds: 3),
          ),
        );
        
        // Retrasamos la salida medio segundo para que el paciente alcance a ver la explosión
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
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

    return Stack(
      children: [
        Scaffold(
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
            const Text(
              'Registra tus series de hoy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Filas dinámicas de las Series
            ...List.generate(_setsControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Serie ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _setsControllers[index]['reps'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Reps',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _setsControllers[index]['weight'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg/lb)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 48, thickness: 2),

            // ESCALA RPE (Esfuerzo Percibido) - Para todos los perfiles
            const Text(
              'RPE - Esfuerzo Percibido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              '¿Qué tan pesado sentiste este ejercicio?',
              style: TextStyle(color: Colors.grey),
            ),
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

            // ESCALA EVA (Dolor) - ¡SOLO PARA PERFIL CLÍNICO!
            if (_profileType == 'clinical') ...[
              const Text(
                'EVA - Escala de Dolor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const Text(
                '¿Sentiste algún dolor anormal articular?',
                style: TextStyle(color: Colors.grey),
              ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                icon: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save),
                label: const Text(
                  'Guardar Registro',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive, // Explota hacia todos lados
            shouldLoop: false,
            colors: const [Colors.teal, Colors.green, Colors.blue, Colors.orange], // Colores de Mon TI Labs
            createParticlePath: drawStar, // Opcional: Si quieres que sean estrellitas
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