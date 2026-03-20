import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

// Helper para manejar los campos dinámicos de cada comida
class MealField {
  TextEditingController nameController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController descController = TextEditingController();
}

class CreateDietScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const CreateDietScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<CreateDietScreen> createState() => _CreateDietScreenState();
}

class _CreateDietScreenState extends State<CreateDietScreen> {
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedObjective = 'Mantenimiento';
  final List<String> _objectives = ['Pérdida de Grasa', 'Mantenimiento', 'Aumento de Masa Muscular', 'Recomposición', 'Déficit Calórico'];
  
  final List<MealField> _meals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Agregamos una comida por defecto al abrir
    _addMealField();
  }

  void _addMealField() {
    setState(() {
      _meals.add(MealField());
    });
  }

  void _removeMealField(int index) {
    setState(() {
      _meals.removeAt(index);
    });
  }

  Future<void> _saveDiet() async {
    if (_caloriesController.text.trim().isEmpty || _meals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa las calorías y al menos una comida.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String physioId = FirebaseAuth.instance.currentUser!.uid;

      // 1. Procesar las comidas
      List<Map<String, String>> mealData = [];
      for (var meal in _meals) {
        if (meal.nameController.text.trim().isNotEmpty) {
          mealData.add({
            'name': meal.nameController.text.trim(),
            'time': meal.timeController.text.trim(),
            'description': meal.descController.text.trim(),
          });
        }
      }

      // 2. Desactivar dietas anteriores del paciente
      final oldDiets = await FirebaseFirestore.instance.collection('nutrition_plans')
          .where('patientId', isEqualTo: widget.patientId)
          .where('isActive', isEqualTo: true)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in oldDiets.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      await batch.commit();

      // 3. Guardar el nuevo plan nutricional
      await FirebaseFirestore.instance.collection('nutrition_plans').add({
        'patientId': widget.patientId,
        'physioId': physioId,
        'objective': _selectedObjective,
        'calories': int.tryParse(_caloriesController.text.trim()) ?? 0,
        'notes': _notesController.text.trim(),
        'meals': mealData,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Notificar al paciente
      await NotificationService.sendNotification(
        receiverId: widget.patientId,
        title: 'Nuevo Plan Nutricional 🍏',
        body: 'Tu especialista ha actualizado tu dieta. ¡Revisa tus nuevas comidas!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dieta asignada con éxito ✅', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _notesController.dispose();
    for (var meal in _meals) {
      meal.nameController.dispose();
      meal.timeController.dispose();
      meal.descController.dispose();
    }
    super.dispose();
  }

  InputDecoration _premiumInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.green, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Dieta: ${widget.patientName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCIÓN 1: MACROS Y OBJETIVOS
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estrategia Nutricional', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
                  const SizedBox(height: 20),
                  
                  const Text('Objetivo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedObjective,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
                        items: _objectives.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: darkSlate)))).toList(),
                        onChanged: (newValue) => setState(() => _selectedObjective = newValue!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: _caloriesController, keyboardType: TextInputType.number, decoration: _premiumInput('Calorías Diarias (Kcal)', Icons.local_fire_department)),
                  const SizedBox(height: 16),
                  TextField(controller: _notesController, maxLines: 2, decoration: _premiumInput('Indicaciones generales (Agua, Suplementos...)', Icons.info_outline)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // SECCIÓN 2: COMIDAS (DINÁMICO)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estructura de Comidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
                OutlinedButton.icon(
                  onPressed: _addMealField,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Comida'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: BorderSide(color: Colors.green.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...List.generate(_meals.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _meals[index].nameController, decoration: const InputDecoration(hintText: 'Ej. Desayuno', border: InputBorder.none, hintStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkSlate))),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _removeMealField(index)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _meals[index].timeController, decoration: const InputDecoration(hintText: 'Horario (Ej. 08:00 AM)', border: InputBorder.none, isDense: true))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: TextField(controller: _meals[index].descController, maxLines: 3, decoration: const InputDecoration(hintText: 'Describe los alimentos y porciones...', border: InputBorder.none, isDense: true), style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveDiet,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 4),
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Guardar y Asignar Dieta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}