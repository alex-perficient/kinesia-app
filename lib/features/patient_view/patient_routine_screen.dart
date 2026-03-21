import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_tracking_screen.dart';

class PatientRoutineScreen extends StatelessWidget {
  final String routineId;
  final String patientName;

  const PatientRoutineScreen({
    super.key,
    required this.routineId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: darkSlate,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: const Text(
            'MI RUTINA DEL DÍA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('routines')
            .doc(routineId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Esta rutina ya no está disponible.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final routineData = snapshot.data!.data() as Map<String, dynamic>;
          final List exercises = routineData['exercises'] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                color: darkSlate,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: const Text(
                    'Tu plan está\nlisto 💪',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: exercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.do_not_disturb_on_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tu fisio aún no ha cargado ejercicios.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise =
                              exercises[index] as Map<String, dynamic>;
                          final title =
                              exercise['title'] ??
                              exercise['name'] ??
                              'Ejercicio';
                          final reps = exercise['reps'] ?? 0;
                          final sets = exercise['sets'] ?? 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: darkSlate,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.repeat,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$sets Series  ×  $reps Reps',
                                        style: const TextStyle(
                                          color: darkSlate,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.play_circle_fill,
                                color: Colors.tealAccent,
                                size: 36,
                              ), // ¡Invitación visual a tocar!
                              // NAVEGACIÓN INDIVIDUAL AL TOCAR LA TARJETA
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ExerciseTrackingScreen(
                                          exercise: exercise,
                                          routineId: routineId,
                                          patientName: patientName,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),

              // BOTÓN INFERIOR: COMIENZA EL PRIMER EJERCICIO
              if (exercises.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        // Pasamos el primer ejercicio (índice 0)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseTrackingScreen(
                              exercise: exercises[0],
                              routineId: routineId,
                              patientName: patientName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent.shade400,
                        foregroundColor: darkSlate,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'COMENZAR ENTRENAMIENTO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
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
