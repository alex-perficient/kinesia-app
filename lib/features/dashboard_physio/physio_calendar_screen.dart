import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart'; 
import '../patients/patient_profile_screen.dart';

class PhysioCalendarScreen extends StatefulWidget {
  const PhysioCalendarScreen({super.key});

  @override
  State<PhysioCalendarScreen> createState() => _PhysioCalendarScreenState();
}

class _PhysioCalendarScreenState extends State<PhysioCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    const Color darkSlate = Color(0xFF0F172A); // Color corporativo

    final targetDate = _selectedDay ?? _focusedDay;
    final startOfDay = Timestamp.fromDate(DateTime(targetDate.year, targetDate.month, targetDate.day));
    final endOfDay = Timestamp.fromDate(DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59));

    final workoutStream = FirebaseFirestore.instance
        .collection('workout_logs')
        .where('physioId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots();

    final dailyLogStream = FirebaseFirestore.instance
        .collection('daily_logs')
        .where('physioId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        // CABECERA DARK SLATE UNIFICADA
        title: const Text('Agenda Global', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white70),
            tooltip: 'Volver a hoy',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // CALENDARIO
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: TableCalendar(
              locale: 'es_ES',
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.teal.shade200, shape: BoxShape.circle),
                selectedDecoration: const BoxDecoration(color: darkSlate, shape: BoxShape.circle), // Selección en Dark Slate
                markerDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
                CalendarFormat.twoWeeks: '2 Sem',
                CalendarFormat.week: 'Semana',
              },
            ),
          ),
          
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // LÍNEA DE TIEMPO UNIFICADA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: workoutStream,
              builder: (context, workoutSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: dailyLogStream,
                  builder: (context, dailySnapshot) {
                    
                    if (workoutSnapshot.connectionState == ConnectionState.waiting || dailySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.teal));
                    }

                    final workoutDocs = workoutSnapshot.data?.docs ?? [];
                    final dailyDocs = dailySnapshot.data?.docs ?? [];
                    final allLogs = [...workoutDocs, ...dailyDocs];

                    if (allLogs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 20)]),
                              child: Icon(Icons.event_busy, size: 64, color: Colors.teal.shade200),
                            ),
                            const SizedBox(height: 24),
                            const Text('Agenda Despejada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkSlate)),
                            const SizedBox(height: 8),
                            const Text('No hay registros de pacientes en este día.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    allLogs.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;
                      final Timestamp timeA = dataA['date'] ?? Timestamp.now();
                      final Timestamp timeB = dataB['date'] ?? Timestamp.now();
                      return timeB.compareTo(timeA); 
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: allLogs.length,
                      itemBuilder: (context, index) {
                        final logData = allLogs[index].data() as Map<String, dynamic>;
                        
                        if (logData.containsKey('exerciseName')) {
                          return TimelineCard(log: logData);
                        } else {
                          return DailyLogCard(log: logData);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// WIDGET 1: TARJETA DE EJERCICIOS (SaaS Style)
// ------------------------------------------------------------------------
class TimelineCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const TimelineCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final String patientId = log['patientId'] ?? '';
    final String exerciseName = log['exerciseName'] ?? 'Ejercicio';
    final int? rpe = log['rpe'];
    final int? eva = log['eva'];
    
    final Timestamp? timestamp = log['date'] as Timestamp?;
    String timeStr = '--:--';
    if (timestamp != null) {
      final date = timestamp.toDate();
      timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
      builder: (context, snapshot) {
        String patientName = 'Cargando...';
        if (snapshot.hasData && snapshot.data!.exists) {
          patientName = snapshot.data!.get('fullName') ?? 'Paciente';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (snapshot.hasData && snapshot.data!.exists) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PatientProfileScreen(patientId: patientId, patientName: patientName)));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.fitness_center, size: 16, color: Colors.teal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)))),
                      Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Completó: $exerciseName', style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (rpe != null) 
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Text('RPE: $rpe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700))),
                      if (eva != null) 
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Text('EVA: $eva', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------------------
// WIDGET 2: TARJETA DE BITÁCORA (SaaS Style)
// ------------------------------------------------------------------------
class DailyLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const DailyLogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final String patientId = log['patientId'] ?? '';
    final int pain = log['generalPain'] ?? 0;
    final int fatigue = log['fatigue'] ?? 5;
    final String notes = log['notes'] ?? '';
    
    final Timestamp? timestamp = log['date'] as Timestamp?;
    String timeStr = '--:--';
    if (timestamp != null) {
      final date = timestamp.toDate();
      timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
      builder: (context, snapshot) {
        String patientName = 'Cargando...';
        if (snapshot.hasData && snapshot.data!.exists) {
          patientName = snapshot.data!.get('fullName') ?? 'Paciente';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade100),
            boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (snapshot.hasData && snapshot.data!.exists) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PatientProfileScreen(patientId: patientId, patientName: patientName)));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.mood, size: 16, color: Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)))),
                      Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Registró su bitácora diaria', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.healing, size: 16, color: pain > 6 ? Colors.red : Colors.green),
                      const SizedBox(width: 4),
                      Text('Dolor: $pain', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      const Icon(Icons.battery_charging_full, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('Fatiga: $fatigue', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text('"$notes"', style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic, fontSize: 13)),
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}