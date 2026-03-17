import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart'; // Ajusta la ruta a donde tengas tu servicio

class SelectTemplateScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const SelectTemplateScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<SelectTemplateScreen> createState() => _SelectTemplateScreenState();
}

class _SelectTemplateScreenState extends State<SelectTemplateScreen> {
  bool _isCloning = false;

  // LA MAGIA: Esta función toma la plantilla y la clona para el paciente
  Future<void> _cloneTemplate(Map<String, dynamic> templateData) async {
    setState(() => _isCloning = true);

    try {
      await FirebaseFirestore.instance.collection('routines').add({
        'patientId': widget.patientId,
        'physioId': FirebaseAuth.instance.currentUser!.uid,
        'title': templateData['title'],
        'description': templateData['description'] ?? '',
        'exercises': templateData['exercises'] ?? [],
        'assignedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      try {
        await NotificationService.sendNotification(
          receiverId: widget.patientId,
          title: 'Nueva rutina asignada 📋',
          body: 'Tu fisioterapeuta te ha asignado: ${templateData['title']}',
        );
      } catch (e) {
        debugPrint('Error al enviar notificación: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rutina asignada a ${widget.patientName} ✅')),
        );
        Navigator.pop(context); // Regresamos al perfil del paciente
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al clonar: $e')));
        setState(() => _isCloning = false);
      }
    }
  }

  // Cuadro de confirmación antes de clonar
  void _confirmSelection(Map<String, dynamic> templateData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignar Rutina'),
        content: Text('¿Deseas asignar la plantilla "${templateData['title']}" a ${widget.patientName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              _cloneTemplate(templateData); // Inicia la clonación
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Plantilla'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isCloning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text('Generando rutina personalizada...', style: TextStyle(color: Colors.teal)),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('routine_templates')
                  .where('physioId', isEqualTo: currentUserId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final templates = snapshot.data?.docs ?? [];

                if (templates.isEmpty) {
                  return const Center(
                    child: Text('No tienes plantillas en tu biblioteca aún.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final data = templates[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Sin título';
                    final exercises = data['exercises'] as List? ?? [];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: const Icon(Icons.file_copy, color: Colors.teal),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${exercises.length} ejercicios base'),
                        trailing: const Icon(Icons.send, color: Colors.teal),
                        onTap: () => _confirmSelection(data),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}