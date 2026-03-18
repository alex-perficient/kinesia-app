import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

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
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al clonar: $e')));
        setState(() => _isCloning = false);
      }
    }
  }

  void _confirmSelection(Map<String, dynamic> templateData) {
    const Color darkSlate = Color(0xFF0F172A);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Asignar Rutina', style: TextStyle(fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: -0.5)),
        content: Text('¿Deseas asignar la plantilla "${templateData['title']}" a ${widget.patientName}?', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              _cloneTemplate(templateData); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Asignar Plantilla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Seleccionar Plantilla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha blanca asegurada
        elevation: 0,
      ),
      body: _isCloning
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.teal),
                  const SizedBox(height: 24),
                  Text('Generando rutina para ${widget.patientName}...', style: const TextStyle(color: darkSlate, fontWeight: FontWeight.bold, fontSize: 16)),
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
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }
                
                final templates = snapshot.data?.docs ?? [];

                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No tienes plantillas en tu biblioteca.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final data = templates[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Sin título';
                    final exercises = data['exercises'] as List? ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.library_books, color: Colors.teal),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkSlate, letterSpacing: -0.5)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: darkSlate.withValues(alpha:0.05), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fitness_center, size: 14, color: darkSlate),
                                const SizedBox(width: 6),
                                Text(
                                  '${exercises.length} Ejercicios',
                                  style: const TextStyle(color: darkSlate, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.send, color: Colors.teal, size: 16),
                        ),
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