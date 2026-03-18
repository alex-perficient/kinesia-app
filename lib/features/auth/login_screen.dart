import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false; 
  String? _errorMessage;   

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) { 
        setState(() {
          if (e.code == 'user-not-found') {
            _errorMessage = 'No hay un usuario con este correo.';
          } else if (e.code == 'wrong-password') {
            _errorMessage = 'Contraseña incorrecta.';
          } else {
            _errorMessage = 'Error al iniciar sesión: ${e.message}';
          }
        });
      }
    } finally {
      if (mounted) { 
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos Stack para apilar el fondo oscuro y el formulario encima
      body: Stack(
        children: [
          // 1. EL FONDO INMERSIVO
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                // Fotografía premium de un centro de entrenamiento/clínica
                image: const NetworkImage('https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=2000&auto=format&fit=crop'),
                fit: BoxFit.cover,
                // Filtro oscuro muy elegante para que resalte el blanco
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha:0.75), BlendMode.darken),
              ),
            ),
          ),
          
          // 2. EL CONTENIDO FLOTANTE
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LOGOTIPO (Texto blanco para contrastar)
                    const Text(
                      'Kines.ia',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.white,
                        letterSpacing: -1.5, // Tipografía más unida y deportiva
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Alto Rendimiento y Rehabilitación',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 56),

                    // FORMULARIO (Se verán como burbujas gracias al ThemeData)
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ERROR MESSAGE (Con fondo para que se lea sobre la foto)
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha:0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 16),

                    // BOTÓN DE INGRESAR (Ajustado al ancho total, sin height fijo)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Ingresar a mi cuenta', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // BOTÓN DE REGISTRO
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        '¿Eres nuevo? Regístrate aquí', 
                        style: TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold),
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