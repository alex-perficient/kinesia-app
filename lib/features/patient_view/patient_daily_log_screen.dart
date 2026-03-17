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

  Future<void> _saveDailyLog() async {
    setState(() => _isSaving = true);

    try {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      
      // 1. Buscamos el ID del fisio para que este registro aparezca en su Torre de Control
      final patientDoc = await FirebaseFirestore.instance.collection('patients').doc(currentUserId).get();
      final String physioId = patientDoc.data()?['physioId'] ?? '';

      // 2. Guardamos en una nueva colección maestra
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
            content: Text('Bitácora registrada. ¡Gracias por actualizar tu estado!'),
            backgroundColor: Colors.teal,
          )
        );
        Navigator.pop(context); // Regresamos al Home
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
        title: const Text('¿Cómo te sientes hoy?'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tu bienestar es prioridad',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            const Text(
              'Registra tu estado actual para que tu fisioterapeuta pueda monitorear tu evolución general.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // ESCALA DE DOLOR GENERAL
            const Text('Dolor General (Cuerpo completo)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Slider(
              value: _painLevel,
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: _painLevel > 6 ? Colors.red : (_painLevel > 3 ? Colors.orange : Colors.green),
              label: _painLevel.round().toString(),
              onChanged: (val) => setState(() => _painLevel = val),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [Text('0 (Sin dolor)'), Text('10 (Insoportable)')],
            ),
            const SizedBox(height: 32),

            // ESCALA DE FATIGA / ENERGÍA
            const Text('Nivel de Cansancio / Fatiga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Slider(
              value: _fatigueLevel,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: Colors.blue.shade400,
              label: _fatigueLevel.round().toString(),
              onChanged: (val) => setState(() => _fatigueLevel = val),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [Text('1 (Mucha Energía)'), Text('10 (Exhausto)')],
            ),
            const SizedBox(height: 32),

            // NOTAS LIBRES
            const Text('Notas adicionales (Opcional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ej. Me dolió la espalda al despertar, dormí mal, me siento excelente hoy...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 40),

            // BOTÓN DE GUARDAR
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDailyLog,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.send),
                label: const Text('Enviar Reporte', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}