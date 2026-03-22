import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // <-- NUEVO: Para el blindaje de inputs
import 'sign_up_screen.dart';
import '../patient_view/main_patient_screen.dart';

// 1. IMPORTAMOS EL CONTENEDOR PRINCIPAL DEL FISIO (El que tiene la barra de navegación)
import '../../features/dashboard_physio/main_physio_screen.dart';

// 2. IMPORTAMOS LA PANTALLA DEL PACIENTE B2C
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
      // 1. Iniciamos sesión en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final String uid = userCredential.user!.uid;

      // 2. EL GUARDIA DE TRÁFICO: Buscamos qué rol tiene
      // Buscamos si existe en la colección de Fisioterapeutas
      DocumentSnapshot physioDoc = await FirebaseFirestore.instance
          .collection('physiotherapists')
          .doc(uid)
          .get();

      if (physioDoc.exists) {
        // ES FISIOTERAPEUTA -> Lo mandamos a la pantalla con el menú inferior
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPhysioScreen()),
          );
        }
      } else {
        // ES ATLETA B2C (O PACIENTE DE CLÍNICA) -> Lo mandamos a su modo entrenamiento
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPatientScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'user-not-found' || e.code == 'invalid-email') {
            _errorMessage = 'No hay un usuario con este correo o es inválido.';
          } else if (e.code == 'wrong-password' ||
              e.code == 'invalid-credential') {
            _errorMessage = 'Contraseña incorrecta.';
          } else {
            _errorMessage = 'Error al iniciar sesión: ${e.message}';
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      body: Stack(
        children: [
          // 1. EL FONDO INMERSIVO
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/fondo_login.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.75),
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          // 2. EL CONTENIDO FLOTANTE
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LOGOTIPO
                      const Text(
                        'Kines.ia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: darkSlate,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Alto Rendimiento y Rehabilitación',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // FORMULARIO
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(
                            RegExp(r'\s'),
                          ), // Bloquea espacios
                          LengthLimitingTextInputFormatter(
                            50,
                          ), // Límite de 50 caracteres
                        ],
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(
                            RegExp(r'\s'),
                          ), // Bloquea espacios
                          LengthLimitingTextInputFormatter(
                            32,
                          ), // Límite de 32 caracteres
                        ],
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ERROR MESSAGE
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (_errorMessage != null) const SizedBox(height: 16),

                      // BOTÓN DE INGRESAR
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkSlate,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // BOTÓN DE REGISTRO
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        ),
                        child: const Text(
                          '¿Eres nuevo? Regístrate aquí',
                          style: TextStyle(
                            color: Colors.teal,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
