import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateDetailScreen extends StatefulWidget {
  final String templateId;
  final String title;
  final String description;
  final List<dynamic> exercises;

  const TemplateDetailScreen({
    super.key,
    required this.templateId,
    required this.title,
    required this.description,
    required this.exercises,
  });

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  bool _isDeleting = false;

  Future<void> _deleteTemplate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar plantilla?'),
        content: const Text('Esta acción no se puede deshacer. Los pacientes que ya tienen esta rutina asignada no se verán afectados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await FirebaseFirestore.instance.collection('routine_templates').doc(widget.templateId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla eliminada 🗑️')),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detalle de Plantilla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha blanca asegurada
        elevation: 0,
        actions: [
          _isDeleting 
            ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade300,
                tooltip: 'Eliminar Plantilla',
                onPressed: _deleteTemplate,
              ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CABECERA TIPO DOCUMENTO DIGITAL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.library_books, color: Colors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: -0.5)),
                    ),
                  ],
                ),
                if (widget.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(widget.description, style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5)),
                ]
              ],
            ),
          ),
          
          // ENCABEZADO DE LA LISTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                const Text('Ejercicios Base', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: darkSlate.withValues(alpha:0.05), borderRadius: BorderRadius.circular(12)),
                  child: Text('${widget.exercises.length} Total', style: const TextStyle(fontWeight: FontWeight.bold, color: darkSlate)),
                ),
              ],
            ),
          ),
          
          // LISTA DE EJERCICIOS (SaaS Bubbles)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: widget.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.exercises[index] as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(exercise['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkSlate)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('${exercise['sets']} series × ${exercise['reps']} reps', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}