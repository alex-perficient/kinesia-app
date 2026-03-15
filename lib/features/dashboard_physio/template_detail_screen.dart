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

  // Función para borrar la plantilla de Firebase
  Future<void> _deleteTemplate() async {
    // 1. Pedimos confirmación para no borrar por accidente
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar plantilla?'),
        content: const Text('Esta acción no se puede deshacer. Los pacientes que ya tienen esta rutina asignada no se verán afectados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
      // 2. Borramos el documento de Firestore
      await FirebaseFirestore.instance.collection('routine_templates').doc(widget.templateId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla eliminada 🗑️')),
        );
        Navigator.pop(context); // Regresamos a la biblioteca
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Plantilla'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Botón de basura en la esquina superior
          _isDeleting 
            ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar Plantilla',
                onPressed: _deleteTemplate,
              ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera con la info
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.teal.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                if (widget.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(widget.description, style: TextStyle(fontSize: 16, color: Colors.teal.shade800)),
                ]
              ],
            ),
          ),
          
          // Lista de ejercicios
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('${widget.exercises.length} Ejercicios Base', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: widget.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.exercises[index] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(exercise['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${exercise['sets']} series x ${exercise['reps']}'),
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