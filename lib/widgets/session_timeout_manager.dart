import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/auth_gate.dart';
import '../main.dart';

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;

  const SessionTimeoutManager({
    super.key,
    required this.child,
    // Por estándar médico, 10 a 15 minutos es lo ideal
    // 💡 TIP PARA PRUEBAS: Cambia 'minutes: 15' a 'seconds: 15' para probar que te expulsa rápido
    this.timeoutDuration = const Duration(minutes: 15),
  });

  @override
  State<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends State<SessionTimeoutManager> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // Reinicia el reloj desde cero
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeoutDuration, _handleTimeout);
  }

  // Se dispara cada vez que el usuario toca la pantalla
  void _handleUserInteraction([_]) {
    _startTimer();
  }

  // Se dispara cuando el temporizador llega a cero
  Future<void> _handleTimeout() async {
    // Solo actuamos si hay alguien con sesión iniciada
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // Redirigimos al Login y destruimos el historial de navegación
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );

        // Le explicamos al usuario qué pasó
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              'Por tu seguridad, la sesión se ha cerrado por inactividad.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El widget Listener atrapa todos los toques globalmente sin bloquear la app
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      child: widget.child,
    );
  }
}
