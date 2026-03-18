import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; 

class CreatePatientScreen extends StatefulWidget {
  const CreatePatientScreen({super.key});

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedPatientType = 'Clínica'; 
  final List<String> _patientTypes = ['Clínica', 'Fitness'];
  
  bool _isLoading = false;

  Future<void> _savePatient() async {
    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Llena todos los campos. La contraseña debe tener al menos 6 caracteres.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String physioId = FirebaseAuth.instance.currentUser!.uid;
      final physioRef = FirebaseFirestore.instance.collection('physiotherapists').doc(physioId);

      final physioDoc = await physioRef.get();
      final physioData = physioDoc.data() as Map<String, dynamic>;
      final String plan = physioData['plan'] ?? 'free';
      final int currentCount = physioData['patientCount'] ?? 0;

      if (plan == 'free' && currentCount >= 15) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Límite de 15 pacientes alcanzado en el plan Free.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryPatientCreation',
        options: Firebase.app().options,
      );

      UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String newPatientId = userCredential.user!.uid;
      await tempApp.delete();

      await FirebaseFirestore.instance.collection('patients').doc(newPatientId).set({
        'physioId': physioId,
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'patientType': _selectedPatientType,
      });

      await physioRef.update({'patientCount': FieldValue.increment(1)});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente y credenciales creadas con éxito ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper para Inputs Premium
  InputDecoration _premiumInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.teal),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.teal, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Fondo gris para resaltar el formulario blanco
      appBar: AppBar(
        title: const Text('Nuevo Paciente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha blanca asegurada
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Genera el acceso', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            const Text('Crea las credenciales seguras para que tu paciente pueda usar la app.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 32),
            
            // CONTENEDOR BLANCO DEL FORMULARIO
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 15, offset: const Offset(0, 5))]),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _premiumInput('Nombre Completo', Icons.person_outline),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _premiumInput('Correo del Paciente', Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedPatientType,
                    decoration: _premiumInput('Enfoque / Tipo', Icons.category_outlined),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.teal),
                    items: _patientTypes.map((String type) => DropdownMenuItem<String>(value: type, child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) setState(() => _selectedPatientType = newValue);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    decoration: _premiumInput('Contraseña Temporal', Icons.lock_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // MENSAJE DE CUOTA PREMIUM
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: darkSlate.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: darkSlate.withValues(alpha:0.1))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: darkSlate, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gestión de Cuota', style: TextStyle(fontWeight: FontWeight.bold, color: darkSlate)),
                        const SizedBox(height: 4),
                        Text(
                          'Crear un expediente consume 1 espacio. Los espacios no se recuperan al archivar para preservar el historial médico.',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // BOTÓN GIGANTE FLOTANTE
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.grey.shade100,
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _savePatient,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 4),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Generar Acceso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}