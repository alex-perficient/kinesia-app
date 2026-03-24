import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ¡IMPORTANTE PARA QUE EL SEMÁFORO FUNCIONE AQUÍ!
import 'package:kinesia_app/services/notification_service.dart';

class PatientDailyLogScreen extends StatefulWidget {
  const PatientDailyLogScreen({super.key});

  @override
  State<PatientDailyLogScreen> createState() => _PatientDailyLogScreenState();
}

class _PatientDailyLogScreenState extends State<PatientDailyLogScreen> {
  double _painLevel = 0;
  double _fatigueLevel = 5;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  String _getPainEmoji(double value) {
    if (value == 0) return '💪';
    if (value <= 3) return '🙂';
    if (value <= 6) return '😕';
    if (value <= 8) return '😣';
    return '😫';
  }

  String _getEnergyEmoji(double value) {
    if (value <= 3) return '⚡';
    if (value <= 6) return '🔋';
    if (value <= 8) return '🪫';
    return '🛌';
  }

  // GAMIFICACIÓN Y SEMÁFORO PARA EL DIARIO
  Future<void> _updatePatientStreakAndCheckAlerts(
    String physioId,
    String patientName,
  ) async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final patientRef = FirebaseFirestore.instance
        .collection('patients')
        .doc(currentUserId);
    final patientDoc = await patientRef.get();

    if (patientDoc.exists) {
      final data = patientDoc.data() as Map<String, dynamic>;
      int streak = data['streakCount'] ?? 0;
      Timestamp? lastDate = data['lastActivityDate'];

      final now = DateTime.now();
      if (lastDate != null) {
        final last = lastDate.toDate();
        final difference = DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(last.year, last.month, last.day)).inDays;

        if (difference == 1) {
          streak += 1;
        } else if (difference > 1) {
          streak = 1;
        }
      } else {
        streak = 1;
      }

      await patientRef.update({
        'streakCount': streak,
        'lastActivityDate': FieldValue.serverTimestamp(),
      });

      // SEMÁFORO CLÍNICO 🚨
      if (physioId.isNotEmpty && _painLevel >= 7) {
        await NotificationService.sendNotification(
          receiverId: physioId,
          title: '🚨 Alerta de Dolor Diario',
          body:
              '$patientName reportó un nivel de dolor de ${_painLevel.toInt()} el día de hoy. Sugerimos contactarlo.',
          type: 'urgent', // <-- ¡EL DISPARADOR CLAVE PARA EL TRIAGE!
          patientId: currentUserId, // <-- Guardamos quién lo detonó
        );
      }
    }
  }

  Future<void> _saveDailyLog() async {
    setState(() => _isSaving = true);

    try {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(currentUserId)
          .get();
      final String physioId = patientDoc.data()?['physioId'] ?? '';
      final String patientName =
          patientDoc.data()?['fullName'] ?? 'Tu paciente';

      await FirebaseFirestore.instance.collection('daily_logs').add({
        'patientId': currentUserId,
        'physioId': physioId,
        'date': FieldValue.serverTimestamp(),
        'generalPain': _painLevel.toInt(),
        'fatigue': _fatigueLevel.toInt(),
        'notes': _notesController.text.trim(),
      });

      // Disparamos la lógica de gamificación y alertas
      await _updatePatientStreakAndCheckAlerts(physioId, patientName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Excelente! Registro completado y racha actualizada 🔥',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
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
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Diario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Escucha a tu cuerpo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Un buen atleta sabe cuándo empujar y cuándo descansar. ¿Cómo te sientes hoy?',
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 32),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      _getPainEmoji(_painLevel),
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nivel de Dolor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _painLevel == 0
                          ? 'Sin molestias físicas'
                          : 'Nivel ${_painLevel.toInt()}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _painLevel >= 7 ? Colors.red : Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _painLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: _painLevel >= 7
                          ? Colors.red
                          : (_painLevel > 3 ? Colors.orange : Colors.teal),
                      onChanged: (val) => setState(() => _painLevel = val),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Nada',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Insoportable',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      _getEnergyEmoji(_fatigueLevel),
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nivel de Energía',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Impacto: ${_fatigueLevel.toInt()}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _fatigueLevel > 7 ? Colors.red : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _fatigueLevel,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: Colors.blue,
                      onChanged: (val) => setState(() => _fatigueLevel = val),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Al máximo',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Exhausto',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.book, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Diario de Recuperación',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Ej. Dormí excelente, pero siento la rodilla rígida...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDailyLog,
                icon: _isSaving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_circle),
                label: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Completar Check-in'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
