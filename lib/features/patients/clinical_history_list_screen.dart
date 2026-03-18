import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shimmer/shimmer.dart';
import 'clinical_evaluation_screen.dart'; // IMPORTAMOS LA PANTALLA DE EVALUACIÓN

class ClinicalHistoryListScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const ClinicalHistoryListScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  Future<void> _deleteClinicalNote(BuildContext context, String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta nota clínica?'),
        content: const Text('Esta acción borrará este registro del expediente de forma permanente. ¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('clinical_histories').doc(noteId).delete();
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota clínica eliminada.')));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Expediente: $patientName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('clinical_histories').where('patientId', isEqualTo: patientId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(padding: const EdgeInsets.all(20), itemCount: 3, itemBuilder: (context, index) => const ClinicalHistoryShimmer());
          }

          if (snapshot.hasError) return const Center(child: Text('Error al cargar el expediente.'));

          final histories = snapshot.data?.docs ?? [];
          histories.sort((a, b) => ((b.data() as Map<String, dynamic>)['date'] ?? Timestamp.now()).compareTo((a.data() as Map<String, dynamic>)['date'] ?? Timestamp.now()));

          if (histories.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle), child: Icon(Icons.medical_information_outlined, size: 80, color: Colors.teal.shade300)),
                    const SizedBox(height: 32),
                    const Text('Expediente en blanco', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkSlate)),
                    const SizedBox(height: 16),
                    const Text('Utiliza el botón inferior para grabar la primera consulta con Inteligencia Artificial.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Espacio para el FAB
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final data = histories[index].data() as Map<String, dynamic>;
              final Timestamp? timestamp = data['date'] as Timestamp?;
              final DateTime date = timestamp?.toDate() ?? DateTime.now();
              final String formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(data['diagnosis'] ?? 'Sin diagnóstico', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: -0.5))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)), child: Text(formattedDate, style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 12))),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _deleteClinicalNote(context, histories[index].id)),
                        ],
                      ),
                      const Divider(height: 32, thickness: 1),
                      _buildSectionTitle(Icons.flag, 'Objetivos'),
                      Text(data['objectives'] ?? 'Sin objetivos', style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.4)),
                      const SizedBox(height: 16),
                      _buildSectionTitle(Icons.personal_injury, 'Zonas de Dolor'),
                      Text(data['painZones'] ?? 'No especificadas', style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.4)),
                      const SizedBox(height: 24),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Ver transcripción y audio original', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                        children: [
                          if (data['audioUrl'] != null && data['audioUrl'].toString().isNotEmpty) CustomAudioPlayer(audioUrl: data['audioUrl']),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // EL NUEVO BOTÓN FLOTANTE PARA EVALUAR AQUÍ MISMO
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClinicalEvaluationScreen(patientId: patientId, patientName: patientName))),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.mic),
        label: const Text('Nueva Evaluación (IA)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }
}

// Reproductor de Audio Premium
class CustomAudioPlayer extends StatefulWidget {
  final String audioUrl;
  const CustomAudioPlayer({super.key, required this.audioUrl});

  @override
  State<CustomAudioPlayer> createState() => _CustomAudioPlayerState();
}

class _CustomAudioPlayerState extends State<CustomAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) { if (mounted) setState(() => _isPlaying = state == PlayerState.playing); });
    _audioPlayer.onDurationChanged.listen((newDuration) { if (mounted) setState(() => _duration = newDuration); });
    _audioPlayer.onPositionChanged.listen((newPosition) { if (mounted) setState(() => _position = newPosition); });
  }

  @override
  void dispose() { _audioPlayer.dispose(); super.dispose(); }

  String _formatDuration(Duration d) => "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF0F172A).withValues(alpha:0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          IconButton(icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill), color: const Color(0xFF0F172A), iconSize: 40, onPressed: () async { _isPlaying ? await _audioPlayer.pause() : await _audioPlayer.play(UrlSource(widget.audioUrl)); }),
          Expanded(child: Slider(activeColor: const Color(0xFF0F172A), inactiveColor: Colors.grey.shade300, min: 0, max: _duration.inSeconds.toDouble(), value: _position.inSeconds.toDouble(), onChanged: (value) async { await _audioPlayer.seek(Duration(seconds: value.toInt())); })),
          Text(_formatDuration(_position), style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Shimmer Premium
class ClinicalHistoryShimmer extends StatelessWidget {
  const ClinicalHistoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(height: 20, width: 200, color: Colors.white)),
            const Divider(height: 32),
            Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(height: 16, width: double.infinity, color: Colors.white)),
            const SizedBox(height: 12),
            Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(height: 16, width: 150, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}