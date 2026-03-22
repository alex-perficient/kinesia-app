import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhysioExerciseBankScreen extends StatelessWidget {
  final bool isSelecting; // NUEVO: Para saber si estamos en modo "selección"

  const PhysioExerciseBankScreen({
    super.key,
    this.isSelecting = false, // Por defecto es false (solo lectura)
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
        title: Text(
          isSelecting ? 'SELECCIONA UN EJERCICIO' : 'BANCO DE EJERCICIOS',
          style: const TextStyle(
            color: Colors.tealAccent,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('global_exercises')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('El banco está vacío.'));
          }

          final exercises = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final doc = exercises[index];
              final exercise = doc.data() as Map<String, dynamic>;
              exercise['id'] = doc.id; // Guardamos el ID del documento

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  // NUEVO: Hacemos la tarjeta clickeable
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (isSelecting) {
                      // Si estamos armando una rutina, devolvemos este ejercicio a la pantalla anterior
                      Navigator.pop(context, exercise);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise['name'] ?? 'Sin nombre',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkSlate,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exercise['primaryMuscle'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isSelecting) // Indicador visual extra
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              Icons.add_circle,
                              color: Colors.teal,
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
