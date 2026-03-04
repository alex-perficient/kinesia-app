import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatePatientScreen extends StatefulWidget {
  const CreatePatientScreen({super.key});

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Opcional por ahora
  
  bool _isLoading = false;

  Future<void> _savePatient() async {
    // Validar que el nombre no esté vacío
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el nombre del paciente.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String physioId = FirebaseAuth.instance.currentUser!.uid;
      final physioRef = FirebaseFirestore.instance.collection('physiotherapists').doc(physioId);

      // 1. Leer los datos actuales del fisioterapeuta
      final physioDoc = await physioRef.get();
      final physioData = physioDoc.data() as Map<String, dynamic>;
      final String plan = physioData['plan'] ?? 'free';
      final int currentCount = physioData['patientCount'] ?? 0;

      // 2. Aplicar la regla de negocio: Límite del plan gratuito
      if (plan == 'free' && currentCount >= 15) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Límite alcanzado'),
              content: const Text('Has alcanzado el límite de 15 pacientes de tu plan gratuito. Mejora a Pro para agregar más.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
        setState(() => _isLoading = false);
        return; // Detenemos la ejecución aquí
      }

      // 3. Crear el documento del nuevo paciente
      await FirebaseFirestore.instance.collection('patients').add({
        'physioId': physioId,
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Aumentar el contador del fisioterapeuta en +1
      await physioRef.update({
        'patientCount': FieldValue.increment(1),
      });

      // 5. Mostrar éxito y regresar al Dashboard
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente agregado exitosamente ✅')),
        );
        Navigator.pop(context); // Cierra la pantalla
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Paciente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingresa los datos del paciente. Más adelante podrás asignarle rutinas.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo (Requerido)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico (Opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Paciente', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}