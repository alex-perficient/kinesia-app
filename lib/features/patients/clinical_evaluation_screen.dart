import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class ClinicalEvaluationScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const ClinicalEvaluationScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ClinicalEvaluationScreen> createState() => _ClinicalEvaluationScreenState();
}

class _ClinicalEvaluationScreenState extends State<ClinicalEvaluationScreen> {
  // Controlador para las notas en bruto (texto libre o futuro dictado por voz)
  final TextEditingController _notesController = TextEditingController();
  
  // Controladores para los datos estructurados por la IA
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _objectivesController = TextEditingController();
  final TextEditingController _painZonesController = TextEditingController();

  bool _isAnalyzing = false;
  bool _showResults = false;
  bool _isSaving = false;

  // Esta función simulará a Gemini por ahora
  Future<void> _runAIAnalysis() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe algunas notas primero.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // ⚠️ TEMPORAL PARA HOY: Pega tu API Key aquí.
      const apiKey = 'AIzaSyCBf7MHxG9ja12hsXxFeeW_ZkreDOAbVCY'; 
      
      // Usamos el modelo fundacional global (gemini-pro) que no tiene restricciones
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
      );

      // Combinamos la instrucción maestra y las notas en un solo bloque de texto
      final prompt = '''
Eres un asistente médico experto en fisioterapia. Analiza las siguientes notas coloquiales de la consulta. 
Extrae y profesionaliza 3 cosas: 
1. "diagnosis" (Diagnóstico clínico probable o descrito)
2. "objectives" (Objetivos terapéuticos a corto/largo plazo)
3. "painZones" (Zonas de dolor y nivel EVA si se menciona)
Responde ÚNICAMENTE con un JSON válido con esas 3 llaves exactas en minúsculas. No agregues texto extra ni formato markdown.

NOTAS DE LA CONSULTA:
${_notesController.text}
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      // Limpiamos la respuesta de cualquier formato extra
      String rawJson = response.text ?? '{}';
      rawJson = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();

      // Convertimos a Mapa
      final data = jsonDecode(rawJson);

      setState(() {
        _diagnosisController.text = data['diagnosis'] ?? 'No detectado';
        _objectivesController.text = data['objectives'] ?? 'No detectado';
        _painZonesController.text = data['painZones'] ?? 'No detectado';
        
        _isAnalyzing = false;
        _showResults = true;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de IA: $e')));
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _saveEvaluation() async {
    setState(() => _isSaving = true);

    try {
      // Guardamos en una nueva colección del historial clínico
      await FirebaseFirestore.instance.collection('clinical_histories').add({
        'patientId': widget.patientId,
        'date': FieldValue.serverTimestamp(),
        'rawNotes': _notesController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'objectives': _objectivesController.text.trim(),
        'painZones': _painZonesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expediente clínico guardado con éxito ✅')),
        );
        Navigator.pop(context); // Regresa al perfil del paciente
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _diagnosisController.dispose();
    _objectivesController.dispose();
    _painZonesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evaluación: ${widget.patientName}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECCIÓN 1: Captura de Datos
            const Text(
              'Notas de la Consulta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escribe los síntomas, el dolor y los objetivos que el paciente te mencione. Pronto agregaremos el dictado por voz.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Ej. El paciente llega refiriendo dolor en la rodilla derecha al subir escaleras...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Botón de Análisis IA
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _runAIAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600, // Color distintivo para la IA
                  foregroundColor: Colors.white,
                ),
                icon: _isAnalyzing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome), // Ícono de "magia/IA"
                label: Text(_isAnalyzing ? 'Analizando con IA...' : 'Extraer Datos con IA', style: const TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(thickness: 2),
            const SizedBox(height: 24),

            // SECCIÓN 2: Resultados Editables (Solo se muestran después de analizar)
            if (_showResults) ...[
              const Text(
                'Resumen Clínico Generado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _diagnosisController,
                decoration: const InputDecoration(labelText: 'Diagnóstico', border: OutlineInputBorder(), prefixIcon: Icon(Icons.medical_services)),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _objectivesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Objetivos del Paciente', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag)),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _painZonesController,
                decoration: const InputDecoration(labelText: 'Zonas de Dolor', border: OutlineInputBorder(), prefixIcon: Icon(Icons.personal_injury)),
              ),
              const SizedBox(height: 32),
              
              // Botón Final para Guardar
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveEvaluation,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                  label: const Text('Guardar Expediente', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}