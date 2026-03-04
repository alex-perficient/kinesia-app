import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PatientRoutineScreen extends StatelessWidget {
  final String routineId;

  const PatientRoutineScreen({super.key, required this.routineId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Rutina de Rehabilitación'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Usamos FutureBuilder porque el paciente solo necesita leer la rutina al entrar, 
        // no necesitamos escuchar cambios en tiempo real minuto a minuto aquí.
        future: FirebaseFirestore.instance.collection('routines').doc(routineId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error al cargar la rutina.'));
          }

          final routineData = snapshot.data!.data() as Map<String, dynamic>;
          final List exercises = routineData['exercises'] ?? [];
          final String title = routineData['title'] ?? 'Rutina';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.teal.shade50,
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Lista de ejercicios restringida a tamaño de celular
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 400, // <--- Esto simula el ancho de un celular
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index] as Map<String, dynamic>;
                        return _ExerciseCard(exercise: exercise, index: index);
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Sub-componente para aislar la lógica de cada reproductor de YouTube
class _ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final int index;

  const _ExerciseCard({required this.exercise, required this.index});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  YoutubePlayerController? _controller;
  bool _isUrlValid = true;

  @override
  void initState() {
    super.initState();
    final url = widget.exercise['youtubeUrl'] ?? '';
    // Extraemos el ID del video de la URL completa (ej. watch?v=XXXXX -> XXXXX)
    final videoId = YoutubePlayer.convertUrlToId(url);

    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false, // ¡Crucial para no gastar datos!
          mute: false,
        ),
      );
    } else {
      _isUrlValid = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Liberar memoria al hacer scroll
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Área del Video
          if (_isUrlValid && _controller != null)
            YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
            )
          else
            Container(
              height: 200,
              color: Colors.grey.shade300,
              child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
            ),
            
          // Información del Ejercicio
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.index + 1}. ${widget.exercise['title'] ?? 'Ejercicio'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBadge(Icons.repeat, '${widget.exercise['sets']} Series'),
                    _buildStatBadge(Icons.tag, '${widget.exercise['reps']} Reps'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Botón para marcar como completado (Por ahora visual)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Excelente trabajo! Ejercicio completado.')),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Marcar como completado'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }
}