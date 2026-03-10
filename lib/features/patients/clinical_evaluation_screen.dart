import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Para saber si estamos en Chrome o en Celular
import 'package:path_provider/path_provider.dart';
import '../../services/notification_service.dart'; // Ajusta la ruta según tus carpetas

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

  // NUEVAS VARIABLES PARA AUDIO
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder(); // Inicializamos el grabador
  }

  // Esta función simulará a Gemini por ahora
  Future<void> _runAIAnalysis() async {
    // Validamos que haya al menos texto O un audio grabado
    if (_notesController.text.trim().isEmpty && (_audioPath == null || _audioPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe notas o graba un audio primero.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // ⚠️ TEMPORAL PARA HOY: Pega tu API Key aquí.
      const apiKey = 'AIzaSyCBf7MHxG9ja12hsXxFeeW_ZkreDOAbVCY'; 
      
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
      );

      // Agregamos una 4ta llave a nuestro JSON esperado: la transcripción
      final promptText = '''
Eres un asistente médico experto en fisioterapia. Analiza la consulta (ya sea en texto o audio). 
Extrae y profesionaliza lo siguiente: 
1. "diagnosis" (Diagnóstico clínico probable o descrito)
2. "objectives" (Objetivos terapéuticos a corto/largo plazo)
3. "painZones" (Zonas de dolor y nivel EVA si se menciona)
4. "transcription" (Si recibes un audio, transcribe literalmente lo que el doctor dijo. Si solo recibes texto, devuelve el mismo texto).
Responde ÚNICAMENTE con un JSON válido con esas 4 llaves exactas en minúsculas. No agregues texto extra ni formato markdown.
''';

      // Preparamos las partes que le enviaremos a Gemini
      List<Part> promptParts = [TextPart(promptText)];

      // Si el fisio grabó un audio, lo leemos de la memoria y lo adjuntamos al prompt
      if (_audioPath != null && _audioPath!.isNotEmpty) {
        final audioFile = File(_audioPath!);
        final audioBytes = await audioFile.readAsBytes();
        promptParts.add(DataPart('audio/mp4', audioBytes)); // .m4a es tratado como audio/mp4
      } else {
        // Si no hay audio, le mandamos el texto que escribió manualmente
        promptParts.add(TextPart('\nNOTAS DE LA CONSULTA:\n${_notesController.text}'));
      }

      // Enviamos el paquete completo a la IA
      final content = [Content.multi(promptParts)];
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
        
        // ¡Magia! Si subió audio, Gemini nos devuelve la transcripción y la ponemos en la caja de texto
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

      // 1. SI HAY UN AUDIO GRABADO, LO SUBIMOS PRIMERO
      if (_audioPath != null && _audioPath!.isNotEmpty) {
        // Creamos una ruta única en Storage: audios_clinicos / ID_PACIENTE / fecha.m4a
        final fileName = '${widget.patientId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final storageRef = FirebaseStorage.instance.ref().child('audios_clinicos/$fileName');

        // Dependiendo de si estamos en Web o en Celular, la forma de subirlo cambia un poco
        if (kIsWeb) {
          // En Web por ahora solo dejamos el aviso (la web maneja los audios como Blob)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nota: La subida de audio real se probará en el dispositivo Android.')),
          );
        } else {
          // En Android/iOS subimos el archivo físico
          final file = File(_audioPath!);
          final uploadTask = await storageRef.putFile(file);
          // Obtenemos el link público para poder reproducirlo después
          uploadedAudioUrl = await uploadTask.ref.getDownloadURL();
        }
      }

      // 2. GUARDAMOS EL TEXTO EN LA BASE DE DATOS COMO ANTES (Agregando el link del audio)
      await FirebaseFirestore.instance.collection('clinical_histories').add({
        'patientId': widget.patientId,
        'date': FieldValue.serverTimestamp(),
        'rawNotes': _notesController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'objectives': _objectivesController.text.trim(),
        'painZones': _painZonesController.text.trim(),
        'audioUrl': uploadedAudioUrl, // ¡AQUÍ ESTÁ EL LINK DEL AUDIO!
      });

      // ... (código donde guardas el expediente) ...

      // NUEVO: Disparamos la notificación al paciente
      await NotificationService.sendNotification(
        receiverId: widget.patientId,
        title: 'Nuevo Expediente Clínico',
        body: 'Tu fisioterapeuta ha actualizado tus notas de evolución.',
      );

// ... (resto de tu código) ...

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expediente clínico guardado con éxito ✅')),
        );
        Navigator.pop(context); // Regresa al perfil del paciente
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
    _diagnosisController.dispose();
    _objectivesController.dispose();
    _painZonesController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // FUNCIÓN PARA INICIAR/DETENER GRABACIÓN
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // Detener grabación
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _audioPath = path;
          // Simulamos que el audio se transcribió automáticamente para la demo de hoy
          _notesController.text = "[Audio grabado listo para analizar]...\n(Para la demo de hoy, puedes escribir el texto manual aquí para que Gemini lo procese)";
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio guardado exitosamente.')),
        );
      // ... (código anterior)
        } else {
          // Iniciar grabación
          if (await _audioRecorder.hasPermission()) {
            
            // 1. Obtenemos la carpeta temporal del celular (Exclusivo para Android/iOS)
            String tempPath = '';
            if (!kIsWeb) {
              final tempDir = await getTemporaryDirectory();
              tempPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
            }

            // 2. Le pasamos esa ruta física real al grabador (en web tempPath será '', lo cual está bien)
            await _audioRecorder.start(
              const RecordConfig(encoder: AudioEncoder.aacLc), // Forzamos formato AAC súper ligero
              path: tempPath,
            );
            
            setState(() {
              _isRecording = true;
            });
         // ... (resto de tu código)
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Necesitas dar permisos de micrófono.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error con el micrófono: $e')),
      );
    }
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
              'Consulta y Notas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 16),
            
            // EL BOTÓN DE GRABACIÓN
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
                    border: Border.all(
                      color: _isRecording ? Colors.red : Colors.teal,
                      width: _isRecording ? 4 : 2,
                    ),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 40,
                    color: _isRecording ? Colors.red : Colors.teal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _isRecording ? 'Grabando consulta... (Toca para detener)' : 'Toca para grabar al paciente',
                style: TextStyle(
                  color: _isRecording ? Colors.red : Colors.grey,
                  fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'O escribe las notas manualmente aquí...',
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