import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_routine_screen.dart'; 
import 'physio_routine_detail_screen.dart';
import 'clinical_history_list_screen.dart';
import 'select_template_screen.dart';
import 'patient_logs_history_screen.dart';
import '../patient_view/patient_diet_screen.dart';
import 'create_diet_screen.dart'; // Agrega esta línea

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

// Cambiamos a 3 pestañas
class _PatientProfileScreenState extends State<PatientProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<QuerySnapshot> _routinesStream;
  late Stream<QuerySnapshot> _workoutLogsStream;
  late Stream<QuerySnapshot> _dailyLogsStream;

  @override
  void initState() {
    super.initState();
    // AHORA SON 3 TABS
    _tabController = TabController(length: 3, vsync: this);

    _routinesStream = FirebaseFirestore.instance.collection('routines').where('patientId', isEqualTo: widget.patientId).where('isActive', isEqualTo: true).snapshots();
    _workoutLogsStream = FirebaseFirestore.instance.collection('workout_logs').where('patientId', isEqualTo: widget.patientId).orderBy('date', descending: true).snapshots();
    _dailyLogsStream = FirebaseFirestore.instance.collection('daily_logs').where('patientId', isEqualTo: widget.patientId).orderBy('date', descending: true).snapshots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text(widget.patientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 12),
          // NUEVAS PESTAÑAS
          tabs: const [Tab(text: 'RUTINAS'), Tab(text: 'NUTRICIÓN'), Tab(text: 'HISTORIAL')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRoutinesTab(darkSlate), 
          _buildNutritionTab(darkSlate), // NUEVA PESTAÑA
          _buildHistoryTab(darkSlate)
        ],
      ),
    );
  }

  // --- PESTAÑA 1: RUTINAS ---
  Widget _buildRoutinesTab(Color darkSlate) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SelectTemplateScreen(patientId: widget.patientId, patientName: widget.patientName))), icon: const Icon(Icons.library_books, size: 16), label: const Text('Plantilla', style: TextStyle(fontSize: 13)), style: OutlinedButton.styleFrom(foregroundColor: darkSlate, side: BorderSide(color: Colors.grey.shade300)))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateRoutineScreen(patientId: widget.patientId, patientName: widget.patientName))), icon: const Icon(Icons.edit, size: 16), label: const Text('Manual', style: TextStyle(fontSize: 13)), style: OutlinedButton.styleFrom(foregroundColor: Colors.teal.shade700, side: BorderSide(color: Colors.teal.shade100)))),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _routinesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_edu, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('Sin rutinas activas.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16))]));

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final routine = docs[index].data() as Map<String, dynamic>;
                  final String routineId = docs[index].id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(routine['title'] ?? 'Rutina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkSlate, letterSpacing: -0.5)),
                      subtitle: Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('${(routine['exercises'] ?? []).length} ejercicios asignados', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600))),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PhysioRoutineDetailScreen(routineData: routine, routineId: routineId))),
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

  // --- PESTAÑA 2: NUTRICIÓN (NUEVA) ---
  Widget _buildNutritionTab(Color darkSlate) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: const Icon(Icons.restaurant, size: 64, color: Colors.green)),
          const SizedBox(height: 24),
          Text('Módulo de Nutrición', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: -0.5)),
          const SizedBox(height: 16),
          const Text('Diseña y asigna planes alimenticios personalizados o revisa la dieta activa de tu paciente en tiempo real.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 15)),
          const SizedBox(height: 40),
          
          SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // ¡EL CONECTOR FINAL!
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CreateDietScreen(patientId: widget.patientId, patientName: widget.patientName)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
                icon: const Icon(Icons.add),
                label: const Text('Asignar Nueva Dieta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PatientDietScreen(patientId: widget.patientId))),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.green.shade700, side: BorderSide(color: Colors.green.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: const Icon(Icons.visibility),
              label: const Text('Ver Dieta Activa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClinicalHistoryListScreen(patientId: widget.patientId, patientName: widget.patientName))),
                  icon: const Icon(Icons.folder_shared),
                  label: const Text('Expediente Clínico e IA', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade50, foregroundColor: Colors.teal.shade800, elevation: 0),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PatientLogsHistoryScreen(patientId: widget.patientId, patientName: widget.patientName))),
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Ver Reportes de Bienestar'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade700, side: BorderSide(color: Colors.orange.shade200)),
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
                  if (workoutSnapshot.connectionState == ConnectionState.waiting || dailySnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
                  final allLogs = [...(workoutSnapshot.data?.docs ?? []), ...(dailySnapshot.data?.docs ?? [])];
                  if (allLogs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.timeline, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('El historial de actividad está en blanco.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16))]));

                  allLogs.sort((a, b) => ((b.data() as Map<String, dynamic>)['date'] ?? Timestamp.now()).compareTo((a.data() as Map<String, dynamic>)['date'] ?? Timestamp.now()));

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: allLogs.length,
                    itemBuilder: (context, index) {
                      final logData = allLogs[index].data() as Map<String, dynamic>;
                      final Timestamp? timestamp = logData['date'] as Timestamp?;
                      String dateStr = timestamp != null ? '${timestamp.toDate().day.toString().padLeft(2, '0')}/${timestamp.toDate().month.toString().padLeft(2, '0')}/${timestamp.toDate().year}' : '--/--';

                      if (logData.containsKey('exerciseName')) {
                        return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle), child: const Icon(Icons.fitness_center, size: 16, color: Colors.teal)), title: Text(logData['exerciseName'] ?? 'Ejercicio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkSlate, letterSpacing: -0.5)), subtitle: const Padding(padding: EdgeInsets.only(top: 4.0), child: Text('Entrenamiento', style: TextStyle(color: Colors.grey))), trailing: Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))));
                      } else {
                        return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade100)), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Icon(Icons.mood, size: 16, color: Colors.orange)), title: Text('Check-in Diario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkSlate, letterSpacing: -0.5)), subtitle: const Padding(padding: EdgeInsets.only(top: 4.0), child: Text('Bienestar', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13))), trailing: Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))));
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