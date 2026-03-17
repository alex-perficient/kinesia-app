import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class RoutineChartsScreen extends StatelessWidget {
  final String routineId;
  final String patientName;

  const RoutineChartsScreen({
    super.key,
    required this.routineId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolución Gráfica'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workout_logs')
            .where('routineId', isEqualTo: routineId)
            .orderBy('date', descending: false) // ASCENDENTE: Del pasado al presente
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }

          final logs = snapshot.data?.docs ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Text('Aún no hay suficientes datos\npara generar gráficas.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          // Variables para agrupar las coordenadas (Puntos en la gráfica)
          List<FlSpot> evaSpots = [];
          List<FlSpot> rpeSpots = [];
          
          double sessionIndex = 0; // El eje X será el número de sesión (1, 2, 3...)

          for (var doc in logs) {
            final data = doc.data() as Map<String, dynamic>;
            final eva = data['eva'];
            final rpe = data['rpe'];

            // Solo agregamos el punto si el paciente registró ese dato
            if (eva != null) evaSpots.add(FlSpot(sessionIndex, eva.toDouble()));
            if (rpe != null) rpeSpots.add(FlSpot(sessionIndex, rpe.toDouble()));
            
            sessionIndex++;
          }

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text('Paciente: $patientName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 24),

              // GRÁFICA 1: DOLOR (EVA)
              if (evaSpots.isNotEmpty) ...[
                const Text('Evolución del Dolor (EVA)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                const Text('Objetivo: Tendencia a la baja', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                _buildChartContainer(
                  spots: evaSpots,
                  lineColor: Colors.red,
                  gradientColors: [Colors.red.withValues(alpha: 0.3), Colors.red.withValues(alpha: 0.0)],
                  maxY: 10,
                ),
                const SizedBox(height: 40),
              ],

              // GRÁFICA 2: ESFUERZO (RPE)
              if (rpeSpots.isNotEmpty) ...[
                const Text('Esfuerzo Percibido (RPE)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                const Text('Objetivo: Estabilidad o adaptación', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                _buildChartContainer(
                  spots: rpeSpots,
                  lineColor: Colors.blue,
                  gradientColors: [Colors.blue.withValues(alpha: 0.3), Colors.blue.withValues(alpha: 0.0)],
                  maxY: 10,
                ),
              ],

              if (evaSpots.isEmpty && rpeSpots.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('El paciente no ha registrado métricas de Dolor o Esfuerzo en esta rutina aún.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Widget de diseño para enmarcar las gráficas de fl_chart
  Widget _buildChartContainer({required List<FlSpot> spots, required Color lineColor, required List<Color> gradientColors, required double maxY}) {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 24, left: 12, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1, // Ajustamos el eje X
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  // Mostramos el número de sesión en el eje X
                  return Text('S${(value + 1).toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 12));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: gradientColors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}