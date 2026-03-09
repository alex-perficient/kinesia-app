import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // Importante para la segunda instancia

class CreatePatientScreen extends StatefulWidget {
  const CreatePatientScreen({super.key});

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // NUEVA VARIABLE: Por defecto será Clínico (Rehabilitación)
  String _selectedProfile = 'clinical'; 
  
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

      // 1. Validar límite de plan gratuito
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

      // 2. EL TRUCO ARQUITECTÓNICO: Crear una segunda app de Firebase temporal
      // Esto evita que Firebase cierre la sesión del Fisioterapeuta actual.
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryPatientCreation',
        options: Firebase.app().options,
      );

      // 3. Crear el usuario en Authentication usando la app temporal
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String newPatientId = userCredential.user!.uid;

      // 4. Destruir la app temporal inmediatamente por seguridad
      await tempApp.delete();

      // 5. Guardar el documento del paciente en Firestore con el nuevo ID real
      await FirebaseFirestore.instance.collection('patients').doc(newPatientId).set({
        'physioId': physioId,
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'status': 'active',
        'profileType': _selectedProfile, // ¡AQUÍ ESTÁ LA MAGIA!
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 6. Actualizar el contador del fisio
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Paciente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crea las credenciales de acceso para tu paciente.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo del Paciente', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 16),

            // NUEVO SELECTOR DE PERFIL
            DropdownButtonFormField<String>(
              value: _selectedProfile,
              decoration: const InputDecoration(
                labelText: 'Tipo de Paciente / Enfoque',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'clinical',
                  child: Text('Clínico (Rehabilitación / Lesión)'),
                ),
                DropdownMenuItem(
                  value: 'fitness',
                  child: Text('Fitness (Fuerza / Rendimiento)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProfile = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña Temporal (Mín. 6 letras/números)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePatient,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Generar Acceso y Guardar', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}