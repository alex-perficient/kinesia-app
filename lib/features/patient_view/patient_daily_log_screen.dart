import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Helpers para los emojis dinámicos
  String _getPainEmoji(double value) {
    if (value == 0) return '💪'; // Cero dolor, fuerte
    if (value <= 3) return '🙂'; // Ligera molestia
    if (value <= 6) return '😕'; // Dolor moderado
    if (value <= 8) return '😣'; // Dolor fuerte
    return '😫'; // Inaguantable
  }

  String _getEnergyEmoji(double value) {
    if (value <= 3) return '⚡'; // 1-3: Mucha energía
    if (value <= 6) return '🔋'; // 4-6: Batería normal
    if (value <= 8) return '🪫'; // 7-8: Batería baja
    return '🛌'; // 9-10: Exhausto
  }

  Future<void> _saveDailyLog() async {
    setState(() => _isSaving = true);

    try {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      
      final patientDoc = await FirebaseFirestore.instance.collection('patients').doc(currentUserId).get();
      final String physioId = patientDoc.data()?['physioId'] ?? '';

      await FirebaseFirestore.instance.collection('daily_logs').add({
        'patientId': currentUserId,
        'physioId': physioId,
        'date': FieldValue.serverTimestamp(),
        'generalPain': _painLevel.toInt(),
        'fatigue': _fatigueLevel.toInt(),
        'notes': _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Excelente! Registro completado.', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating, // Estilo Premium flotante
          )
        );
        Navigator.pop(context); 
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
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Diario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CABECERA MOTIVACIONAL
            const Text(
              'Escucha a tu cuerpo',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Un buen atleta sabe cuándo empujar y cuándo descansar. ¿Cómo te sientes hoy?',
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 32),

            // TARJETA 1: DOLOR FÍSICO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(_getPainEmoji(_painLevel), style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    const Text('Nivel de Dolor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _painLevel == 0 ? 'Sin molestias físicas' : 'Nivel ${_painLevel.toInt()}',
                      style: TextStyle(fontSize: 16, color: _painLevel > 6 ? Colors.red : Colors.teal),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _painLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: _painLevel > 6 ? Colors.red : (_painLevel > 3 ? Colors.orange : Colors.teal),
                      onChanged: (val) => setState(() => _painLevel = val),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Nada', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)), 
                        Text('Insoportable', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // TARJETA 2: ENERGÍA (Antes "Fatiga")
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(_getEnergyEmoji(_fatigueLevel), style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    const Text('Nivel de Energía', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Impacto: ${_fatigueLevel.toInt()}',
                      style: TextStyle(fontSize: 16, color: _fatigueLevel > 7 ? Colors.red : Colors.blue),
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
                        Text('Al máximo', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)), 
                        Text('Exhausto', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // TARJETA 3: DIARIO (Notas)
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
                        Text('Diario de Recuperación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ej. Dormí excelente, pero siento la rodilla un poco rígida al caminar...',
                        border: InputBorder.none, // Quitamos el borde duro para que parezca una libreta
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

            // BOTÓN DE GUARDAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDailyLog,
                icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.check_circle),
                label: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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