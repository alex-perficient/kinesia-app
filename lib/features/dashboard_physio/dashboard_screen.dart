import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../patients/create_patient_screen.dart';
import '../patients/patient_profile_screen.dart';
import 'package:kinesia_app/features/notifications/notification_bell.dart';
import 'package:shimmer/shimmer.dart';

// 1. CAMBIO CLAVE: Ahora es un StatefulWidget para poder usar la barra de búsqueda
class DashboardPhysioScreen extends StatefulWidget {
  const DashboardPhysioScreen({super.key});

  @override
  State<DashboardPhysioScreen> createState() => _DashboardPhysioScreenState();
}

class _DashboardPhysioScreenState extends State<DashboardPhysioScreen> {
  // 2. VARIABLES DE BÚSQUEDA
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // NUEVO: Variables para guardar la conexión a Firebase
  late Stream<DocumentSnapshot> _physioStream;
  late Stream<QuerySnapshot> _patientsStream;

  @override
  void initState() {
    super.initState();
    // Preparamos las conexiones UNA SOLA VEZ
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    _physioStream = FirebaseFirestore.instance
        .collection('physiotherapists')
        .doc(currentUserId)
        .snapshots();
        
    _patientsStream = FirebaseFirestore.instance
        .collection('patients')
        .where('physioId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kines.ia', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          NotificationBell(userId: currentUserId),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _physioStream, // ¡Mucho más limpio! //FirebaseFirestore.instance.collection('physiotherapists').doc(currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error al cargar la información del perfil.'));
          }

          final physioData = snapshot.data!.data() as Map<String, dynamic>;
          final String physioName = physioData['displayName'] ?? 'Fisio';
          final String plan = physioData['plan'] ?? 'free';
          final int patientCount = physioData['patientCount'] ?? 0;
          final int maxPatients = 15;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $physioName 👋', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

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

                const Text('Tus Pacientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),

                // 3. LA BARRA DE BÚSQUEDA
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar paciente...',
                      prefixIcon: const Icon(Icons.search, color: Colors.teal),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _patientsStream, // ¡Aquí también! FirebaseFirestore.instance //ya se coloco al inicio el resto del codigo
                    builder: (context, patientSnapshot) {
                      if (patientSnapshot.connectionState == ConnectionState.waiting) {
                        // Mostramos 4 tarjetas fantasma animadas mientras carga
                        return ListView.builder(
                          itemCount: 4,
                          itemBuilder: (context, index) => const PatientCardShimmer(),
                        );
                      }

                      if (patientSnapshot.hasError) {
                        return const Center(child: Text('Error al cargar la lista de pacientes.', style: TextStyle(color: Colors.red)));
                      }

                      final patientDocs = patientSnapshot.data?.docs ?? [];

                      // 4. EL FILTRO LOCAL MÁGICO
                      final filteredDocs = patientDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['fullName'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();

                      // Estado 1: Absolutamente 0 pacientes en la base de datos (Tu Empty State)
                      if (patientDocs.isEmpty) {
                        return Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                                  child: Icon(Icons.group_add_outlined, size: 80, color: Colors.teal.shade300),
                                ),
                                const SizedBox(height: 32),
                                const Text('Tu consultorio está listo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aún no tienes pacientes activos en tu lista. Toca el botón en la esquina inferior derecha para registrar a tu primer paciente y comenzar a estructurar expedientes con Inteligencia Artificial.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                                ),
                                const SizedBox(height: 40),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 32.0),
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Icon(Icons.arrow_downward_rounded, size: 48, color: Colors.teal.shade200),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Estado 2: Hay pacientes, pero la búsqueda no arrojó resultados
                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('No se encontró a "$_searchQuery"', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        );
                      }

                      // Estado 3: Mostrar la lista filtrada
                      return ListView.builder(
                        itemCount: filteredDocs.length, // Usamos la lista filtrada
                        itemBuilder: (context, index) {
                          final patientData = filteredDocs[index].data() as Map<String, dynamic>;
                          final String patientId = filteredDocs[index].id;
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
                                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Row(
                                children: [
                                  Icon(status == 'active' ? Icons.check_circle : Icons.cancel, size: 16, color: status == 'active' ? Colors.green : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(status == 'active' ? 'Activo' : 'Inactivo', style: TextStyle(color: status == 'active' ? Colors.green : Colors.grey)),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => PatientProfileScreen(patientId: patientId, patientName: name)));
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePatientScreen()));
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// NUEVO: El molde animado para los Shimmers
class PatientCardShimmer extends StatelessWidget {
  const PatientCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: const CircleAvatar(radius: 24, backgroundColor: Colors.white),
        ),
        title: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(height: 16, width: double.infinity, color: Colors.white),
        ),
        subtitle: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 12, 
            width: 100, 
            color: Colors.white, 
            margin: const EdgeInsets.only(top: 8, right: 100) // Margen para que se vea más corto que el título
          ),
        ),
      ),
    );
  }
}