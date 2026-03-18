import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  Future<void> _launchWhatsApp(BuildContext context) async {
    const phoneNumber = '529332443982'; 
    const message = 'Hola Mon TI Labs, quiero actualizar mi cuenta de Kines.ia al Plan PRO 🚀. ¿Me apoyan con la activación?';
    final Uri whatsappUrl = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir WhatsApp. Escríbenos al $phoneNumber')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar la solicitud.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);
    const Color goldAccent = Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: darkSlate,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        // LA SOLUCIÓN: Todo envuelto en un Scroll para que fluya natural
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono Premium
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: goldAccent.withValues(alpha: 0.1),
                    border: Border.all(color: goldAccent.withValues(alpha: 0.5), width: 2),
                  ),
                  child: const Icon(Icons.star_rounded, size: 64, color: goldAccent),
                ),
              ),
              const SizedBox(height: 32),
              
              // Título de Ventas
              const Text(
                'Desbloquea tu\nPotencial Clínico',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1),
              ),
              const SizedBox(height: 16),
              const Text(
                'Eleva el nivel de tu servicio, ahorra horas de papeleo y escala tu clínica sin límites.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 40),

              // Lista de Beneficios (Ya no es un ListView separado)
              _buildFeatureRow(Icons.all_inclusive, 'Pacientes Ilimitados', 'Rompe la barrera de los 15 expedientes y crece tu cartera.'),
              const SizedBox(height: 24),
              _buildFeatureRow(Icons.auto_awesome, 'Evaluación con IA', 'Dicta tus consultas y deja que la Inteligencia Artificial estructure el expediente por ti.'),
              const SizedBox(height: 24),
              _buildFeatureRow(Icons.support_agent, 'Soporte Prioritario', 'Atención directa y actualizaciones exclusivas de Mon TI Labs.'),
              
              const SizedBox(height: 40), // Espacio de respiro antes del precio

              // Sección de Precio y Botón
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: const [
                        Text('\$100', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2)),
                        Text(' MXN / mes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => _launchWhatsApp(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldAccent,
                          foregroundColor: darkSlate,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                        child: const Text('Actualizar a PRO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Activación rápida y segura vía WhatsApp.', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              const SizedBox(height: 32), // Espacio final
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.tealAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.tealAccent, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}