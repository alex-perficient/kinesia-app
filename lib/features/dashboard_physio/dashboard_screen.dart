import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../patients/create_patient_screen.dart';
import '../patients/patient_profile_screen.dart';
import 'package:kinesia_app/features/notifications/notification_bell.dart';
import 'package:shimmer/shimmer.dart';
import 'paywall_screen.dart'; 

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

    _physioStream = FirebaseFirestore.instance.collection('physiotherapists').doc(currentUserId).snapshots();
    _patientsStream = FirebaseFirestore.instance.collection('patients').where('physioId', isEqualTo: currentUserId).where('status', isEqualTo: 'active').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50, 
      appBar: AppBar(
        title: const Text('Centro de Mando', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          NotificationBell(userId: currentUserId),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white70), tooltip: 'Cerrar Sesión', onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _physioStream, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Error al cargar perfil.'));

          final physioData = snapshot.data!.data() as Map<String, dynamic>;
          final String physioName = physioData['displayName'] ?? 'Especialista';
          final String shortName = physioName.split(' ')[0];
          final String plan = physioData['plan'] ?? 'free';
          final int patientCount = physioData['patientCount'] ?? 0;
          final int maxPatients = 15;

          return Column(
            children: [
              // 1. HEADER COMPACTADO (Menos padding, fuentes más optimizadas)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: const BoxDecoration(
                  color: darkSlate,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hola, $shortName 👋', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12), // Reducido
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pacientes Activos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text('$patientCount', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                    Text(plan == 'pro' ? '' : ' / $maxPatients', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12), // Reducido
                        
                        Expanded(
                          child: GestureDetector(
                            onTap: () { if (plan != 'pro') Navigator.push(context, MaterialPageRoute(builder: (context) => const PaywallScreen())); },
                            child: Container(
                              padding: const EdgeInsets.all(12), // Reducido
                              decoration: BoxDecoration(color: plan == 'pro' ? Colors.amber.withValues(alpha: 0.2) : Colors.teal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: plan == 'pro' ? Colors.amber.withValues(alpha: 0.5) : Colors.teal.withValues(alpha: 0.5))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Licencia Actual', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(plan == 'pro' ? Icons.star : Icons.verified, color: plan == 'pro' ? Colors.amber : Colors.tealAccent, size: 20),
                                      const SizedBox(width: 6),
                                      Text(plan == 'pro' ? 'PRO' : 'GRATUITA', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. LISTA DE PACIENTES OPTIMIZADA
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Reducido
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        height: 45, // Barra de búsqueda más delgada
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Buscar paciente...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 20), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
                            filled: true, fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Todos', 'Clínica', 'Fitness'].map((String filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(filter, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                selectedColor: darkSlate,
                                showCheckmark: false,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected ? darkSlate : Colors.grey.shade300)),
                                onSelected: (bool selected) => setState(() => _selectedFilter = filter),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _patientsStream, 
                          builder: (context, patientSnapshot) {
                            if (patientSnapshot.connectionState == ConnectionState.waiting) return ListView.builder(itemCount: 4, itemBuilder: (context, index) => const PatientCardShimmer());
                            if (patientSnapshot.hasError) return const Center(child: Text('Error al cargar', style: TextStyle(color: Colors.red)));

                            final patientDocs = patientSnapshot.data?.docs ?? [];
                            final filteredDocs = patientDocs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data['fullName'] ?? '').toString().toLowerCase();
                              final String patientType = data['patientType'] ?? 'Clínica';
                              return name.contains(_searchQuery) && (_selectedFilter == 'Todos' || patientType == _selectedFilter);
                            }).toList();

                            if (patientDocs.isEmpty) return const Center(child: Text('Agrega a tu primer paciente', style: TextStyle(color: Colors.grey)));

                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80), 
                              itemCount: filteredDocs.length, 
                              itemBuilder: (context, index) {
                                final patientData = filteredDocs[index].data() as Map<String, dynamic>;
                                final String patientId = filteredDocs[index].id;
                                final String name = patientData['fullName'] ?? 'Sin nombre';
                                final String patientType = patientData['patientType'] ?? 'Clínica';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8), // Reducido
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16), // Reducido
                                    border: Border.all(color: Colors.grey.shade100),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Mucho más compacto
                                    leading: CircleAvatar(backgroundColor: darkSlate, radius: 20, child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkSlate, letterSpacing: -0.5)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: patientType == 'Fitness' ? Colors.orange.shade50 : Colors.teal.shade50, borderRadius: BorderRadius.circular(6)),
                                            child: Text(patientType.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: patientType == 'Fitness' ? Colors.orange.shade700 : Colors.teal.shade700)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PatientProfileScreen(patientId: patientId, patientName: name))),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePatientScreen())),
        backgroundColor: darkSlate, foregroundColor: Colors.white, elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nuevo Paciente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}

class PatientCardShimmer extends StatelessWidget {
  const PatientCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Shimmer.fromColors(baseColor: Colors.grey.shade200, highlightColor: Colors.grey.shade50, child: const CircleAvatar(radius: 20, backgroundColor: Colors.white)),
        title: Shimmer.fromColors(baseColor: Colors.grey.shade200, highlightColor: Colors.grey.shade50, child: Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
        subtitle: Shimmer.fromColors(baseColor: Colors.grey.shade200, highlightColor: Colors.grey.shade50, child: Container(height: 10, width: 80, margin: const EdgeInsets.only(top: 8, right: 100), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
      ),
    );
  }
}