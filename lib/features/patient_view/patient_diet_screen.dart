import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDietScreen extends StatelessWidget {
  final String patientId;

  const PatientDietScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mi Plan Nutricional', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('nutrition_plans')
            .where('patientId', isEqualTo: patientId)
            .where('isActive', isEqualTo: true)
            .limit(1) // Solo traemos el plan activo actual
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: const Icon(Icons.restaurant, size: 64, color: Colors.green)),
                    const SizedBox(height: 24),
                    const Text('Sin dieta asignada', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkSlate)),
                    const SizedBox(height: 16),
                    const Text('Tu especialista aún no te ha asignado un plan nutricional. Cuando lo haga, aparecerá aquí.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
                  ],
                ),
              ),
            );
          }

          final planData = docs.first.data() as Map<String, dynamic>;
          final String objective = planData['objective'] ?? 'Mantenimiento';
          final int calories = planData['calories'] ?? 0;
          final String notes = planData['notes'] ?? '';
          final List meals = planData['meals'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TARJETA DE MACROS Y OBJETIVO
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Objetivo Actual', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Text(objective, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 28),
                          const SizedBox(width: 8),
                          Text('$calories', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                          const Text(' kcal / día', style: TextStyle(fontSize: 16, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),

                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade100)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(child: Text(notes, style: TextStyle(color: Colors.orange.shade900, height: 1.4))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                const Text('Tus Comidas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: darkSlate)),
                const SizedBox(height: 16),

                // 2. LISTA DE COMIDAS
                ...List.generate(meals.length, (index) {
                  final meal = meals[index] as Map<String, dynamic>;
                  final String mealName = meal['name'] ?? 'Comida ${index + 1}';
                  final String description = meal['description'] ?? '';
                  final String time = meal['time'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: const Icon(Icons.restaurant_menu, color: Colors.green)),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(mealName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkSlate)),
                          if (time.isNotEmpty) Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      subtitle: Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(description, style: TextStyle(color: Colors.grey.shade700, height: 1.4))),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}