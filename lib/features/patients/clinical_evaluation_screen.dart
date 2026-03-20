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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../dashboard_physio/paywall_screen.dart';

// Estructura de control para campos dinámicos
class CustomField {
  TextEditingController nameController = TextEditingController();
  TextEditingController valueController = TextEditingController();
}

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
  // Campos Estáticos Originales
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _objectivesController = TextEditingController();
  final TextEditingController _painZonesController = TextEditingController();

  // NUEVO: Campos Demográficos Básicos
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // NUEVO: Campos Dinámicos
  final List<CustomField> _customFields = [];

  bool _isAnalyzing = false;
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

  // Agrega un campo dinámico a la lista
  void _addCustomField() {
    setState(() {
      _customFields.add(CustomField());
    });
  }

  Future<void> _runAIAnalysis() async {
    if (_notesController.text.trim().isEmpty && (_audioPath == null || _audioPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe notas de la sesión o graba un audio primero.')));
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
        // La IA rellena automáticamente los campos que el fisio ya estaba viendo
        if(data['diagnosis'] != null) _diagnosisController.text = data['diagnosis'];
        if(data['objectives'] != null) _objectivesController.text = data['objectives'];
        if(data['painZones'] != null) _painZonesController.text = data['painZones'];
        if (_audioPath != null && _audioPath!.isNotEmpty) _notesController.text = data['transcription'] ?? 'Sin transcripción.';
        _isAnalyzing = false;
      });
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Datos extraídos mágicamente! ✨'), backgroundColor: Colors.teal));
    } }catch (e) {
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

      // Procesamos los campos personalizados para guardarlos como Mapa
      Map<String, String> dynamicData = {};
      for (var field in _customFields) {
        if (field.nameController.text.trim().isNotEmpty) {
          dynamicData[field.nameController.text.trim()] = field.valueController.text.trim();
        }
      }

      await FirebaseFirestore.instance.collection('clinical_histories').add({
        'patientId': widget.patientId,
        'date': FieldValue.serverTimestamp(),
        'age': _ageController.text.trim(),
        'phone': _phoneController.text.trim(),
        'customFields': dynamicData, // Guardamos Dieta, Alergias, etc.
        'rawNotes': _notesController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'objectives': _objectivesController.text.trim(),
        'painZones': _painZonesController.text.trim(),
        'audioUrl': uploadedAudioUrl,
      });

      await NotificationService.sendNotification(receiverId: widget.patientId, title: 'Nuevo Expediente Clínico', body: 'Tu fisioterapeuta ha actualizado tus notas.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expediente guardado con éxito ✅')));
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
        setState(() { _isRecording = false; _audioPath = path; _notesController.text = "Audio capturado y listo para analizar."; });
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
    _notesController.dispose(); _diagnosisController.dispose(); _objectivesController.dispose(); _painZonesController.dispose();
    _ageController.dispose(); _phoneController.dispose();
    for (var field in _customFields) { field.nameController.dispose(); field.valueController.dispose(); }
    _audioRecorder.dispose();
    super.dispose();
  }

  InputDecoration _premiumInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label, labelStyle: TextStyle(color: Colors.grey.shade600), prefixIcon: Icon(icon, color: Colors.teal, size: 20),
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
        title: const Text('Evaluación del Paciente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. SECCIÓN DEMOGRÁFICA Y CAMPOS PERSONALIZADOS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 15)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Datos Generales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: _premiumInput('Edad', Icons.cake))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _premiumInput('Teléfono', Icons.phone))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Lista dinámica de campos (Alergias, Dieta, etc.)
                  if (_customFields.isNotEmpty) ...[
                    const Text('Datos Adicionales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkSlate)),
                    const SizedBox(height: 12),
                    ...List.generate(_customFields.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: TextField(controller: _customFields[index].nameController, decoration: _premiumInput('Nombre (ej. Dieta)', Icons.label_outline))),
                            const SizedBox(width: 8),
                            Expanded(flex: 3, child: TextField(controller: _customFields[index].valueController, decoration: _premiumInput('Valor', Icons.edit))),
                            IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => setState(() => _customFields.removeAt(index))),
                          ],
                        ),
                      );
                    }),
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addCustomField,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar campo personalizado'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.teal, side: BorderSide(color: Colors.teal.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. SECCIÓN CLÍNICA (Manual o IA)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 15)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Diagnóstico y Evolución', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
                  const SizedBox(height: 16),

                  // Bloque IA y Notas
                  if (_isAiLocked) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: darkSlate, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.amber, size: 32),
                          const SizedBox(height: 8),
                          const Text('Asistente de IA Bloqueado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaywallScreen())), 
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: darkSlate, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                            child: const Text('Desbloquear ahora', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _toggleRecording,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 60, width: 60,
                            decoration: BoxDecoration(color: _isRecording ? Colors.red : Colors.teal.shade50, shape: BoxShape.circle, boxShadow: _isRecording ? [BoxShadow(color: Colors.red.withValues(alpha:0.4), blurRadius: 15, spreadRadius: 2)] : []),
                            child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 28, color: _isRecording ? Colors.white : Colors.teal),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _notesController, maxLines: 2, decoration: _premiumInput('Notas de sesión (o dicta aquí)', Icons.edit_note))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _isAnalyzing ? null : _runAIAnalysis, style: ElevatedButton.styleFrom(backgroundColor: darkSlate, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: _isAnalyzing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome, color: Colors.amber, size: 18), label: Text(_isAnalyzing ? 'Extrayendo datos...' : 'Procesar con Inteligencia Artificial'))),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                  ],

                  // Campos siempre visibles (El fisio puede escribir a mano si no quiere usar la IA)
                  TextField(controller: _diagnosisController, maxLines: 2, decoration: _premiumInput('Diagnóstico', Icons.medical_services_outlined)),
                  const SizedBox(height: 12),
                  TextField(controller: _objectivesController, maxLines: 2, decoration: _premiumInput('Objetivos Terapéuticos', Icons.flag_outlined)),
                  const SizedBox(height: 12),
                  TextField(controller: _painZonesController, decoration: _premiumInput('Zonas de Dolor', Icons.personal_injury_outlined)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.grey.shade50,
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveEvaluation,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
            child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Expediente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}