import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // NUEVO: Para dar formato a las fechas (ej. "Lun", "Mar")
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
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 4. EL NUEVO CALENDARIO HORIZONTAL
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
                  onTap: () {
                    setState(() {
                      _selectedDate = date; // ¡Actualizamos el día seleccionado!
                    });
                  },
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
                          style: TextStyle(
                            color: isSelected ? Colors.teal.shade100 : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 5. LA LÍNEA DE TIEMPO (AHORA FILTRADA POR FECHA)
          Expanded(
            child: Container(
              color: Colors.grey.shade50, // Fondo un poco más gris para dar contraste
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('workout_logs')
                    .where('physioId', isEqualTo: currentUserId)
                    // Filtramos específicamente por el día que el fisio tocó
                    .where('date', isGreaterThanOrEqualTo: startOfDay)
                    .where('date', isLessThanOrEqualTo: endOfDay)
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
                          'Requiere Índice de Firebase.\nAbre tu consola, haz clic en el enlace azul y créalo.\n\nError: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      ),
                    );
                  }

                  final logs = snapshot.data?.docs ?? [];

                  // ESTADO VACÍO: Si ese día nadie hizo nada
                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 80, color: Colors.teal.shade100),
                          const SizedBox(height: 16),
                          Text(
                            // CORRECCIÓN: Usamos _selectedDate
                            'No hay actividad el ${_selectedDate.day}/${_selectedDate.month}',
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  // Si hay datos, dibujamos las tarjetas de la línea de tiempo
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index].data() as Map<String, dynamic>;
                      return TimelineCard(log: log); 
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

// Widget personalizado para cada evento en la línea de tiempo
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
      timeStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // Buscamos el nombre del paciente en tiempo real
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
      builder: (context, snapshot) {
        String patientName = 'Cargando paciente...';
        if (snapshot.hasData && snapshot.data!.exists) {
          patientName = snapshot.data!.get('fullName') ?? 'Paciente Desconocido';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.teal.shade100, width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Navegar al perfil del paciente al tocar la tarjeta
              if (snapshot.hasData && snapshot.data!.exists) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientProfileScreen(
                      patientId: patientId,
                      patientName: patientName,
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.teal.shade50,
                        child: const Icon(Icons.person, size: 16, color: Colors.teal),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          patientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Completó: $exerciseName',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  
                  // Chips de métricas granulares si existen
                  if (rpe != null || eva != null)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (rpe != null)
                          Chip(
                            label: Text('RPE: $rpe', style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.blue.shade50,
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                          ),
                        if (eva != null)
                          Chip(
                            label: Text('EVA: $eva', style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.red.shade50,
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                          ),
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
