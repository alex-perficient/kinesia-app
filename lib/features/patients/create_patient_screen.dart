import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import '../dashboard_physio/paywall_screen.dart';

class CreatePatientScreen extends StatefulWidget {
  const CreatePatientScreen({super.key});

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  // Controladores Originales
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedPatientType = 'Clínica';
  final List<String> _patientTypes = ['Clínica', 'Fitness'];

  // NUEVOS: Controladores Clínicos
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  DateTime? _selectedDOB;
  String? _selectedGender;
  final List<String> _selectedPathologies = [];
  final List<String> _commonPathologies = [
    'Diabetes',
    'Hipertensión',
    'Artritis',
    'Marcapasos',
    'Material de Osteosíntesis',
    'Ninguna',
  ];

  bool _isLoading = false;

  // Lógica para el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
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

  Future<void> _savePatient() async {
    // 1. Validación expandida
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().length < 6 ||
        _selectedDOB == null ||
        _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Llena todos los campos clave (Nombre, Correo, Contraseña, Fecha Nac., Sexo).',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String physioId = FirebaseAuth.instance.currentUser!.uid;
      final physioRef = FirebaseFirestore.instance
          .collection('physiotherapists')
          .doc(physioId);

      // 2. Validar límite de plan gratuito (INTACTO)
      final physioDoc = await physioRef.get();
      final physioData = physioDoc.data() as Map<String, dynamic>;
      final String plan = physioData['plan'] ?? 'free';
      final int currentCount = physioData['patientCount'] ?? 0;

      if (plan == 'free' && currentCount >= 15) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaywallScreen()),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 3. Crear una segunda app de Firebase temporal (INTACTO)
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryPatientCreation',
        options: Firebase.app().options,
      );

      // 4. Crear el usuario en Authentication usando la app temporal (INTACTO)
      UserCredential userCredential =
          await FirebaseAuth.instanceFor(
            app: tempApp,
          ).createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final String newPatientId = userCredential.user!.uid;

      // 5. Destruir la app temporal inmediatamente por seguridad (INTACTO)
      await tempApp.delete();

      // 6. Guardar el documento del paciente en Firestore (EXPANDIDO CON DATOS CLÍNICOS)
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(newPatientId)
          .set({
            // Datos de sistema y acceso
            'physioId': physioId,
            'email': _emailController.text.trim(),
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'patientType': _selectedPatientType,

            // Ficha Clínica Fija
            'fullName': _nameController.text.trim(),
            'dateOfBirth': Timestamp.fromDate(_selectedDOB!),
            'gender': _selectedGender,
            'occupation': _occupationController.text.trim(),
            'emergencyContact': {
              'name': _emergencyNameController.text.trim(),
              'phone': _emergencyPhoneController.text.trim(),
            },
            'pathologies': _selectedPathologies,
          });

      // 7. Actualizar el contador del fisio (INTACTO)
      await physioRef.update({'patientCount': FieldValue.increment(1)});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expediente y credenciales creados con éxito ✅'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _occupationController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  InputDecoration _premiumInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.teal),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Nuevo Paciente',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Genera el acceso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: darkSlate,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea las credenciales y la ficha médica base de tu paciente.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // SECCIÓN 1: CREDENCIALES
            const Text(
              'CREDENCIALES DE ACCESO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _premiumInput(
                      'Correo del Paciente',
                      Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: _premiumInput(
                      'Contraseña Temporal',
                      Icons.lock_outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPatientType,
                    decoration: _premiumInput(
                      'Enfoque / Tipo',
                      Icons.category_outlined,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.teal,
                    ),
                    items: _patientTypes
                        .map(
                          (String type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedPatientType = newValue);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // SECCIÓN 2: FICHA MÉDICA FIJA
            const Text(
              'FICHA MÉDICA BASE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _premiumInput(
                      'Nombre Completo',
                      Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selector de Fecha Integrado
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(16),
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
                                : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDOB!),
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDOB == null
                                  ? Colors.grey.shade500
                                  : darkSlate,
                            ),
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
                    onChanged: (newValue) =>
                        setState(() => _selectedGender = newValue),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _occupationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _premiumInput('Ocupación', Icons.work_outline),
                  ),
                  const SizedBox(height: 24),

                  // Patologías
                  const Text(
                    'Antecedentes Patológicos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkSlate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _commonPathologies.map((pathology) {
                      final isSelected = _selectedPathologies.contains(
                        pathology,
                      );
                      return FilterChip(
                        label: Text(
                          pathology,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.teal.shade900
                                : Colors.grey.shade700,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.teal.shade100,
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

                  // Emergencia
                  const Text(
                    'Contacto de Emergencia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkSlate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emergencyNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _premiumInput(
                      'Nombre del contacto',
                      Icons.health_and_safety_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _premiumInput(
                      'Teléfono de emergencia',
                      Icons.phone_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // MENSAJE DE CUOTA PREMIUM
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkSlate.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: darkSlate.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: darkSlate, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestión de Cuota',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkSlate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Crear un expediente consume 1 espacio. Los espacios no se recuperan al archivar para preservar el historial médico.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.grey.shade100,
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _savePatient,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Generar Acceso y Expediente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
