import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // <-- NUEVO

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPhysio = false; // Por defecto asumimos que es un Atleta B2C

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // 1. VALIDACIÓN RIGUROSA ANTES DE TOCAR FIREBASE
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Por favor llena todos los campos.');
      return;
    }

    // Validador de estructura de correo (ej. test@test.com)
    final emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
    if (!emailValid) {
      setState(() => _errorMessage = 'Ingresa un correo electrónico válido.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Crear el usuario en Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;

        // 2. Guardar en la colección correspondiente según el rol elegido
        if (_isPhysio) {
          // PERFIL ESPECIALISTA
          await FirebaseFirestore.instance.collection('physiotherapists').doc(uid).set({
            'displayName': name,
            'email': email,
            'plan': 'free', 
            'patientCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // PERFIL ATLETA B2C
          await FirebaseFirestore.instance.collection('patients').doc(uid).set({
            'fullName': name,
            'email': email,
            'physioId': uid, 
            'patientType': 'B2C', 
            'status': 'active',
            'streakCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      // 3. Regresamos al Login (El AuthState/LoginScreen se encargará de enviarlo a su Home)
      if (mounted) Navigator.pop(context); 
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'Ya existe una cuenta con este correo.';
        } else {
          _errorMessage = 'Error: ${e.message}';
        }
      });
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
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      body: Stack(
        children: [
          // FONDO INMERSIVO
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/fondo_signup.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.darken),
              ),
            ),
          ),

          // FORMULARIO FLOTANTE (ESTILO TARJETA PREMIUM)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(32), 
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Únete a Kines.ia', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: -1)),
                      const SizedBox(height: 8),
                      const Text('Selecciona tu perfil para comenzar', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 32),

                      // SELECTOR DE ROL (Atleta vs Especialista)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPhysio = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: !_isPhysio ? Colors.teal : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: !_isPhysio ? Colors.teal : Colors.grey.shade200, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.fitness_center, color: !_isPhysio ? Colors.white : Colors.grey, size: 28),
                                    const SizedBox(height: 8),
                                    Text('Atleta', style: TextStyle(fontWeight: FontWeight.bold, color: !_isPhysio ? Colors.white : Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPhysio = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _isPhysio ? darkSlate : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _isPhysio ? darkSlate : Colors.grey.shade200, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.medical_services, color: _isPhysio ? Colors.white : Colors.grey, size: 28),
                                    const SizedBox(height: 8),
                                    Text('Especialista', style: TextStyle(fontWeight: FontWeight.bold, color: _isPhysio ? Colors.white : Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),

                      TextField(
                        controller: _nameController,
                        inputFormatters: [LengthLimitingTextInputFormatter(50)], // Máximo 50 caracteres
                        decoration: InputDecoration(labelText: 'Nombre Completo', prefixIcon: const Icon(Icons.person_outline), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')), // Bloquea espacios
                          LengthLimitingTextInputFormatter(50),
                        ],
                        decoration: InputDecoration(labelText: 'Correo Electrónico', prefixIcon: const Icon(Icons.email_outlined), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')), // Bloquea espacios
                          LengthLimitingTextInputFormatter(32),
                        ],
                        decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
                          child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      if (_errorMessage != null) const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPhysio ? darkSlate : Colors.teal, 
                            foregroundColor: Colors.white, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                            elevation: 4
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_isPhysio ? 'Crear Clínica' : 'Comenzar a Entrenar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}