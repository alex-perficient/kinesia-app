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

  bool _askWeight = false;
  bool _askRPE = true; 
  bool _askEVA = true; 

  @override
  void initState() {
    super.initState();
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

  // Helpers para diseño limpio (Igual que en los otros formularios)
  InputDecoration _premiumInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label, 
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14), 
      prefixIcon: Icon(icon, color: Colors.teal, size: 20),
      filled: true, 
      fillColor: Colors.grey.shade50, 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.tune, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Configurar Ejercicio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: -0.5)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Datos Básicos
            TextField(controller: _nameController, decoration: _premiumInput('Nombre del Ejercicio', Icons.fitness_center)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _setsController, decoration: _premiumInput('Series', Icons.repeat), keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _repsController, decoration: _premiumInput('Reps / Tiempo', Icons.timer))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _youtubeController, decoration: _premiumInput('URL de YouTube (Opcional)', Icons.video_library)),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1, thickness: 1)),
            
            // LA MAGIA CLÍNICA: Configuración de Métricas
            const Text('Métricas a solicitar al paciente', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: darkSlate)),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Peso Levantado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Solicita registrar kg/lb', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _askWeight,
                    activeThumbColor: Colors.blue,
                    onChanged: (val) => setState(() => _askWeight = val),
                  ),
                  const Divider(height: 1, thickness: 1),
                  SwitchListTile(
                    title: const Text('Esfuerzo (RPE)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Escala del 1 al 10', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _askRPE,
                    activeThumbColor: Colors.orange,
                    onChanged: (val) => setState(() => _askRPE = val),
                  ),
                  const Divider(height: 1, thickness: 1),
                  SwitchListTile(
                    title: const Text('Dolor Articular (EVA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Escala del 0 al 10', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _askEVA,
                    activeThumbColor: Colors.redAccent,
                    onChanged: (val) => setState(() => _askEVA = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: darkSlate, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  onPressed: _save,
                  child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}