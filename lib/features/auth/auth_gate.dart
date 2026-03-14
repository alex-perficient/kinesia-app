import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
//import '../dashboard_physio/dashboard_screen.dart';
import '../dashboard_physio/main_physio_screen.dart';
import '../patient_view/patient_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Revisando estado de la sesión
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Si no hay usuario logueado, mandamos al Login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final User currentUser = snapshot.data!;

        // 3. Si hay usuario, averiguamos su ROL (Fisio o Paciente)
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('physiotherapists').doc(currentUser.uid).get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.teal)));
            }

            // Si el documento existe en la colección de fisios...
            if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
              return const MainPhysioScreen(); //DashboardPhysioScreen(); // Entra el Fisioterapeuta
            } else {
              // Si no existe, por descarte es un paciente
              return const PatientHomeScreen(); // Entra el Paciente
            }
          },
        );
      },
    );
  }
}