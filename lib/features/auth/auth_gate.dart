import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../dashboard_physio/main_physio_screen.dart';
import '../patient_view/main_patient_screen.dart';
// 👇 IMPORTAMOS LA NUEVA PANTALLA LEGAL
import 'privacy_consent_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Revisando estado general de la sesión
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        // 2. Si no hay usuario logueado, mandamos al Login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final User currentUser = snapshot.data!;

        // 3. Revisamos si es FISIOTERAPEUTA
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('physiotherapists')
              .doc(currentUser.uid)
              .get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                ),
              );
            }

            // A. RUTA FISIOTERAPEUTA
            if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
              final data = roleSnapshot.data!.data() as Map<String, dynamic>?;
              final bool hasAcceptedPrivacy =
                  data != null &&
                  data.containsKey('hasAcceptedPrivacy') &&
                  data['hasAcceptedPrivacy'] == true;

              // Si no ha firmado, lo desviamos al contrato
              if (!hasAcceptedPrivacy) {
                return const PrivacyConsentScreen(role: 'physiotherapist');
              }
              // Si ya firmó, entra normal
              return const MainPhysioScreen();
            }
            // B. RUTA PACIENTE (O USUARIO NUEVO)
            else {
              // Necesitamos leer el perfil del paciente para saber si ya firmó
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('patients')
                    .doc(currentUser.uid)
                    .get(),
                builder: (context, patientSnapshot) {
                  if (patientSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      ),
                    );
                  }

                  if (patientSnapshot.hasData && patientSnapshot.data!.exists) {
                    final patientData =
                        patientSnapshot.data!.data() as Map<String, dynamic>?;
                    final bool hasAcceptedPrivacy =
                        patientData != null &&
                        patientData.containsKey('hasAcceptedPrivacy') &&
                        patientData['hasAcceptedPrivacy'] == true;

                    // Si no ha firmado, lo desviamos al contrato
                    if (!hasAcceptedPrivacy) {
                      return const PrivacyConsentScreen(role: 'patient');
                    }
                    // Si ya firmó, entra normal
                    return const MainPatientScreen();
                  }

                  // C. SALVAVIDAS (Usuario Huérfano)
                  // Si el usuario se autenticó pero por un error de red nunca se creó
                  // su documento en Firestore, cerramos su sesión para no dejarlo atrapado en pantalla blanca.
                  FirebaseAuth.instance.signOut();
                  return const LoginScreen();
                },
              );
            }
          },
        );
      },
    );
  }
}
