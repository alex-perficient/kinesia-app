import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../dashboard_physio/dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder "escucha" los cambios de estado (login/logout) en tiempo real
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si Firebase está verificando, mostramos un indicador de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si el usuario NO existe (no ha iniciado sesión), mostramos el Login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Si el usuario SÍ existe, lo mandamos a su pantalla principal.
        // Por ahora, pondremos una pantalla temporal (placeholder) del Dashboard.
        // Más adelante, aquí agregaremos la lógica para separar al Fisio del Paciente.
        // Si el usuario SÍ existe, lo mandamos a su pantalla principal.
        return const DashboardPhysioScreen();
      },
    );
  }
}