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
    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes de $patientName', style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('daily_logs')
            .where('patientId', isEqualTo: patientId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Falta crear el índice en Firebase para esta vista. Revisa tu consola.\nError: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final logs = snapshot.data?.docs ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'El paciente aún no ha enviado\nreportes de bienestar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;
              final int pain = log['generalPain'] ?? 0;
              final int fatigue = log['fatigue'] ?? 5;
              final String notes = log['notes'] ?? '';
              
              final Timestamp? timestamp = log['date'] as Timestamp?;
              String dateStr = 'Fecha desconocida';
              if (timestamp != null) {
                final date = timestamp.toDate();
                dateStr = DateFormat('EEEE d \'de\' MMMM, hh:mm a', 'es').format(date);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado con Fecha
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.teal.shade300),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateStr.toUpperCase(), 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700, fontSize: 12)
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      
                      // Métricas de Dolor y Fatiga
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              'Dolor', 
                              pain.toString(), 
                              pain > 6 ? Colors.red : (pain > 3 ? Colors.orange : Colors.green),
                              Icons.healing
                            ),
                          ),
                          Container(width: 1, height: 40, color: Colors.grey.shade300),
                          Expanded(
                            child: _buildMetricTile(
                              'Fatiga', 
                              fatigue.toString(), 
                              Colors.blue.shade400,
                              Icons.battery_charging_full
                            ),
                          ),
                        ],
                      ),
                      
                      // Notas
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text('"$notes"', style: TextStyle(color: Colors.grey.shade800, fontStyle: FontStyle.italic)),
                        ),
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

  // Widget de apoyo para dibujar el dolor y fatiga bonito
  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}