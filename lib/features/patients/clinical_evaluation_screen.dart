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
import 'package:image_picker/image_picker.dart';

class ClinicalEvaluationScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const ClinicalEvaluationScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ClinicalEvaluationScreen> createState() =>
      _ClinicalEvaluationScreenState();
}

class _ClinicalEvaluationScreenState extends State<ClinicalEvaluationScreen> {
  // Campos Clínicos
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _objectivesController = TextEditingController();
  final TextEditingController _painZonesController = TextEditingController();
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

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
      final doc = await FirebaseFirestore.instance
          .collection('physiotherapists')
          .doc(physioId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if ((data['plan'] ?? 'free') == 'free' &&
            (data['patientCount'] ?? 0) >= 15) {
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
    if (_notesController.text.trim().isEmpty &&
        (_audioPath == null || _audioPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe notas de la sesión o graba un audio primero.'),
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      ); // Actualizado a modelo estable reciente

      final promptText = '''
Eres un asistente médico experto en fisioterapia. Analiza la consulta. 
Extrae: 1. "diagnosis" 2. "objectives" 3. "painZones" 4. "transcription".
Responde ÚNICAMENTE con un JSON válido con esas 4 llaves exactas en minúsculas.
''';

      List<Part> promptParts = [TextPart(promptText)];

      if (_audioPath != null && _audioPath!.isNotEmpty) {
        promptParts.add(
          DataPart('audio/mp4', await File(_audioPath!).readAsBytes()),
        );
      } else {
        promptParts.add(TextPart('\nNOTAS:\n${_notesController.text}'));
      }

      final response = await model.generateContent([
        Content.multi(promptParts),
      ]);
      String rawJson = (response.text ?? '{}')
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final data = jsonDecode(rawJson);

      setState(() {
        if (data['diagnosis'] != null) {
          _diagnosisController.text = data['diagnosis'];
        }
        if (data['objectives'] != null) {
          _objectivesController.text = data['objectives'];
        }
        if (data['painZones'] != null) {
          _painZonesController.text = data['painZones'];
        }
        if (_audioPath != null && _audioPath!.isNotEmpty) {
          _notesController.text = data['transcription'] ?? 'Sin transcripción.';
        }
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Datos extraídos mágicamente! ✨'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de IA: $e')));
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _scanDocument() async {
    try {
      // 1. Abrimos la cámara
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null) return; // El usuario canceló

      setState(() => _isScanning = true);

      // 2. Preparamos la imagen para Gemini
      final bytes = await image.readAsBytes();
      final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      // 3. El Prompt estricto para OCR Médico
      final prompt = TextPart(
        'Eres un asistente médico experto. Transcribe de forma exacta todo el texto (manuscrito o impreso) que veas en esta hoja o receta médica. No agregues introducciones ni comentarios, devuelve exclusivamente el texto crudo que logres leer.',
      );
      final imagePart = DataPart('image/jpeg', bytes);

      // 4. Mandamos a procesar
      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      // 5. Vaciamos el texto en las notas
      setState(() {
        // Si ya había texto, le sumamos el nuevo
        final textoPrevio = _notesController.text.isNotEmpty ? "\n" : "";
        _notesController.text += textoPrevio + (response.text ?? '').trim();
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📄 Texto extraído mágicamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al escanear: $e')));
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _saveEvaluation() async {
    setState(() => _isSaving = true);
    try {
      String? uploadedAudioUrl;
      if (_audioPath != null && _audioPath!.isNotEmpty) {
        if (!kIsWeb) {
          final uploadTask = await FirebaseStorage.instance
              .ref()
              .child(
                'audios_clinicos/${widget.patientId}_${DateTime.now().millisecondsSinceEpoch}.m4a',
              )
              .putFile(File(_audioPath!));
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

      await NotificationService.sendNotification(
        receiverId: widget.patientId,
        title: 'Nuevo Expediente Clínico',
        body: 'Tu fisioterapeuta ha actualizado tus notas.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expediente guardado con éxito ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _audioPath = path;
          _notesController.text = "Audio capturado y listo para analizar.";
        });
      } else {
        if (await _audioRecorder.hasPermission()) {
          String tempPath = '';
          if (!kIsWeb) {
            tempPath =
                '${(await getTemporaryDirectory()).path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          }
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: tempPath,
          );
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error micrófono: $e')));
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _diagnosisController.dispose();
    _objectivesController.dispose();
    _painZonesController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  InputDecoration _premiumInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.teal, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    if (_isLoadingStatus) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: darkSlate,
          title: const Text('Cargando...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Evaluación del Paciente',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
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
            // SECCIÓN ÚNICA: CAPTURA CLÍNICA (Manual o IA)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diagnóstico y Evolución',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: darkSlate,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isAiLocked) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkSlate,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.amber,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Asistente de IA Bloqueado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaywallScreen(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: darkSlate,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Desbloquear ahora',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // NUEVO BOTÓN: Escanear Hoja
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isScanning ? null : _scanDocument,
                          icon: _isScanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.document_scanner_outlined),
                          label: Text(
                            _isScanning
                                ? 'Leyendo documento...'
                                : 'Escanear Expediente (Foto)',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkSlate,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _toggleRecording,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? Colors.red
                                  : Colors.teal.shade50,
                              shape: BoxShape.circle,
                              boxShadow: _isRecording
                                  ? [
                                      BoxShadow(
                                        color: Colors.red.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: 28,
                              color: _isRecording ? Colors.white : Colors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: _premiumInput(
                              'Notas de sesión (o dicta aquí)',
                              Icons.edit_note,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _runAIAnalysis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkSlate,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.auto_awesome,
                                color: Colors.amber,
                                size: 18,
                              ),
                        label: Text(
                          _isAnalyzing
                              ? 'Extrayendo datos...'
                              : 'Procesar con Inteligencia Artificial',
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                  ],

                  TextField(
                    controller: _diagnosisController,
                    maxLines: 2,
                    decoration: _premiumInput(
                      'Diagnóstico',
                      Icons.medical_services_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _objectivesController,
                    maxLines: 2,
                    decoration: _premiumInput(
                      'Objetivos Terapéuticos',
                      Icons.flag_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _painZonesController,
                    decoration: _premiumInput(
                      'Zonas de Dolor',
                      Icons.personal_injury_outlined,
                    ),
                  ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Guardar Expediente',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
