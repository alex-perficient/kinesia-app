import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'create_routine_screen.dart';
import 'physio_routine_detail_screen.dart';
import 'clinical_history_list_screen.dart';
import 'select_template_screen.dart';
import 'patient_logs_history_screen.dart';
import '../patient_view/patient_diet_screen.dart';
import 'create_diet_screen.dart';
import '../dashboard_physio/routine_builder_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientProfileScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientProfileScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<QuerySnapshot> _routinesStream;
  late Stream<QuerySnapshot> _workoutLogsStream;
  late Stream<QuerySnapshot> _dailyLogsStream;

  // 👇 SOLUCIÓN AL ERROR: Declaramos la variable de alertas aquí
  List<DocumentSnapshot> _alerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    _routinesStream = FirebaseFirestore.instance
        .collection('routines')
        .where('patientId', isEqualTo: widget.patientId)
        .where('isActive', isEqualTo: true)
        .snapshots();
    _workoutLogsStream = FirebaseFirestore.instance
        .collection('workout_logs')
        .where('patientId', isEqualTo: widget.patientId)
        .orderBy('date', descending: true)
        .snapshots();
    _dailyLogsStream = FirebaseFirestore.instance
        .collection('daily_logs')
        .where('patientId', isEqualTo: widget.patientId)
        .orderBy('date', descending: true)
        .snapshots();

    // 👇 SOLUCIÓN AL ERROR: Iniciamos la escucha de alertas al abrir la pantalla
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Menú inferior para crear rutinas
  void _showCreateRoutineOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¿Cómo deseas crear la rutina?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: const Icon(Icons.library_books, color: Colors.teal),
                  ),
                  title: const Text(
                    'Desde una Plantilla',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Usa una rutina pre-armada de tu biblioteca',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectTemplateScreen(
                          patientId: widget.patientId,
                          patientName: widget.patientName,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: const Icon(Icons.build, color: Colors.orange),
                  ),
                  title: const Text(
                    'Armar desde el Banco (Nueva)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Selecciona ejercicios individuales'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoutineBuilderScreen(
                          patientId: widget.patientId,
                          patientName: widget.patientName,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.edit, color: Colors.blue),
                  ),
                  title: const Text(
                    'Manual (Desde cero)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Escribe tus propios ejercicios libremente',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateRoutineScreen(
                          patientId: widget.patientId,
                          patientName: widget.patientName,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Cargar alertas del paciente
  void _loadAlerts() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('alerts')
        .where('patientId', isEqualTo: widget.patientId)
        .where('isResolved', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _alerts = snapshot.docs;
            });
          }
        });
  }

  // Resolver alerta
  Future<void> _resolveAlert(String alertId) async {
    try {
      await FirebaseFirestore.instance.collection('alerts').doc(alertId).update(
        {'isResolved': true, 'resolvedAt': FieldValue.serverTimestamp()},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Alerta resuelta.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al resolver: $e')));
      }
    }
  }

  // 👇 FUNCIÓN V19 RECUPERADA: Dar de Alta / Archivar
  Future<void> _confirmArchivePatient(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.archive, color: Colors.orange),
            SizedBox(width: 8),
            Text('¿Dar de Alta?'),
          ],
        ),
        content: const Text(
          'El expediente se archivará y desaparecerá de tu lista principal de pacientes activos. \n\n'
          'Nota: Los pacientes archivados siguen contando para tu límite de licencias gratuitas por motivos de almacenamiento clínico.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Archivar Paciente',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .update({'status': 'inactive'});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente archivado exitosamente.'),
              backgroundColor: Colors.teal,
            ),
          );
          Navigator.of(context).pop(); // Regresa al Dashboard
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
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.patientName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // 1. Alertas
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Alertas Activas'),
                      content: _alerts.isEmpty
                          ? const Text(
                              'Todo en orden. El paciente está siguiendo el plan.',
                            )
                          : SizedBox(
                              width: double.maxFinite,
                              height: 300,
                              child: ListView.builder(
                                itemCount: _alerts.length,
                                itemBuilder: (context, index) {
                                  final alert =
                                      _alerts[index].data()
                                          as Map<String, dynamic>;
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                    ),
                                    title: Text(alert['title'] ?? 'Alerta'),
                                    subtitle: Text(
                                      '${alert['body']}\n${DateFormat('dd/MM HH:mm').format((alert['timestamp'] as Timestamp).toDate())}',
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () =>
                                          _resolveAlert(_alerts[index].id),
                                      child: const Text('Resolver'),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  );
                },
              ),
              if (_alerts.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      _alerts.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // 2. Triage IA
          IconButton(
            icon: const Icon(Icons.science_outlined, color: Colors.white),
            tooltip: 'Analizar Riesgo (Triage)',
            onPressed: () {}, // Lógica de IA a futuro
          ),

          // 👇 3. BOTÓN V19 RECUPERADO: Archivar (3 Puntos)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'archive') {
                _confirmArchivePatient(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(
                      Icons.archive_outlined,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Dar de Alta (Archivar)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'RUTINAS'),
            Tab(text: 'NUTRICIÓN'),
            Tab(text: 'HISTORIAL'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRoutinesTab(darkSlate),
          _buildNutritionTab(darkSlate),
          _buildHistoryTab(darkSlate),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: Colors.tealAccent.shade400,
              icon: const Icon(Icons.add, color: Color(0xFF0F172A)),
              label: const Text(
                'Crear Rutina',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _showCreateRoutineOptions(context),
            )
          : null,
    );
  }

  // --- PESTAÑA 1: RUTINAS ---
  Widget _buildRoutinesTab(Color darkSlate) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _routinesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_edu,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sin rutinas activas.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final routine = docs[index].data() as Map<String, dynamic>;
                  final String routineId = docs[index].id;

                  return Dismissible(
                    key: Key(routineId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: const Icon(
                        Icons.archive_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('¿Archivar Rutina?'),
                          content: const Text(
                            'Esta rutina desaparecerá de la app del paciente, pero los entrenamientos pasados se conservarán en el historial.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Archivar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      FirebaseFirestore.instance
                          .collection('routines')
                          .doc(routineId)
                          .update({'isActive': false});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rutina archivada exitosamente'),
                        ),
                      );
                    },
                    child: Container(
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
                          horizontal: 20,
                          vertical: 8,
                        ),
                        title: Text(
                          routine['routineName'] ??
                              routine['title'] ??
                              'Rutina',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: darkSlate,
                            letterSpacing: -0.5,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${(routine['exercises'] ?? []).length} ejercicios asignados',
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
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
                            builder: (context) => PhysioRoutineDetailScreen(
                              routineData: routine,
                              routineId: routineId,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- PESTAÑA 2: NUTRICIÓN ---
  Widget _buildNutritionTab(Color darkSlate) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant, size: 64, color: Colors.green),
          ),
          const SizedBox(height: 24),
          Text(
            'Módulo de Nutrición',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: darkSlate,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Diseña y asigna planes alimenticios personalizados o revisa la dieta activa de tu paciente en tiempo real.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 15),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateDietScreen(
                    patientId: widget.patientId,
                    patientName: widget.patientName,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Asignar Nueva Dieta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PatientDietScreen(patientId: widget.patientId),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.visibility),
              label: const Text(
                'Ver Dieta Activa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PESTAÑA 3: HISTORIAL CLÍNICO ---
  Widget _buildHistoryTab(Color darkSlate) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClinicalHistoryListScreen(
                        patientId: widget.patientId,
                        patientName: widget.patientName,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.folder_shared),
                  label: const Text(
                    'Expediente Clínico e IA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade50,
                    foregroundColor: Colors.teal.shade800,
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientLogsHistoryScreen(
                        patientId: widget.patientId,
                        patientName: widget.patientName,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Ver Reportes de Bienestar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade200),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _workoutLogsStream,
            builder: (context, workoutSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: _dailyLogsStream,
                builder: (context, dailySnapshot) {
                  if (workoutSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      dailySnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    );
                  }

                  final allLogs = [
                    ...(workoutSnapshot.data?.docs ?? []),
                    ...(dailySnapshot.data?.docs ?? []),
                  ];
                  if (allLogs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timeline,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'El historial de actividad está en blanco.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  allLogs.sort(
                    (a, b) =>
                        ((b.data() as Map<String, dynamic>)['date'] ??
                                Timestamp.now())
                            .compareTo(
                              (a.data() as Map<String, dynamic>)['date'] ??
                                  Timestamp.now(),
                            ),
                  );

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: allLogs.length,
                    itemBuilder: (context, index) {
                      final logData =
                          allLogs[index].data() as Map<String, dynamic>;
                      final Timestamp? timestamp =
                          logData['date'] as Timestamp?;
                      String dateStr = timestamp != null
                          ? '${timestamp.toDate().day.toString().padLeft(2, '0')}/${timestamp.toDate().month.toString().padLeft(2, '0')}/${timestamp.toDate().year}'
                          : '--/--';

                      if (logData.containsKey('exerciseName')) {
                        final bool isCardio = logData['type'] == 'cardio';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCardio
                                    ? Colors.blue.shade50
                                    : Colors.teal.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCardio
                                    ? Icons.directions_run
                                    : Icons.fitness_center,
                                size: 16,
                                color: isCardio ? Colors.blue : Colors.teal,
                              ),
                            ),
                            title: Text(
                              logData['exerciseName'] ?? 'Ejercicio',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: darkSlate,
                                letterSpacing: -0.5,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                isCardio
                                    ? '${(logData['distanceKm'] ?? 0).toStringAsFixed(2)} km • ${logData['pace'] ?? ''}'
                                    : 'Entrenamiento de fuerza',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                            trailing: Text(
                              dateStr,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mood,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                            title: Text(
                              'Check-in Diario',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: darkSlate,
                                letterSpacing: -0.5,
                              ),
                            ),
                            subtitle: const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Bienestar',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            trailing: Text(
                              dateStr,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
