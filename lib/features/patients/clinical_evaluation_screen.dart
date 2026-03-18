import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../../services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _objectivesController = TextEditingController();
  final TextEditingController _painZonesController = TextEditingController();

  bool _isAnalyzing = false;
  bool _showResults = false;
  bool _isSaving = false;

  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _audioPath;

  bool _isLoadingStatus = true;
  bool _isAiLocked = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _checkFreemiumStatus(); 
  }

  Future<void> _checkFreemiumStatus() async {
    try {
      final physioId = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('physiotherapists').doc(physioId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if ((data['plan'] ?? 'free') == 'free' && (data['patientCount'] ?? 0) >= 15) {
          setState(() => _isAiLocked = true);
        }
      }
    } catch (e) {
      debugPrint('Error validando plan: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _runAIAnalysis() async {
    if (_notesController.text.trim().isEmpty && (_audioPath == null || _audioPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe notas o graba un audio primero.')));
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);

      final promptText = '''
Eres un asistente médico experto en fisioterapia. Analiza la consulta. 
Extrae: 1. "diagnosis" 2. "objectives" 3. "painZones" 4. "transcription".
Responde ÚNICAMENTE con un JSON válido con esas 4 llaves exactas en minúsculas.
''';

      List<Part> promptParts = [TextPart(promptText)];

      if (_audioPath != null && _audioPath!.isNotEmpty) {
        promptParts.add(DataPart('audio/mp4', await File(_audioPath!).readAsBytes()));
      } else {
        promptParts.add(TextPart('\nNOTAS:\n${_notesController.text}'));
      }

      final response = await model.generateContent([Content.multi(promptParts)]);
      String rawJson = (response.text ?? '{}').replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(rawJson);

      setState(() {
        _diagnosisController.text = data['diagnosis'] ?? 'No detectado';
        _objectivesController.text = data['objectives'] ?? 'No detectado';
        _painZonesController.text = data['painZones'] ?? 'No detectado';
        if (_audioPath != null && _audioPath!.isNotEmpty) _notesController.text = data['transcription'] ?? 'Sin transcripción.';
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
      String? uploadedAudioUrl;
      if (_audioPath != null && _audioPath!.isNotEmpty) {
        if (!kIsWeb) {
          final uploadTask = await FirebaseStorage.instance.ref().child('audios_clinicos/${widget.patientId}_${DateTime.now().millisecondsSinceEpoch}.m4a').putFile(File(_audioPath!));
          uploadedAudioUrl = await uploadTask.ref.getDownloadURL();
        }
      }

      await FirebaseFirestore.instance.collection('clinical_histories').add({
        'patientId': widget.patientId,
        'date': FieldValue.serverTimestamp(),
        'rawNotes': _notesController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'objectives': _objectivesController.text.trim(),
        'painZones': _painZonesController.text.trim(),
        'audioUrl': uploadedAudioUrl,
      });

      await NotificationService.sendNotification(receiverId: widget.patientId, title: 'Nuevo Expediente Clínico', body: 'Tu fisioterapeuta ha actualizado tus notas.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expediente clínico guardado ✅')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() { _isRecording = false; _audioPath = path; _notesController.text = "Audio listo para analizar."; });
      } else {
        if (await _audioRecorder.hasPermission()) {
          String tempPath = '';
          if (!kIsWeb) tempPath = '${(await getTemporaryDirectory()).path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: tempPath);
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error micrófono: $e')));
    }
  }

  @override
  void dispose() {
    _notesController.dispose(); _diagnosisController.dispose(); _objectivesController.dispose(); _painZonesController.dispose(); _audioRecorder.dispose();
    super.dispose();
  }

  // Helpers para diseño limpio
  InputDecoration _premiumInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label, labelStyle: TextStyle(color: Colors.grey.shade600), prefixIcon: Icon(icon, color: Colors.teal),
      filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    if (_isLoadingStatus) return Scaffold(appBar: AppBar(backgroundColor: darkSlate, title: const Text('Cargando...')), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Evaluación Asistida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // EL PAYWALL FREEMIUM
            if (_isAiLocked) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: darkSlate, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 15, offset: const Offset(0, 5))]),
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 48),
                    const SizedBox(height: 16),
                    const Text('Límite de IA Alcanzado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    const Text('Has superado tu cuota. Reactiva el poder del dictado por voz y la extracción automática por \$100 MXN.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.4)),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () async { const p = '529332443982'; const m = 'Hola Mon TI Labs, quiero actualizar mi cuenta de Kines.ia al plan Premium para desbloquear la Inteligencia Artificial. 🚀'; final u = Uri.parse('https://wa.me/$p?text=${Uri.encodeComponent(m)}'); if (await canLaunchUrl(u)) { await launchUrl(u, mode: LaunchMode.externalApplication); } }, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: darkSlate, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Actualizar Plan (WhatsApp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Captura Manual (Básica)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 24),
            ],

            // GRABADORA IA
            if (!_isAiLocked) ...[
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _isRecording ? Colors.red.shade100 : Colors.transparent), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 15)]),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _toggleRecording,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 90, width: 90,
                        decoration: BoxDecoration(color: _isRecording ? Colors.red : Colors.teal.shade50, shape: BoxShape.circle, boxShadow: _isRecording ? [BoxShadow(color: Colors.red.withValues(alpha:0.4), blurRadius: 20, spreadRadius: 5)] : []),
                        child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 40, color: _isRecording ? Colors.white : Colors.teal),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_isRecording ? 'Escuchando consulta...' : 'Toca para grabar al paciente', style: TextStyle(color: _isRecording ? Colors.red : darkSlate, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(controller: _notesController, maxLines: 4, decoration: _premiumInput('O escribe las notas aquí...', Icons.edit_note)),
              const SizedBox(height: 24),
              SizedBox(height: 55, child: ElevatedButton.icon(onPressed: _isAnalyzing ? null : _runAIAnalysis, style: ElevatedButton.styleFrom(backgroundColor: darkSlate, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: _isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome, color: Colors.amber), label: Text(_isAnalyzing ? 'Analizando con IA...' : 'Extraer Datos con IA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 32),
            ],

            // RESULTADOS DEL FORMULARIO
            if (_showResults || _isAiLocked) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 15)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datos Estructurados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
                    const SizedBox(height: 24),
                    if (_isAiLocked) ...[TextField(controller: _notesController, maxLines: 3, decoration: _premiumInput('Notas Generales', Icons.notes)), const SizedBox(height: 16)],
                    TextField(controller: _diagnosisController, decoration: _premiumInput('Diagnóstico', Icons.medical_services_outlined)),
                    const SizedBox(height: 16),
                    TextField(controller: _objectivesController, maxLines: 2, decoration: _premiumInput('Objetivos Terapéuticos', Icons.flag_outlined)),
                    const SizedBox(height: 16),
                    TextField(controller: _painZonesController, decoration: _premiumInput('Zonas de Dolor', Icons.personal_injury_outlined)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: (_showResults || _isAiLocked) ? Container(
        padding: const EdgeInsets.all(24),
        color: Colors.grey.shade100,
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveEvaluation,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 4),
            child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Expediente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ) : null,
    );
  }
}