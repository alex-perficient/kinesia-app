import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_template_screen.dart';
import 'template_detail_screen.dart';


class RoutineLibraryScreen extends StatelessWidget {
  const RoutineLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Rutinas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('routine_templates')
            .where('physioId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError) {
            // Como acabamos de crear una consulta con "where" y "orderBy", 
            // Firebase nos va a pedir crear un índice la primera vez.
            debugPrint(snapshot.error.toString());
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar. Si es la primera vez, revisa la consola para crear el índice en Firebase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade300),
                ),
              ),
            );
          }

          final templates = snapshot.data?.docs ?? [];

          // ESTADO VACÍO: Look "Nike Training" con fotografía inyectada
          if (templates.isEmpty) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                // Inyectamos una foto profesional de Unsplash directo de la nube
                image: DecorationImage(
                  image: const NetworkImage('https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=2070&auto=format&fit=crop'), 
                  fit: BoxFit.cover,
                  // El truco mágico: Un cristal oscuro sobre la foto para que el texto sea legible
                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha:0.65), BlendMode.darken), 
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fitness_center, size: 64, color: Colors.white),
                    const SizedBox(height: 24),
                    const Text(
                      'Diseña el Éxito',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tu biblioteca está en blanco. Crea plantillas estándar de alto rendimiento para escalar tu impacto y asignarlas rápidamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    // Un botón blanco sólido que resalta sobre el fondo oscuro
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTemplateScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal.shade900,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear mi primera plantilla'),
                    )
                  ],
                ),
              ),
            );
          }

          // LISTA DE PLANTILLAS
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final data = templates[index].data() as Map<String, dynamic>;
              final String title = data['title'] ?? 'Sin título';
              final String description = data['description'] ?? '';
              final List exercises = data['exercises'] ?? [];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: const Icon(Icons.fitness_center, color: Colors.teal),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (description.isNotEmpty) Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text(
                        '${exercises.length} ejercicios',
                        style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
               onTap: () {
                 // AHORA SÍ NAVEGAMOS AL DETALLE
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => TemplateDetailScreen(
                       templateId: templates[index].id, // El ID de Firebase
                       title: title,
                       description: description,
                       exercises: exercises,
                     ),
                   ),
                 );
               },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // AHORA SÍ NAVEGAMOS AL FORMULARIO:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTemplateScreen()),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Plantilla'),
      ),
    );
  }
}