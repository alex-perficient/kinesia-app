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

  // 👇 TRIAGE CONECTADO A FIREBASE
  Widget _buildTriageSection(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false) // Solo mostramos las no leídas
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          );
        }

        // ✅ CÓDIGO NUEVO (El Filtro Inteligente):
        final allNotifications = snapshot.data?.docs ?? [];

        // Filtramos en memoria para que el Triage SOLO muestre las urgentes o advertencias
        final alerts = allNotifications.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] ?? 'general';
          return type == 'urgent' || type == 'warning';
        }).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Atención Requerida',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 140,
              child: alerts.isEmpty
                  ? _buildAllClearCard() // Si no hay alertas, mostramos tarjeta verde
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final data =
                            alerts[index].data() as Map<String, dynamic>;
                        final docId = alerts[index].id;

                        // Diseño dinámico según la urgencia
                        Color alertColor = data['type'] == 'urgent'
                            ? Colors.redAccent
                            : Colors.orange;
                        IconData alertIcon = data['type'] == 'urgent'
                            ? Icons.warning
                            : Icons.notifications_active;

                        return _buildAlertCard(
                          icon: alertIcon,
                          color: alertColor,
                          title: data['title'] ?? 'Alerta',
                          alertText:
                              data['body'] ?? 'Tienes una nueva notificación.',
                          onTap: () {
                            // Al tocar la tarjeta en el Triage, la marcamos como leída y desaparece
                            FirebaseFirestore.instance
                                .collection('notifications')
                                .doc(docId)
                                .update({'isRead': true});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Alerta marcada como atendida'),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // Tarjeta de "Todo bien" cuando la bandeja está vacía
  Widget _buildAllClearCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Todo bajo control',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'No hay alertas urgentes pendientes.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required Color color,
    required String title,
    required String alertText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              alertText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            child: Text(
              'Atender alerta →',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Centro de Mando',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
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
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text('Error al cargar perfil.'));
          }

          final physioData = snapshot.data!.data() as Map<String, dynamic>;
          final String physioName = physioData['displayName'] ?? 'Especialista';
          final String shortName = physioName.split(' ')[0];
          final String plan = physioData['plan'] ?? 'free';
          final int patientCount = physioData['patientCount'] ?? 0;
          final int maxPatients = 15;

          return CustomScrollView(
            slivers: [
              // 1. HEADER COMPACTADO (Sliver)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pacientes Activos',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$patientCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        plan == 'pro' ? '' : ' / $maxPatients',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (plan != 'pro') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PaywallScreen(),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: plan == 'pro'
                                      ? Colors.amber.withValues(alpha: 0.15)
                                      : Colors.teal.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: plan == 'pro'
                                        ? Colors.amber.withValues(alpha: 0.5)
                                        : Colors.teal.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Licencia Actual',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          plan == 'pro'
                                              ? Icons.star
                                              : Icons.verified,
                                          color: plan == 'pro'
                                              ? Colors.amber
                                              : Colors.tealAccent,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          plan == 'pro' ? 'PRO' : 'GRATUITA',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
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
              ),

              // 2. EL CENTRO DE TRIAGE (Alertas)
              SliverToBoxAdapter(child: _buildTriageSection(currentUserId)),

              // 3. BUSCADOR Y FILTROS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expedientes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: darkSlate,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(
                            () => _searchQuery = value.toLowerCase(),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar paciente...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Todos', 'Clínica', 'Fitness'].map((
                            String filter,
                          ) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  filter,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                selected: isSelected,
                                selectedColor: darkSlate,
                                showCheckmark: false,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? darkSlate
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                onSelected: (bool selected) =>
                                    setState(() => _selectedFilter = filter),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. LISTA DE PACIENTES
              StreamBuilder<QuerySnapshot>(
                stream: _patientsStream,
                builder: (context, patientSnapshot) {
                  if (patientSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: PatientCardShimmer(),
                        ),
                        childCount: 4,
                      ),
                    );
                  }
                  if (patientSnapshot.hasError) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          'Error al cargar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  final patientDocs = patientSnapshot.data?.docs ?? [];
                  final filteredDocs = patientDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['fullName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final String patientType = data['patientType'] ?? 'Clínica';
                    return name.contains(_searchQuery) &&
                        (_selectedFilter == 'Todos' ||
                            patientType == _selectedFilter);
                  }).toList();

                  if (patientDocs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Text(
                            'Agrega a tu primer paciente 🏥',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      100,
                    ), // Espacio para FAB
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final patientData =
                            filteredDocs[index].data() as Map<String, dynamic>;
                        final String patientId = filteredDocs[index].id;
                        final String name =
                            patientData['fullName'] ?? 'Sin nombre';
                        final String patientType =
                            patientData['patientType'] ?? 'Clínica';

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
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: darkSlate,
                              radius: 24,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: darkSlate,
                                letterSpacing: -0.5,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: patientType == 'Fitness'
                                          ? Colors.orange.shade50
                                          : Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      patientType.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: patientType == 'Fitness'
                                            ? Colors.orange.shade700
                                            : Colors.teal.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 16,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientProfileScreen(
                                  patientId: patientId,
                                  patientName: name,
                                ),
                              ),
                            ),
                          ),
                        );
                      }, childCount: filteredDocs.length),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePatientScreen()),
        ),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Nuevo Paciente',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: const CircleAvatar(radius: 24, backgroundColor: Colors.white),
        ),
        title: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        subtitle: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: Container(
            height: 12,
            width: 80,
            margin: const EdgeInsets.only(top: 10, right: 100),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
