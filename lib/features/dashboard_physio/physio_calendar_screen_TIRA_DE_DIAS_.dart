import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../patients/patient_profile_screen.dart';

// 1. AHORA ES UN STATEFUL WIDGET PARA MANEJAR EL DÍA SELECCIONADO
class PhysioCalendarScreen extends StatefulWidget {
  const PhysioCalendarScreen({super.key});

  @override
  State<PhysioCalendarScreen> createState() => _PhysioCalendarScreenState();
}

class _PhysioCalendarScreenState extends State<PhysioCalendarScreen> {
  // 2. LA VARIABLE MÁGICA: El día que el fisio está viendo (por defecto, hoy)
  DateTime _selectedDate = DateTime.now();
  
  // Generamos una lista de los últimos 30 días para nuestro calendario horizontal
  late List<DateTime> _pastDays;

  @override
  void initState() {
    super.initState();
    // Llenamos la lista con los últimos 30 días (del más antiguo al día de hoy)
    _pastDays = List.generate(30, (index) {
      return DateTime.now().subtract(Duration(days: 29 - index));
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // 3. CALCULAMOS EL INICIO Y EL FIN DEL DÍA SELECCIONADO PARA FIREBASE
    final startOfDay = Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day));
    final endOfDay = Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59));

    // 1. Preparamos las dos consultas a Firebase
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
      appBar: AppBar(
        title: const Text('Actividad Global', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
        actions: [
          // QUICK WIN: Botón para saltar al día de hoy al instante
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Volver a hoy',
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
          ),
        ],
      ),
      body: Column(
        children: [
          // LA TIRA DEL CALENDARIO (Intacta)
          Container(
            color: Colors.white,
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              // Le decimos a la lista que empiece al final (en el día de hoy)
              controller: ScrollController(initialScrollOffset: 30 * 70.0), 
              itemCount: _pastDays.length,
              itemBuilder: (context, index) {
                final date = _pastDays[index];
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 65,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300),
                      boxShadow: isSelected 
                        ? [BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                        : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          // Extraemos el día de la semana abreviado (ej. "Lun")
                          DateFormat('E', 'es').format(date).toUpperCase(),
                          style: TextStyle(color: isSelected ? Colors.teal.shade100 : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 2. LA MAGIA: ANIDAMOS LOS DOS STREAMS
          Expanded(
            child: Container(
              color: Colors.grey.shade50, // Fondo un poco más gris para dar contraste
              child: StreamBuilder<QuerySnapshot>(
                stream: workoutStream,
                builder: (context, workoutSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: dailyLogStream,
                    builder: (context, dailySnapshot) {
                      
                      if (workoutSnapshot.connectionState == ConnectionState.waiting || dailySnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.teal));
                      }

                      if (workoutSnapshot.hasError || dailySnapshot.hasError) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Requiere Índice de Firebase para daily_logs.\nAbre tu consola y haz clic en el enlace azul en los logs.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      // 3. JUNTAMOS AMBAS LISTAS Y LAS ORDENAMOS POR HORA DESCENDENTE
                      final workoutDocs = workoutSnapshot.data?.docs ?? [];
                      final dailyDocs = dailySnapshot.data?.docs ?? [];
                      
                      final allLogs = [...workoutDocs, ...dailyDocs];

// ESTADO VACÍO: Si ese día nadie hizo nada
                      if (allLogs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 80, color: Colors.teal.shade100),
                              const SizedBox(height: 16),
                              Text('No hay actividad el ${_selectedDate.day}/${_selectedDate.month}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        );
                      }

                      // Ordenar la lista combinada (lo más reciente arriba)
                      allLogs.sort((a, b) {
                        final dataA = a.data() as Map<String, dynamic>;
                        final dataB = b.data() as Map<String, dynamic>;
                        final Timestamp timeA = dataA['date'] ?? Timestamp.now();
                        final Timestamp timeB = dataB['date'] ?? Timestamp.now();
                        return timeB.compareTo(timeA); 
                      });

                      // 4. DIBUJAMOS LA TARJETA CORRECTA SEGÚN EL TIPO DE DOCUMENTO
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: allLogs.length,
                        itemBuilder: (context, index) {
                          final logData = allLogs[index].data() as Map<String, dynamic>;
                          
                          // Si tiene 'exerciseName', es una rutina. Si tiene 'generalPain', es un diario.
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
              ), // Cierra el StreamBuilder
            ), // Cierra el Container gris
          ), // Cierra el Expanded
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// WIDGET 1: Tarjeta para los ejercicios completados (Intacta)
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
    
    // Formatear la fecha
    final Timestamp? timestamp = log['date'] as Timestamp?;
    String timeStr = 'Hora desconocida';
    if (timestamp != null) {
      final date = timestamp.toDate();
      timeStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // Buscamos el nombre del paciente en tiempo real
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
      builder: (context, snapshot) {
        String patientName = 'Cargando...';
        if (snapshot.hasData && snapshot.data!.exists) {
          patientName = snapshot.data!.get('fullName') ?? 'Paciente Desconocido';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.teal.shade100, width: 1)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Navegar al perfil del paciente al tocar la tarjeta
              if (snapshot.hasData && snapshot.data!.exists) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PatientProfileScreen(patientId: patientId, patientName: patientName)));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 14, backgroundColor: Colors.teal.shade50, child: const Icon(Icons.fitness_center, size: 14, color: Colors.teal)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Completó: $exerciseName', style: TextStyle(color: Colors.grey.shade800, fontSize: 15)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (rpe != null) Chip(label: Text('RPE: $rpe', style: TextStyle(fontSize: 11, color: Colors.blue.shade900)), backgroundColor: Colors.blue.shade50, side: BorderSide.none, padding: EdgeInsets.zero),
                      if (eva != null) Chip(label: Text('EVA: $eva', style: TextStyle(fontSize: 11, color: Colors.red.shade900)), backgroundColor: Colors.red.shade50, side: BorderSide.none, padding: EdgeInsets.zero),
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
// WIDGET 2: NUEVA Tarjeta para la Bitácora de Bienestar
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
    String timeStr = 'Hora desconocida';
    if (timestamp != null) {
      final date = timestamp.toDate();
      timeStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
      builder: (context, snapshot) {
        String patientName = 'Cargando...';
        if (snapshot.hasData && snapshot.data!.exists) {
          patientName = snapshot.data!.get('fullName') ?? 'Paciente';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade100, width: 1)),
          color: Colors.orange.shade50.withValues(alpha: 0.3),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (snapshot.hasData && snapshot.data!.exists) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PatientProfileScreen(patientId: patientId, patientName: patientName)));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 14, backgroundColor: Colors.orange.shade100, child: const Icon(Icons.mood, size: 14, color: Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Registró su bitácora diaria', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.healing, size: 16, color: pain > 6 ? Colors.red : Colors.green),
                      const SizedBox(width: 4),
                      Text('Dolor: $pain', style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 16),
                      Icon(Icons.battery_charging_full, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('Fatiga: $fatigue', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('"$notes"', style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic, fontSize: 13)),
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