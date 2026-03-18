import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientLogsHistoryScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const PatientLogsHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reportes de Bienestar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('daily_logs').where('patientId', isEqualTo: patientId).orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text('Falta índice en Firebase.\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))));

          final logs = snapshot.data?.docs ?? [];

          if (logs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), const Text('Sin reportes de bienestar.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkSlate))]));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;
              final int pain = log['generalPain'] ?? 0;
              final int fatigue = log['fatigue'] ?? 5;
              final String notes = log['notes'] ?? '';
              
              final Timestamp? timestamp = log['date'] as Timestamp?;
              String dateStr = timestamp != null ? DateFormat('EEEE d \'de\' MMMM, hh:mm a', 'es').format(timestamp.toDate()) : 'Fecha desconocida';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.calendar_today, size: 16, color: Colors.teal.shade300), const SizedBox(width: 8), Expanded(child: Text(dateStr.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal.shade700, fontSize: 12)))]),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(child: _buildMetricTile('Dolor', pain.toString(), pain > 6 ? Colors.red : (pain > 3 ? Colors.orange : Colors.green), Icons.healing)),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          Expanded(child: _buildMetricTile('Fatiga', fatigue.toString(), Colors.blue.shade400, Icons.battery_charging_full)),
                        ],
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)), child: Text('"$notes"', style: TextStyle(color: Colors.grey.shade800, fontStyle: FontStyle.italic, height: 1.4))),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, height: 1.1)),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}