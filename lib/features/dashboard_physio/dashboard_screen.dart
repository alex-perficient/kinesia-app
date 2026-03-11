import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../patients/create_patient_screen.dart';
import '../patients/patient_profile_screen.dart';
import 'package:kinesia_app/features/notifications/notification_bell.dart';

class DashboardPhysioScreen extends StatelessWidget {
  const DashboardPhysioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el ID del usuario actualmente logueado
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kines.ia', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          NotificationBell(userId: currentUserId), // Usa la variable de tu fisio logueado
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // StreamBuilder "escucha" los cambios en el documento de este fisio en tiempo real
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('physiotherapists')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error al cargar la información del perfil.'));
          }

          // Extraemos los datos del documento
          final physioData = snapshot.data!.data() as Map<String, dynamic>;
          final String physioName = physioData['displayName'] ?? 'Fisio';
          final String plan = physioData['plan'] ?? 'free';
          final int patientCount = physioData['patientCount'] ?? 0;
          final int maxPatients = 15; // Límite del plan gratuito

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de Bienvenida y Estado del Plan
                Text(
                  'Hola, $physioName 👋',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // Tarjeta de Resumen
                Card(
                  elevation: 2,
                  color: plan == 'pro' ? Colors.teal.shade50 : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      plan == 'pro' ? Icons.star : Icons.account_circle,
                      color: plan == 'pro' ? Colors.amber : Colors.teal,
                      size: 40,
                    ),
                    title: Text(
                      plan == 'pro' ? 'Plan Pro Activo' : 'Plan Gratuito',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      plan == 'pro' 
                          ? 'Pacientes ilimitados y funciones IA' 
                          : '$patientCount / $maxPatients pacientes (Mejora a Pro para ilimitados)',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Título de la lista de pacientes
                const Text(
                  'Tus Pacientes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                
                // Placeholder temporal para la lista de pacientes
                // Lista Reactiva de Pacientes
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    // La consulta a Firestore: "Trae los pacientes que me pertenecen"
                    stream: FirebaseFirestore.instance
                        .collection('patients')
                        .where('physioId', isEqualTo: currentUserId)
                        // Por ahora no usamos .orderBy() para no forzar la creación manual de índices en Firebase
                        .snapshots(),
                    builder: (context, patientSnapshot) {
                      // 1. Mientras carga la primera vez
                      if (patientSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // 2. Si hay un error de conexión o permisos
                      if (patientSnapshot.hasError) {
                        return const Center(
                          child: Text('Error al cargar la lista de pacientes.', style: TextStyle(color: Colors.red)),
                        );
                      }

                      // 3. Extraemos la lista de documentos
                      final patientDocs = patientSnapshot.data?.docs ?? [];

                      // 4. Si la consulta está vacía (0 pacientes)
                      if (patientDocs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aún no tienes pacientes registrados.\nToca el botón + para empezar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      // 5. Si hay pacientes, construimos la lista (ListView)
                      return ListView.builder(
                        itemCount: patientDocs.length,
                        itemBuilder: (context, index) {
                          // Extraemos los datos de cada paciente
                          final patientData = patientDocs[index].data() as Map<String, dynamic>;
                          final String patientId = patientDocs[index].id; // ¡Agrega esta línea clave!
                          final String name = patientData['fullName'] ?? 'Sin nombre';
                          final String status = patientData['status'] ?? 'active';

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade100,
                                radius: 24,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.teal, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20
                                  ),
                                ),
                              ),
                              title: Text(
                                name, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    status == 'active' ? Icons.check_circle : Icons.cancel,
                                    size: 16,
                                    color: status == 'active' ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status == 'active' ? 'Activo' : 'Inactivo',
                                    style: TextStyle(color: status == 'active' ? Colors.green : Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () {
                             // Navegamos al perfil pasando el ID y el Nombre
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => PatientProfileScreen(
                                   patientId: patientId,
                                   patientName: name,
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
          );
        },
      ),
      // Botón Flotante para agregar pacientes (por ahora no hace nada)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegamos a la pantalla de crear paciente
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePatientScreen()),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}