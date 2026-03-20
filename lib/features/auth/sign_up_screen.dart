import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('physiotherapists')
            .doc(userCredential.user!.uid)
            .set({
          'displayName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'plan': 'free', 
          'patientCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      if (mounted) Navigator.pop(context); 
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _errorMessage = 'La contraseña es muy débil (mínimo 6 caracteres).';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Ya existe una cuenta con este correo.';
        } else {
          _errorMessage = 'Error: ${e.message}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      extendBodyBehindAppBar: true, // Esto hace que la foto suba hasta arriba
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Barra transparente
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha blanca de regreso
      ),
      body: Stack(
        children: [
          // FONDO INMERSIVO
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                // Otra fotografía premium complementaria
                image: const AssetImage('assets/images/fondo_signup.png'),
             //   image: const NetworkImage('https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha:0.75), BlendMode.darken),
              ),
            ),
          ),

          // FORMULARIO FLOTANTE
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Únete al equipo',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea tu cuenta de especialista',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),

                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email_outlined)),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)),
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
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Comenzar gratis', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}