import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditPatientProfileScreen extends StatefulWidget {
  final String patientId;

  const EditPatientProfileScreen({super.key, required this.patientId});

  @override
  State<EditPatientProfileScreen> createState() =>
      _EditPatientProfileScreenState();
}

class _EditPatientProfileScreenState extends State<EditPatientProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _surgeriesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  DateTime? _selectedDOB;
  String? _selectedGender;
  List<String> _selectedPathologies = [];

  final List<String> _commonPathologies = [
    'Diabetes',
    'Hipertensión',
    'Artritis',
    'Marcapasos',
    'Material de Osteosíntesis',
    'Ninguna',
  ];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['fullName'] ?? data['name'] ?? '';
          _occupationController.text = data['occupation'] ?? '';
          _allergiesController.text = data['allergies'] ?? '';
          _surgeriesController.text = data['surgeries'] ?? '';
          _medicationsController.text = data['medications'] ?? '';

          if (data['emergencyContact'] != null) {
            _emergencyNameController.text =
                data['emergencyContact']['name'] ?? '';
            _emergencyPhoneController.text =
                data['emergencyContact']['phone'] ?? '';
          }

          if (data['dateOfBirth'] != null) {
            _selectedDOB = (data['dateOfBirth'] as Timestamp).toDate();
          }

          _selectedGender = data['gender'];
          _selectedPathologies = List<String>.from(data['pathologies'] ?? []);

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.teal),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDOB) {
      setState(() => _selectedDOB = picked);
    }
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _updatePatient() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update({
            'fullName': _nameController.text.trim(),
            'dateOfBirth': _selectedDOB != null
                ? Timestamp.fromDate(_selectedDOB!)
                : null,
            'gender': _selectedGender,
            'occupation': _occupationController.text.trim(),
            'allergies': _allergiesController.text.trim(),
            'surgeries': _surgeriesController.text.trim(),
            'medications': _medicationsController.text.trim(),
            'emergencyContact': {
              'name': _emergencyNameController.text.trim(),
              'phone': _emergencyPhoneController.text.trim(),
            },
            'pathologies': _selectedPathologies,
          });

      if (mounted) {
        Navigator.pop(
          context,
          true,
        ); // Retorna true para avisar que hubo cambios
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Expediente actualizado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _allergiesController.dispose();
    _surgeriesController.dispose();
    _medicationsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  InputDecoration _premiumInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Editar Expediente',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nameController,
            decoration: _premiumInput('Nombre Completo', Icons.person_outline),
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: _premiumInput(
                'Fecha de Nacimiento',
                Icons.calendar_today,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDOB == null
                        ? 'Seleccionar fecha'
                        : DateFormat('dd/MM/yyyy').format(_selectedDOB!),
                  ),
                  if (_selectedDOB != null)
                    Text(
                      '${_calculateAge(_selectedDOB!)} años',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            decoration: _premiumInput('Sexo Fisiológico', Icons.wc),
            initialValue: _selectedGender,
            items: ['Masculino', 'Femenino', 'Otro']
                .map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (newValue) => setState(() => _selectedGender = newValue),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _occupationController,
            decoration: _premiumInput('Ocupación', Icons.work_outline),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _allergiesController,
            decoration: _premiumInput('Alergias', Icons.warning_amber_outlined),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _surgeriesController,
            decoration: _premiumInput(
              'Cirugías Previas',
              Icons.medical_services_outlined,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _medicationsController,
            decoration: _premiumInput(
              'Medicamentos Actuales',
              Icons.medication_outlined,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          const Text(
            'Antecedentes Patológicos',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkSlate),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _commonPathologies.map((pathology) {
              final isSelected = _selectedPathologies.contains(pathology);
              return FilterChip(
                // 1. TÍTULO DEL CHIP CON ESTILO BASE
                label: Text(
                  pathology,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // 👇 2. SOLUCIÓN AQUÍ: Definimos explícitamente el color del texto
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.teal.shade900
                      : const Color(
                          0xFF0F172A,
                        ), // darkSlate si no está seleccionado
                ),

                selected: isSelected,
                selectedColor: Colors.teal.shade100,

                // 👇 3. Definimos color de fondo para el estado no seleccionado (gris muy claro)
                backgroundColor: Colors.grey.shade100,
                checkmarkColor: Colors.teal.shade800,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.teal.shade300
                        : Colors.transparent,
                  ),
                ),

                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      if (pathology == 'Ninguna') {
                        _selectedPathologies.clear();
                      } else {
                        _selectedPathologies.remove('Ninguna');
                      }
                      _selectedPathologies.add(pathology);
                    } else {
                      _selectedPathologies.remove(pathology);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          const Text(
            'Contacto de Emergencia',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkSlate),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emergencyNameController,
            decoration: _premiumInput(
              'Nombre',
              Icons.health_and_safety_outlined,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            decoration: _premiumInput('Teléfono', Icons.phone_outlined),
          ),
          const SizedBox(height: 40),

          SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _updatePatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Guardar Cambios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
