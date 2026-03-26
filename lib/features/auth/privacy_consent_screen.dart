import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/features/auth/auth_gate.dart';

class PrivacyConsentScreen extends StatefulWidget {
  final String role; // 'patient' o 'physiotherapist'

  const PrivacyConsentScreen({super.key, required this.role});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _acceptedData = false;
  bool _acceptedAI = false;
  bool _isSaving = false;

  Future<void> _saveConsent() async {
    setState(() => _isSaving = true);
    try {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final String collection = widget.role == 'patient'
          ? 'patients'
          : 'physiotherapists';

      // 1. Guardamos en el perfil del usuario que ya aceptó los términos
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(currentUserId)
          .update({
            'hasAcceptedPrivacy': true,
            'privacyAcceptedAt': FieldValue.serverTimestamp(),
          });

      // 2. Guardamos un registro legal inmutable en una colección de auditoría (Buena práctica clínica)
      await FirebaseFirestore.instance
          .collection('legal_consents')
          .doc(currentUserId)
          .set({
            'userId': currentUserId,
            'role': widget.role,
            'acceptedDataProcessing': _acceptedData,
            'acceptedAIProcessing': _acceptedAI,
            'timestamp': FieldValue.serverTimestamp(),
            'ipAddress': 'Registrada por Firebase', // Meta-data
          });

      if (mounted) {
        // Lo mandamos a la app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Consentimiento Informado'),
        automaticallyImplyLeading: false, // No los dejamos regresar sin aceptar
      ),
      body: Column(
        children: [
          // ÁREA DEL DOCUMENTO LEGAL (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.teal,
                          size: 32,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Tu privacidad y la seguridad de tus datos médicos son nuestra prioridad absoluta.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '1. Manejo de Datos Clínicos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkSlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Al utilizar Kines.ia, aceptas que tus datos fisiológicos, métricas de dolor, bitácoras de entrenamiento y planes nutricionales sean almacenados de forma segura en la nube. Estos datos son estrictamente confidenciales y solo serán accesibles por ti y tu fisioterapeuta asignado.',
                    style: TextStyle(height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '2. Procesamiento con Inteligencia Artificial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkSlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kines.ia utiliza modelos avanzados de Inteligencia Artificial para asistir a los profesionales de la salud. Aceptas que textos descriptivos y notas de voz (audios) proporcionados en el expediente clínico sean procesados por motores de IA de terceros para generar resúmenes, extraer métricas (Triage) y ofrecer sugerencias terapéuticas. Ningún dato procesado por IA será utilizado para entrenar modelos públicos ni será vendido a terceros.',
                    style: TextStyle(height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '3. Retención y Derechos ARCO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkSlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tienes derecho a acceder, rectificar, cancelar u oponerse al tratamiento de tus datos en cualquier momento. Si solicitas la eliminación de tu cuenta, tus registros clínicos serán anonimizados o destruidos según las leyes locales de retención médica.',
                    style: TextStyle(height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          // ÁREA DE CHECKBOXES Y BOTÓN (Fija abajo)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _acceptedData,
                    activeColor: Colors.teal,
                    title: const Text(
                      'Acepto el aviso de privacidad y el tratamiento de mis datos clínicos.',
                      style: TextStyle(fontSize: 14),
                    ),
                    onChanged: (val) =>
                        setState(() => _acceptedData = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _acceptedAI,
                    activeColor: Colors.teal,
                    title: const Text(
                      'Doy mi consentimiento explícito para que mis datos y audios sean procesados por Inteligencia Artificial con fines terapéuticos.',
                      style: TextStyle(fontSize: 14),
                    ),
                    onChanged: (val) =>
                        setState(() => _acceptedAI = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      // El botón se desactiva si no ha marcado ambas casillas
                      onPressed: (_acceptedData && _acceptedAI && !_isSaving)
                          ? _saveConsent
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'ACEPTAR Y CONTINUAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
