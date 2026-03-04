import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_routine_screen.dart'; // Para crear la rutina
import '../patient_view/patient_routine_screen.dart'; // Para ver la rutina (Atajo temporal)

class PatientProfileScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const PatientProfileScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil: $patientName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de la sección de rutinas
            const Text(
              'Rutinas Asignadas',
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error al cargar las rutinas.', style: TextStyle(color: Colors.red)),
                    );
                  }

                  final routineDocs = snapshot.data?.docs ?? [];

                  if (routineDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Este paciente aún no tiene rutinas asignadas.\nToca el botón para crear su primera rutina de rehabilitación.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: routineDocs.length,
                    itemBuilder: (context, index) {
                      final routineData = routineDocs[index].data() as Map<String, dynamic>;
                      final String title = routineData['title'] ?? 'Rutina sin título';
                      final bool isActive = routineData['isActive'] ?? false;
                      
                      // Como guardamos los ejercicios en un arreglo, podemos saber cuántos son fácilmente
                      final List exercises = routineData['exercises'] ?? [];
                      final String routineId = routineDocs[index].id;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isActive ? Colors.teal.shade100 : Colors.grey.shade200,
                            child: Icon(
                              Icons.fitness_center,
                              color: isActive ? Colors.teal : Colors.grey,
                            ),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${exercises.length} ejercicios asignados'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
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
                            // Vamos a la vista de la rutina del paciente
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientRoutineScreen(routineId: routineId),
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