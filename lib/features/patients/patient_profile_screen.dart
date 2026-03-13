import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import '../notifications/notification_bell.dart';
import 'create_routine_screen.dart'; // Para crear la rutina
import 'physio_routine_detail_screen.dart';
import 'clinical_evaluation_screen.dart';
import 'clinical_history_list_screen.dart';
import 'package:shimmer/shimmer.dart';

class PatientProfileScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const PatientProfileScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  Future<void> _archivePatient(BuildContext context) async {
    // 1. Mostrar diálogo de confirmación por seguridad
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Dar de alta / Archivar paciente?'),
        content: const Text(
          'El paciente ya no aparecerá en tu lista principal.\n\n'
          '💡 Nota importante: Su expediente, audios y datos clínicos seguirán resguardados en la nube por seguridad médica. Por lo tanto, archivar a un paciente no libera espacios de tu cuota actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Archivar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    // 2. Si el fisio confirma, hacemos el Soft Delete
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .update({'status': 'archived'});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente archivado correctamente.')),
          );
          // 3. Lo regresamos al Dashboard automáticamente
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al archivar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil: $patientName'),
        //title: Text('Perfil del Paciente'),
        actions: [
          // ¡Aquí inyectamos nuestra campanita inteligente!
          //  NotificationBell(userId: patientId), // Asegúrate de pasarle el ID real del usuario
          // Botón para archivar paciente
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            color: Colors
                .red
                .shade200, // Un color sutil para no asustar, pero indicar precaución
            tooltip: 'Archivar paciente',
            onPressed: () => _archivePatient(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NUEVO BOTÓN PARA EVALUACIÓN CLÍNICA
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClinicalEvaluationScreen(
                        patientId: patientId,
                        patientName: patientName,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.teal, width: 2),
                ),
                icon: const Icon(Icons.assignment_ind, color: Colors.teal),
                label: const Text(
                  'Nueva Evaluación Clínica',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ... (Aquí termina tu botón anterior de Nueva Evaluación Clínica) ...
            const SizedBox(height: 12), // Espacio entre botones
            // NUEVO BOTÓN: Ver Expediente Clínico
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClinicalHistoryListScreen(
                        patientId: patientId,
                        patientName: patientName,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal.shade50,
                ),
                icon: const Icon(Icons.folder_shared, color: Colors.teal),
                label: const Text(
                  'Ver Expediente Clínico',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Rutinas Asignadas',
              // ... (El resto de tu código continúa igual) ...
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // Placeholder temporal para la lista de rutinas
            // Lista Reactiva de Rutinas
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Consultamos la colección 'routines' filtrando por este paciente en específico
                stream: FirebaseFirestore.instance
                    .collection('routines')
                    .where('patientId', isEqualTo: patientId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 4, // 4 rutinas fantasma
                      itemBuilder: (context, index) =>
                          const RoutineCardShimmer(),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error al cargar las rutinas.',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final routineDocs = snapshot.data?.docs ?? [];

                  //  if (routineDocs.isEmpty) {
                  // Empty State de las Rutinas
                  if (routineDocs.isEmpty) {
                    // Asegúrate de usar el nombre de tu variable de lista aquí
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fitness_center, // Ícono de ejercicio
                                size: 80,
                                color: Colors.teal.shade300,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Sin plan de rehabilitación',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Es momento de poner a este paciente en movimiento. Toca el botón de agregar para diseñar su primera rutina de ejercicios personalizados.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                height: 1.5,
                              ),
                            ),
                            // Opcional: Si en esta pantalla TIENES un FloatingActionButton,
                            // puedes pegar aquí el mismo código de la flecha que usamos en el Dashboard.
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 32.0),
                                child: Transform.rotate(
                                  // Rota la flecha hacia abajo a la derecha (↘)
                                  angle: -0.5,
                                  child: Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 48,
                                    color: Colors.teal.shade200,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: routineDocs.length,
                    itemBuilder: (context, index) {
                      final routineData =
                          routineDocs[index].data() as Map<String, dynamic>;
                      final String title =
                          routineData['title'] ?? 'Rutina sin título';
                      final bool isActive = routineData['isActive'] ?? false;

                      // Como guardamos los ejercicios en un arreglo, podemos saber cuántos son fácilmente
                      final List exercises = routineData['exercises'] ?? [];
                      final String routineId = routineDocs[index].id;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? Colors.teal.shade100
                                : Colors.grey.shade200,
                            child: Icon(
                              Icons.fitness_center,
                              color: isActive ? Colors.teal : Colors.grey,
                            ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${exercises.length} ejercicios asignados',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Activa' : 'Inactiva',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          onTap: () {
                            // Ahora el fisio ve el detalle administrativo de su rutina
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhysioRoutineDetailScreen(
                                  routineData: routineData,
                                  routineId: routineId,
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
            ),
          ],
        ),
      ),
      // Botón extendido para dejar muy clara la acción principal
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateRoutineScreen(
                patientId: patientId,
                patientName: patientName,
              ),
            ),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.fitness_center),
        label: const Text('Nueva Rutina'),
      ),
    );
  }
}

// NUEVO: El molde animado para las Rutinas
class RoutineCardShimmer extends StatelessWidget {
  const RoutineCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        title: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 16,
            width: double.infinity,
            color: Colors.white,
          ),
        ),
        subtitle: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 14,
            width: 150,
            color: Colors.white,
            margin: const EdgeInsets.only(top: 8),
          ),
        ),
      ),
    );
  }
}
