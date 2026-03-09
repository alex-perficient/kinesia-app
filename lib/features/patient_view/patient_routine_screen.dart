import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'exercise_tracking_screen.dart';

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
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.teal.shade50,
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 400, // Mantiene el tamaño tipo celular que definimos
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index] as Map<String, dynamic>;
                        return _ExerciseCard(exercise: exercise, index: index, routineId: routineId);
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

class _ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final int index;
  final String routineId;

  const _ExerciseCard({required this.exercise, required this.index,required this.routineId});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late YoutubePlayerController _controller;
  bool _isUrlValid = true;
  String? _videoId;
  bool _showVideo = false; // NUEVO: Controla si mostramos la imagen o el reproductor

  @override
  void initState() {
    super.initState();
    final url = widget.exercise['youtubeUrl'] ?? '';
    
    // Extraemos el ID del video
    try {
      final uri = Uri.parse(url);
      if (uri.queryParameters.containsKey('v')) {
        _videoId = uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        _videoId = uri.pathSegments.first;
      }
    } catch (e) {
      _videoId = null;
    }

    if (_videoId != null && _videoId!.isNotEmpty) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: _videoId!,
        autoPlay: true, // Ahora sí autoplay=true, porque solo se inicializa cuando el usuario toca la imagen
        params: const YoutubePlayerParams(
          showControls: true,
          mute: false,
          showFullscreenButton: true,
          loop: false,
        ),
      );
    } else {
      _isUrlValid = false;
    }
  }

  @override
  void dispose() {
    if (_showVideo && _isUrlValid) {
      _controller.close();
    }
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
          // ÁREA VISUAL OPTIMIZADA: Miniatura vs Video Real
          if (!_isUrlValid)
            Container(
              height: 200,
              color: Colors.grey.shade300,
              child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
            )
          else if (!_showVideo)
            // Mostramos solo la imagen (thumbnail) para no gastar memoria
            GestureDetector(
              onTap: () {
                setState(() {
                  _showVideo = true; // Al tocar, cargamos el reproductor pesado
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    'https://img.youtube.com/vi/$_videoId/hqdefault.jpg',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.video_library, size: 50, color: Colors.grey)),
                    ),
                  ),
                  // Capa oscura y botón de Play falso para invitar al clic
                  Container(
                    height: 200,
                    color: Colors.black45,
                  ),
                  const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                ],
              ),
            )
          else
            // El reproductor real de YouTube (solo existe si _showVideo es true)
            YoutubePlayer(
              controller: _controller,
              backgroundColor: Colors.black,
            ),
            
          // INFORMACIÓN DEL EJERCICIO
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navegamos a la pantalla de captura
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExerciseTrackingScreen(
                            exercise: widget.exercise,
                            routineId: widget.routineId, 
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Registrar mis series'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (Conserva tu método _buildStatBadge igual que antes)

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