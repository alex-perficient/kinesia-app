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

  // NUEVAS VARIABLES FREEMIUM
  bool _isLoadingStatus = true;
  bool _isAiLocked = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _checkFreemiumStatus(); // Verificamos el plan al abrir la pantalla
  }

  // NUEVA FUNCIÓN: Valida si tiene derecho a usar IA
  Future<void> _checkFreemiumStatus() async {
    try {
      final physioId = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('physiotherapists').doc(physioId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final String plan = data['plan'] ?? 'free';
        final int count = data['patientCount'] ?? 0;

        // Si es gratuito y ya llegó a su cuota de volumen (15)
        if (plan == 'free' && count >= 15) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe notas o graba un audio primero.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      const apiKey = 'AIzaSyCBf7MHxG9ja12hsXxFeeW_ZkreDOAbVCY'; 
      
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
      );

      final promptText = '''
Eres un asistente médico experto en fisioterapia. Analiza la consulta (ya sea en texto o audio). 
Extrae y profesionaliza lo siguiente: 
1. "diagnosis" (Diagnóstico clínico probable o descrito)
2. "objectives" (Objetivos terapéuticos a corto/largo plazo)
3. "painZones" (Zonas de dolor y nivel EVA si se menciona)
4. "transcription" (Si recibes un audio, transcribe literalmente lo que el doctor dijo. Si solo recibes texto, devuelve el mismo texto).
Responde ÚNICAMENTE con un JSON válido con esas 4 llaves exactas en minúsculas. No agregues texto extra ni formato markdown.
''';

      List<Part> promptParts = [TextPart(promptText)];

      if (_audioPath != null && _audioPath!.isNotEmpty) {
        final audioFile = File(_audioPath!);
        final audioBytes = await audioFile.readAsBytes();
        promptParts.add(DataPart('audio/mp4', audioBytes));
      } else {
        promptParts.add(TextPart('\nNOTAS DE LA CONSULTA:\n${_notesController.text}'));
      }

      final content = [Content.multi(promptParts)];
      final response = await model.generateContent(content);

      String rawJson = response.text ?? '{}';
      rawJson = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(rawJson);

      setState(() {
        _diagnosisController.text = data['diagnosis'] ?? 'No detectado';
        _objectivesController.text = data['objectives'] ?? 'No detectado';
        _painZonesController.text = data['painZones'] ?? 'No detectado';
        
        if (_audioPath != null && _audioPath!.isNotEmpty) {
          _notesController.text = data['transcription'] ?? 'No se pudo generar la transcripción.';
        }
        
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
        final fileName = '${widget.patientId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final storageRef = FirebaseStorage.instance.ref().child('audios_clinicos/$fileName');

        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nota: La subida de audio real se probará en el dispositivo Android.')),
          );
        } else {
          final file = File(_audioPath!);
          final uploadTask = await storageRef.putFile(file);
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
        body: 'Tu fisioterapeuta ha actualizado tus notas de evolución.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expediente clínico guardado con éxito ✅')),
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

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _audioPath = path;
          _notesController.text = "[Audio grabado listo para analizar]...\n(Para la demo de hoy, puedes escribir el texto manual aquí para que Gemini lo procese)";
        });
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio guardado exitosamente.')),
        );
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          String tempPath = '';
          if (!kIsWeb) {
            final tempDir = await getTemporaryDirectory();
            tempPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          }

          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: tempPath,
          );
          
          setState(() {
            _isRecording = true;
          });
        } else {
          if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Necesitas dar permisos de micrófono.')),
          );
        }}
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error con el micrófono: $e')),
      );
    }}
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

  @override
  Widget build(BuildContext context) {
    // Si está consultando la BD, mostramos carga
    if (_isLoadingStatus) {
      return Scaffold(
        appBar: AppBar(title: Text('Evaluación: ${widget.patientName}'), backgroundColor: Colors.teal),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            // ==========================================
            // NUEVO: EL PAYWALL FREEMIUM
            // ==========================================
            if (_isAiLocked) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.purple.shade500]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Límite Gratuito Alcanzado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Has superado tu cuota de pacientes. Reactiva el poder del dictado por voz y la Inteligencia Artificial por solo \$100 MXN mensuales.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        // 1. Preparamos el mensaje y el número
                        const phoneNumber = '529332443982'; // Pon tu número aquí
                        const message = 'Hola Mon TI Labs, quiero actualizar mi cuenta de Kines.ia al plan Premium para desbloquear la Inteligencia Artificial. 🚀';
                        
                        // 2. Codificamos la URL para que WhatsApp la entienda
                        final Uri whatsappUrl = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

                        // 3. Intentamos abrir la app de WhatsApp
                        try {
                          if (await canLaunchUrl(whatsappUrl)) {
                            await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No se pudo abrir WhatsApp. Escríbenos al $phoneNumber')),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error al abrir el enlace.')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple.shade700,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Actualizar Plan (WhatsApp)'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Instrucción para el llenado manual
              const Text(
                '📝 Captura Manual (Modo Básico)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              const Text(
                'Puedes continuar guardando el expediente clínico ingresando los datos manualmente a continuación.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],

            // ==========================================
            // INTERFAZ ORIGINAL (Oculta micrófono si está bloqueado)
            // ==========================================
            if (!_isAiLocked) ...[
              const Text('Consulta y Notas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 16),
              
              Center(
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red.shade100 : Colors.teal.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: _isRecording ? Colors.red : Colors.teal, width: _isRecording ? 4 : 2),
                    ),
                    child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 40, color: _isRecording ? Colors.red : Colors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _isRecording ? 'Grabando consulta... (Toca para detener)' : 'Toca para grabar al paciente',
                  style: TextStyle(color: _isRecording ? Colors.red : Colors.grey, fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal),
                ),
              ),
              const SizedBox(height: 24),
              
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'O escribe las notas manualmente aquí...', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _runAIAnalysis,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600, foregroundColor: Colors.white),
                  icon: _isAnalyzing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isAnalyzing ? 'Analizando con IA...' : 'Extraer Datos con IA', style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(thickness: 2),
              const SizedBox(height: 24),
            ],

            // ==========================================
            // SECCIÓN 2: Resultados (Se muestra si analizó IA o si está bloqueado para llenado manual)
            // ==========================================
            if (_showResults || _isAiLocked) ...[
              if (_showResults && !_isAiLocked) ...[
                const Text('Resumen Clínico Generado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 16),
              ],
              
              // Si está bloqueado, necesita el TextField general que reemplaza al micrófono
              if (_isAiLocked) ...[
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notas Generales (Evolución)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
              ],

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