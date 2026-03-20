import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kinesia_app/services/notification_service.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart'; 
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
  
  late ConfettiController _confettiController;
  double _rpeValue = 5; 
  double _evaValue = 0; 

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
    final rawSets = widget.exercise['sets'];
    int targetSets = 1; 

    if (rawSets is int) {
      targetSets = rawSets; 
    } else if (rawSets is String) {
      targetSets = int.tryParse(rawSets) ?? 1; 
    }

    for (int i = 0; i < targetSets; i++) {
      _setsControllers.add({
        'reps': TextEditingController(text: widget.exercise['reps'].toString()), 
        'weight': TextEditingController(), 
      });
    }
  }

  // EL MOTOR LÓGICO DE GAMIFICACIÓN
  Future<void> _updatePatientStreakAndCheckAlerts(bool askEVA, String exerciseName) async {
    final patientRef = FirebaseFirestore.instance.collection('patients').doc(currentUserId);
    final patientDoc = await patientRef.get();
    
    if (patientDoc.exists) {
      final data = patientDoc.data() as Map<String, dynamic>;
      int streak = data['streakCount'] ?? 0;
      Timestamp? lastDate = data['lastActivityDate'];

      final now = DateTime.now();
      if (lastDate != null) {
        final last = lastDate.toDate();
        // Calculamos la diferencia en días naturales (ignorando la hora)
        final difference = DateTime(now.year, now.month, now.day).difference(DateTime(last.year, last.month, last.day)).inDays;

        if (difference == 1) {
          streak += 1; // Entrenó ayer y hoy = suma racha
        } else if (difference > 1) {
          streak = 1; // Pasó más de un día = pierde la racha
        }
        // Si difference == 0, significa que ya había entrenado hoy, la racha se mantiene igual.
      } else {
        streak = 1; // Su primer entrenamiento
      }

      await patientRef.update({
        'streakCount': streak,
        'lastActivityDate': FieldValue.serverTimestamp(),
      });

      // SEMÁFORO CLÍNICO 🚨
      if (_physioId != null && askEVA && _evaValue >= 7) {
        await NotificationService.sendNotification(
          receiverId: _physioId!,
          title: '🚨 Alerta de Dolor Alto',
          body: '${widget.patientName} reportó un nivel de dolor de ${_evaValue.toInt()} en el ejercicio: $exerciseName. Sugerimos revisar su caso.',
        );
      }
    }
  }

  Future<void> _saveWorkoutLog() async {
    setState(() => _isSaving = true);

    try {
      final bool askEVA = widget.exercise['askEVA'] ?? false;
      final bool askRIR = widget.exercise['askRIR'] ?? false;
      final bool askWeight = widget.exercise['askWeight'] ?? false;
      final String exerciseName = widget.exercise['title'] ?? widget.exercise['name'];

      List<Map<String, dynamic>> completedSets = [];
      for (var controllers in _setsControllers) {
        completedSets.add({
          'reps': int.tryParse(controllers['reps']!.text) ?? 0,
          'weight': askWeight ? (double.tryParse(controllers['weight']!.text) ?? 0.0) : null,
        });
      }

      final logData = {
        'patientId': currentUserId,
        'physioId': _physioId,
        'routineId': widget.routineId,
        'exerciseName': exerciseName,
        'date': FieldValue.serverTimestamp(),
        'sets': completedSets,
        'rpe': askRIR ? _rpeValue.toInt() : null,
        'eva': askEVA ? _evaValue.toInt() : null,
      };

      await FirebaseFirestore.instance.collection('workout_logs').add(logData);

      // Ejecutamos nuestro motor de gamificación y semáforo
      await _updatePatientStreakAndCheckAlerts(askEVA, exerciseName);

      if (_physioId != null) {
        await NotificationService.sendNotification(
          receiverId: _physioId!,
          title: 'Avance de ${widget.patientName} 💪',
          body: '${widget.patientName} ha completado: $exerciseName.',
        );
      }

      if (mounted) {
        HapticFeedback.heavyImpact();
        _confettiController.play();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Excelente esfuerzo! 🔥 Un paso más cerca de tu meta.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Color(0xFF0D9488), 
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
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
      return const Scaffold(backgroundColor: Color(0xFF0F172A), body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)));
    }

    final bool askEVA = widget.exercise['askEVA'] ?? false;
    final bool askRIR = widget.exercise['askRIR'] ?? false;
    final bool askWeight = widget.exercise['askWeight'] ?? false;
    final String exerciseName = widget.exercise['title'] ?? widget.exercise['name'] ?? 'Registro';

    const Color darkBg = Color(0xFF0F172A);
    const Color surfaceBg = Color(0xFF1E293B);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: darkBg, 
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('ENTRENAMIENTO ACTIVO', style: TextStyle(color: Colors.tealAccent, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(exerciseName.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1)),
                const SizedBox(height: 32),

                ...List.generate(_setsControllers.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: surfaceBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.tealAccent)),
                        ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('REPS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _setsControllers[index]['reps'],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                decoration: InputDecoration(filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 12)),
                              ),
                            ],
                          ),
                        ),
                        
                        if (askWeight) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PESO (KG/LB)', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _setsControllers[index]['weight'],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                  decoration: InputDecoration(filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 12), hintText: '0', hintStyle: const TextStyle(color: Colors.white24)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                if (askRIR || askEVA) const Divider(color: Colors.white12, thickness: 2, height: 48),

                if (askRIR) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: surfaceBg, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Esfuerzo Percibido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), Icon(Icons.local_fire_department, color: Colors.orangeAccent)]),
                        const SizedBox(height: 16),
                        Text(_rpeValue.toInt().toString(), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.orangeAccent)),
                        Slider(value: _rpeValue, min: 1, max: 10, divisions: 9, activeColor: Colors.orangeAccent, inactiveColor: Colors.black26, onChanged: (val) => setState(() => _rpeValue = val)),
                        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('1 (Ligero)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)), Text('10 (Al Fallo)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (askEVA) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: surfaceBg, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Escala de Dolor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), Icon(Icons.warning_amber_rounded, color: Colors.redAccent)]),
                        const SizedBox(height: 16),
                        Text(_evaValue.toInt().toString(), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: _evaValue > 5 ? Colors.redAccent : Colors.tealAccent)),
                        Slider(value: _evaValue, min: 0, max: 10, divisions: 10, activeColor: _evaValue >= 7 ? Colors.redAccent : Colors.tealAccent, inactiveColor: Colors.black26, onChanged: (val) => setState(() => _evaValue = val)),
                        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('0 (Nada)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)), Text('10 (Peor Dolor)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                SizedBox(
                  height: 65, 
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveWorkoutLog,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent.shade400, foregroundColor: darkBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                    child: _isSaving ? const CircularProgressIndicator(color: Color(0xFF0F172A)) : const Text('COMPLETAR EJERCICIO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive, 
            shouldLoop: false,
            colors: const [Colors.tealAccent, Colors.greenAccent, Colors.blueAccent, Colors.orangeAccent], 
            createParticlePath: drawStar, 
          ),
        ),
      ],
    );
  }

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
}