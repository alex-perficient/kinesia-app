import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../patient_view/patient_home_screen.dart'; 

class PhysioProfileScreen extends StatelessWidget {
  const PhysioProfileScreen({super.key});

  // EL MOTOR DE LA COMPUERTA BIDIRECCIONAL
  Future<void> _enterAthleteMode(BuildContext context, String currentUserId, String physioName, String email) async {
    // 1. Mostramos un loading elegante mientras hacemos la magia
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
    );

    try {
      final patientRef = FirebaseFirestore.instance.collection('patients').doc(currentUserId);
      final patientDoc = await patientRef.get();

      // 2. Si el Fisio no tiene perfil de paciente, se lo creamos
      if (!patientDoc.exists) {
        await patientRef.set({
          'physioId': currentUserId, // Es su propio fisioterapeuta
          'fullName': physioName,
          'email': email,
          'status': 'active',
          'patientType': 'Fitness', // Perfil orientado a su propio entrenamiento
          'createdAt': FieldValue.serverTimestamp(),
          'streakCount': 0,
        });
      }

      // 3. Quitamos el loading y lo teletransportamos a la vista de Atleta
      if (context.mounted) {
        Navigator.pop(context); 
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cambiar de modo: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('physiotherapists').doc(currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final String name = data['displayName'] ?? 'Especialista';
          final String email = data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
          final String plan = data['plan'] ?? 'free';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LA TARJETA DE PRESENTACIÓN DIGITAL
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [darkSlate, Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.tealAccent.withValues(alpha: 0.2),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'F', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(fontSize: 14, color: Colors.white70)), 
                      const SizedBox(height: 4),
                      Text('Fisioterapeuta / Especialista', style: TextStyle(fontSize: 14, color: Colors.tealAccent.shade100, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(plan == 'pro' ? Icons.star : Icons.verified, color: plan == 'pro' ? Colors.amber : Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(plan == 'pro' ? 'Licencia PRO Activa' : 'Licencia Gratuita', style: TextStyle(color: plan == 'pro' ? Colors.amber : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text('Panel de Control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
                const SizedBox(height: 16),

                // 2. EL SWITCH "MODO PACIENTE / ENTRENAMIENTO"
                _buildMenuButton(
                  icon: Icons.fitness_center,
                  title: 'Mi Propio Entrenamiento',
                  subtitle: 'Cambia a la vista de atleta para registrar tus rutinas',
                  color: Colors.orange,
                  onTap: () => _enterAthleteMode(context, currentUserId, name, email), // Conectado al nuevo motor
                ),

                _buildMenuButton(
                  icon: Icons.qr_code_2,
                  title: 'Compartir mi Perfil',
                  subtitle: 'Muestra tu código QR a nuevos pacientes',
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generador de QR en desarrollo...')));
                  },
                ),

                _buildMenuButton(
                  icon: Icons.settings,
                  title: 'Ajustes de la Clínica',
                  subtitle: 'Configura notificaciones y preferencias',
                  color: Colors.grey.shade700,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajustes en desarrollo...')));
                  },
                ),

                const SizedBox(height: 32),
                
                // 3. CERRAR SESIÓN
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuButton({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}