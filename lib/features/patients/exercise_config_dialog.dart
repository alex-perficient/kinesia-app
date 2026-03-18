import 'package:flutter/material.dart';

class ExerciseConfigDialog extends StatefulWidget {
  final Map<String, dynamic>? existingExercise;

  const ExerciseConfigDialog({super.key, this.existingExercise});

  @override
  State<ExerciseConfigDialog> createState() => _ExerciseConfigDialogState();
}

class _ExerciseConfigDialogState extends State<ExerciseConfigDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  // Banderas dinámicas para las métricas que le pediremos al paciente
  bool _askWeight = false;
  bool _askRPE = true; // Por defecto encendido, es el más común
  bool _askEVA = true; // Por defecto encendido

  @override
  void initState() {
    super.initState();
    // Si estamos editando un ejercicio existente, cargamos sus datos
    if (widget.existingExercise != null) {
      _nameController.text = widget.existingExercise!['title'] ?? widget.existingExercise!['name'] ?? '';
      _setsController.text = widget.existingExercise!['sets']?.toString() ?? '';
      _repsController.text = widget.existingExercise!['reps']?.toString() ?? '';
      _youtubeController.text = widget.existingExercise!['youtubeUrl'] ?? '';
      
      _askWeight = widget.existingExercise!['askWeight'] ?? false;
      _askRPE = widget.existingExercise!['askRPE'] ?? true;
      _askEVA = widget.existingExercise!['askEVA'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;

    // Retornamos el mapa completo del ejercicio con sus nuevas banderas dinámicas
    Navigator.pop(context, {
      'title': _nameController.text.trim(),
      'sets': _setsController.text.trim(),
      'reps': _repsController.text.trim(),
      'youtubeUrl': _youtubeController.text.trim(),
      'askWeight': _askWeight,
      'askRPE': _askRPE,
      'askEVA': _askEVA,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configurar Ejercicio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 16),
            
            // Datos Básicos
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre del Ejercicio', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _setsController, decoration: const InputDecoration(labelText: 'Series', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _repsController, decoration: const InputDecoration(labelText: 'Reps / Tiempo', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _youtubeController, decoration: const InputDecoration(labelText: 'URL de YouTube (Opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.video_library))),
            
            const Divider(height: 32),
            
            // LA MAGIA CLÍNICA: Configuración de Métricas
            const Text('¿Qué datos debe registrar el paciente?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            SwitchListTile(
              title: const Text('Pedir Peso Levantado (kg/lb)'),
              subtitle: const Text('Útil para hipertrofia o fuerza', style: TextStyle(fontSize: 12)),
              value: _askWeight,
              activeThumbColor: Colors.teal,
              onChanged: (val) => setState(() => _askWeight = val),
            ),
            SwitchListTile(
              title: const Text('Pedir Esfuerzo (RPE 1-10)'),
              subtitle: const Text('Mide qué tan pesado lo sintió', style: TextStyle(fontSize: 12)),
              value: _askRPE,
              activeThumbColor: Colors.blue,
              onChanged: (val) => setState(() => _askRPE = val),
            ),
            SwitchListTile(
              title: const Text('Pedir Dolor (EVA 0-10)'),
              subtitle: const Text('Mide si hubo molestias articulares', style: TextStyle(fontSize: 12)),
              value: _askEVA,
              activeThumbColor: Colors.red,
              onChanged: (val) => setState(() => _askEVA = val),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: _save,
                  child: const Text('Guardar Ejercicio'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}