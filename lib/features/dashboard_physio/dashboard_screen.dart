import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../patients/create_patient_screen.dart';
import '../patients/patient_profile_screen.dart';
import 'package:kinesia_app/features/notifications/notification_bell.dart';
import 'package:shimmer/shimmer.dart';

class DashboardPhysioScreen extends StatefulWidget {
  const DashboardPhysioScreen({super.key});

  @override
  State<DashboardPhysioScreen> createState() => _DashboardPhysioScreenState();
}

class _DashboardPhysioScreenState extends State<DashboardPhysioScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos'; 

  late Stream<DocumentSnapshot> _physioStream;
  late Stream<QuerySnapshot> _patientsStream;

  @override
  void initState() {
    super.initState();
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
    // Colores SaaS Premium
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Fondo ultra limpio para la lista
      appBar: AppBar(
        title: const Text('Centro de Mando', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          NotificationBell(userId: currentUserId),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar Sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _physioStream, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error al cargar la información del perfil.'));
          }

          final physioData = snapshot.data!.data() as Map<String, dynamic>;
          final String physioName = physioData['displayName'] ?? 'Especialista';
          // Tomamos solo el primer nombre para el saludo
          final String shortName = physioName.split(' ')[0];
          final String plan = physioData['plan'] ?? 'free';
          final int patientCount = physioData['patientCount'] ?? 0;
          final int maxPatients = 15;

          return Column(
            children: [
              // 1. EL HEADER OSCURO TIPO SaaS (Stripe/Vercel)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                decoration: const BoxDecoration(
                  color: darkSlate,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $shortName 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const SizedBox(height: 24),
                    
                    // TARJETAS DE KPIs (Métricas Clave)
                    Row(
                      children: [
                        // KPI 1: Pacientes Activos
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pacientes Activos', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text('$patientCount', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                    Text(plan == 'pro' ? '' : ' / $maxPatients', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // KPI 2: Estado del Plan
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: plan == 'pro' ? Colors.amber.withValues(alpha: 0.2) : Colors.teal.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: plan == 'pro' ? Colors.amber.withValues(alpha: 0.5) : Colors.teal.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Licencia Actual', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(plan == 'pro' ? Icons.star : Icons.verified, color: plan == 'pro' ? Colors.amber : Colors.tealAccent, size: 24),
                                    const SizedBox(width: 8),
                                    Text(plan == 'pro' ? 'PRO' : 'GRATUITA', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. ÁREA DE BÚSQUEDA Y LISTA (Fondo Claro)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      // BARRA DE BÚSQUEDA MODERNA
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Buscar paciente por nombre...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          // Sombra sutil
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CHIPS DE FILTRO ELEGANTES
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Todos', 'Clínica', 'Fitness'].map((String filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: isSelected,
                                selectedColor: darkSlate,
                                showCheckmark: false,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: isSelected ? darkSlate : Colors.grey.shade300),
                                ),
                                onSelected: (bool selected) => setState(() => _selectedFilter = filter),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // LA LISTA DE PACIENTES
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _patientsStream, 
                          builder: (context, patientSnapshot) {
                            if (patientSnapshot.connectionState == ConnectionState.waiting) {
                              return ListView.builder(itemCount: 4, itemBuilder: (context, index) => const PatientCardShimmer());
                            }

                            if (patientSnapshot.hasError) {
                              return const Center(child: Text('Error al cargar la lista de pacientes.', style: TextStyle(color: Colors.red)));
                            }

                            final patientDocs = patientSnapshot.data?.docs ?? [];

                            final filteredDocs = patientDocs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data['fullName'] ?? '').toString().toLowerCase();
                              final String patientType = data['patientType'] ?? 'Clínica';
                              final matchesSearch = name.contains(_searchQuery);
                              final matchesFilter = _selectedFilter == 'Todos' || patientType == _selectedFilter;
                              return matchesSearch && matchesFilter;
                            }).toList();

                            // EMPTY STATE 1: Cero pacientes en BD
                            if (patientDocs.isEmpty) {
                              return Center(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                                        child: const Icon(Icons.people_alt_outlined, size: 64, color: Colors.teal),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text('Tu panel está listo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkSlate)),
                                      const SizedBox(height: 12),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                                        child: Text(
                                          'Agrega a tu primer paciente para comenzar a crear planes de rehabilitación de alto impacto.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // EMPTY STATE 2: Búsqueda sin resultados
                            if (filteredDocs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text('No encontramos a "$_searchQuery"', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                                  ],
                                ),
                              );
                            }

                            // LISTA DE PACIENTES PREMIUM
                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
                              itemCount: filteredDocs.length, 
                              itemBuilder: (context, index) {
                                final patientData = filteredDocs[index].data() as Map<String, dynamic>;
                                final String patientId = filteredDocs[index].id;
                                final String name = patientData['fullName'] ?? 'Sin nombre';
                                final String patientType = patientData['patientType'] ?? 'Clínica';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade100),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: darkSlate,
                                      radius: 24,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                      ),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkSlate, letterSpacing: -0.5)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: patientType == 'Fitness' ? Colors.orange.shade50 : Colors.teal.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              patientType.toUpperCase(),
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: patientType == 'Fitness' ? Colors.orange.shade700 : Colors.teal.shade700),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.circle, color: Colors.green, size: 10),
                                          const SizedBox(width: 4),
                                          const Text('Activo', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
                                      child: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                                    ),
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
                ),
              ),
            ],
          );
        },
      ),
      // BOTÓN FLOTANTE EXTENDIDO PREMIUM
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePatientScreen()));
        },
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Paciente', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }
}

class PatientCardShimmer extends StatelessWidget {
  const PatientCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: const CircleAvatar(radius: 24, backgroundColor: Colors.white),
        ),
        title: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: Container(height: 16, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
        ),
        subtitle: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: Container(height: 12, width: 100, margin: const EdgeInsets.only(top: 8, right: 100), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
        ),
      ),
    );
  }
}