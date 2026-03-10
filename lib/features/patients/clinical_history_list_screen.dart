import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

class ClinicalHistoryListScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const ClinicalHistoryListScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expediente: $patientName'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clinical_histories')
            .where('patientId', isEqualTo: patientId)
            //.orderBy('date', descending: true) // Firebase requiere un índice para esto si hay muchos datos
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el expediente.'));
          }

          final histories = snapshot.data?.docs ?? [];
          // NUEVO: Ordenamiento local (más reciente primero)
          histories.sort((a, b) {
            final Timestamp tA = (a.data() as Map<String, dynamic>)['date'] ?? Timestamp.now();
            final Timestamp tB = (b.data() as Map<String, dynamic>)['date'] ?? Timestamp.now();
            return tB.compareTo(tA); 
          });

          if (histories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No hay evaluaciones clínicas registradas aún.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final data = histories[index].data() as Map<String, dynamic>;
              
              // Formateo de fecha
              final Timestamp? timestamp = data['date'] as Timestamp?;
              final DateTime date = timestamp?.toDate() ?? DateTime.now();
              final String formattedDate = '${date.day}/${date.month}/${date.year}';

              final String diagnosis = data['diagnosis'] ?? 'Sin diagnóstico';
              final String objectives = data['objectives'] ?? 'Sin objetivos';
              final String painZones = data['painZones'] ?? 'No especificadas';
              final String rawNotes = data['rawNotes'] ?? ''; // La transcripción original
              final String? audioUrl = data['audioUrl']; // Preparado para el futuro

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera: Fecha y Diagnóstico
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              diagnosis,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ),
                          Chip(
                            label: Text(formattedDate),
                            backgroundColor: Colors.teal.shade50,
                            labelStyle: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),

                      // Datos extraídos por la IA
                      _buildSectionTitle(Icons.flag, 'Objetivos'),
                      Text(objectives, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 16),

                      _buildSectionTitle(Icons.personal_injury, 'Zonas de Dolor'),
                      Text(painZones, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 24),

                      // Espacio para notas adicionales dinámicas (Petición del fisio)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.yellow.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.yellow.shade600)),
                        child: const Text('📝 Anotaciones adicionales: (Próximamente dinámicas)', style: TextStyle(color: Colors.brown, fontStyle: FontStyle.italic)),
                      ),
                      const SizedBox(height: 24),

                      // Acordeón para la Transcripción y el Audio
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Ver transcripción y audio original', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        children: [
                          if (audioUrl != null && audioUrl.isNotEmpty)
                          CustomAudioPlayer(audioUrl: audioUrl)
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
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}

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
    // Escuchamos los cambios del reproductor
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
            color: Colors.teal,
            iconSize: 36,
            onPressed: () async {
              if (_isPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.play(UrlSource(widget.audioUrl));
              }
            },
          ),
          Expanded(
            child: Slider(
              activeColor: Colors.teal,
              inactiveColor: Colors.teal.shade200,
              min: 0,
              max: _duration.inSeconds.toDouble(),
              value: _position.inSeconds.toDouble(),
              onChanged: (value) async {
                final position = Duration(seconds: value.toInt());
                await _audioPlayer.seek(position);
              },
            ),
          ),
          Text(
            _formatDuration(_position),
            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}