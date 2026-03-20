import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_template_screen.dart';
import 'template_detail_screen.dart';
import '../../features/patients/exercise_config_dialog.dart'; // ¡Importamos el diálogo que ya habías creado!

class RoutineLibraryScreen extends StatefulWidget {
  const RoutineLibraryScreen({super.key});

  @override
  State<RoutineLibraryScreen> createState() => _RoutineLibraryScreenState();
}

// Usamos SingleTickerProviderStateMixin para poder controlar las pestañas dinámicamente
class _RoutineLibraryScreenState extends State<RoutineLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isSavingExercise = false;

  @override
  void initState() {
    super.initState();
    // Inicializamos el controlador de 3 pestañas
    _tabController = TabController(length: 3, vsync: this);
    // Escuchamos cuando el usuario cambia de pestaña para redibujar el Botón Flotante
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.animation?.value == _tabController.index) {
        setState(() {}); 
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Función para guardar un ejercicio suelto en la base de datos
  Future<void> _saveCustomExercise(Map<String, dynamic> exerciseData) async {
    setState(() => _isSavingExercise = true);
    try {
      await FirebaseFirestore.instance.collection('custom_exercises').add({
        'physioId': currentUserId,
        ...exerciseData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio guardado en tu bóveda ✅'), backgroundColor: Colors.teal));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSavingExercise = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50, 
      appBar: AppBar(
        title: const Text('Biblioteca Maestra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController, // Conectamos el controlador
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'PLANTILLAS'),
            Tab(text: 'MIS EJERCICIOS'),
            Tab(text: 'KINES.IA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: Mis Plantillas
          _buildTemplatesTab(context, currentUserId, darkSlate),
          
          // PESTAÑA 2: Mis Ejercicios Sueltos
          _buildCustomExercisesTab(context, currentUserId, darkSlate),

          // PESTAÑA 3: Banco Kines.ia (Bloqueado para plan Free o en desarrollo)
          _buildComingSoonTab(
            icon: Icons.public,
            title: 'Banco Global Kines.ia',
            description: 'Estamos construyendo una base de datos con cientos de ejercicios grabados en alta calidad, categorizados por músculo y máquina, exclusivos para usuarios PRO.',
            color: Colors.blue,
          ),
        ],
      ),
      // BOTÓN FLOTANTE DINÁMICO
      floatingActionButton: _tabController.index == 2 
        ? null // No mostramos botón en la pestaña de Kines.ia (es de solo lectura)
        : FloatingActionButton.extended(
            onPressed: () async {
              if (_tabController.index == 0) {
                // Ir a crear plantilla
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTemplateScreen()));
              } else if (_tabController.index == 1) {
                // Abrir diálogo de ejercicio suelto
                final newExercise = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => const ExerciseConfigDialog(),
                );
                if (newExercise != null) {
                  _saveCustomExercise(newExercise);
                }
              }
            },
            backgroundColor: darkSlate,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: _isSavingExercise 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.add),
            label: Text(
              _tabController.index == 0 ? 'Nueva Plantilla' : 'Nuevo Ejercicio', 
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)
            ),
          ),
    );
  }

  // --- WIDGET PARA LA PESTAÑA 1 (Tus plantillas) ---
  Widget _buildTemplatesTab(BuildContext context, String currentUserId, Color darkSlate) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('routine_templates').where('physioId', isEqualTo: currentUserId).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
        if (snapshot.hasError) return Center(child: Text('Error al cargar.', style: TextStyle(color: Colors.red.shade300)));

        final templates = snapshot.data?.docs ?? [];

        if (templates.isEmpty) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/fondo_gym.jpg'),
                fit: BoxFit.cover,
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
                  const Text('Diseña el Éxito', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                  const SizedBox(height: 16),
                  const Text('Tu biblioteca está en blanco. Crea plantillas estándar de alto rendimiento para escalar tu impacto y asignarlas rápidamente.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final data = templates[index].data() as Map<String, dynamic>;
            final String title = data['title'] ?? 'Sin título';
            final String description = data['description'] ?? '';
            final List exercises = data['exercises'] ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle), child: const Icon(Icons.library_books, color: Colors.teal)),
                title: Text(title, style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkSlate, letterSpacing: -0.5)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    if (description.isNotEmpty) Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: darkSlate.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.fitness_center, size: 14, color: darkSlate),
                          const SizedBox(width: 6),
                          Text('${exercises.length} Ejercicios', style:  TextStyle(color: darkSlate, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle), child: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TemplateDetailScreen(templateId: templates[index].id, title: title, description: description, exercises: exercises))),
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGET PARA LA PESTAÑA 2 (Mis Ejercicios Sueltos) ---
  Widget _buildCustomExercisesTab(BuildContext context, String currentUserId, Color darkSlate) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('custom_exercises').where('physioId', isEqualTo: currentUserId).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
        if (snapshot.hasError) return Center(child: Text('Error al cargar.', style: TextStyle(color: Colors.red.shade300)));

        final exercises = snapshot.data?.docs ?? [];

        if (exercises.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.fitness_center, size: 64, color: Colors.orange)),
                  const SizedBox(height: 24),
                  const Text('Tu Bóveda de Ejercicios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  const Text('Guarda aquí configuraciones específicas (series, reps, tiempos) para agregarlas rápidamente a cualquier paciente o rutina.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final data = exercises[index].data() as Map<String, dynamic>;
            final String title = data['title'] ?? 'Sin nombre';
            final String reps = data['reps'] ?? '-';
            final String sets = data['sets'] ?? '-';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.fitness_center, color: Colors.orange, size: 20)),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('$sets Series • $reps Reps', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                     // Lógica simple de borrado
                     FirebaseFirestore.instance.collection('custom_exercises').doc(exercises[index].id).delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGET PARA LAS PESTAÑAS EN CONSTRUCCIÓN ---
  Widget _buildComingSoonTab({required IconData icon, required String title, required String description, required Color color}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 64, color: color)),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
            const SizedBox(height: 16),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
            const SizedBox(height: 32),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)), child: const Text('EN DESARROLLO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1))),
          ],
        ),
      ),
    );
  }
}