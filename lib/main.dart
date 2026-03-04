import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/auth_gate.dart'; // ¡Agregamos esta importación!

void main() async {
  // 1. Fundamental: Le dice a Flutter que espere a que los canales nativos estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Firebase con los IDs mágicos que te arrojó la consola
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Arranca la aplicación
  runApp(const KinesiaApp());
}

class KinesiaApp extends StatelessWidget {
  const KinesiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kines.ia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Un tema limpio y médico/tecnológico para empezar
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), 
        useMaterial3: true,
      ),
      // Aquí está el cambio: La app arranca directamente en el AuthGate
      home: const AuthGate(), 
    );
  }
}