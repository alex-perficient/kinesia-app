import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importamos las pantallas que vivirán en cada pestaña
import 'patient_home_screen.dart';
import 'patient_run_tracker_screen.dart';
import 'patient_diet_screen.dart';

class MainPatientScreen extends StatefulWidget {
  const MainPatientScreen({super.key});

  @override
  State<MainPatientScreen> createState() => _MainPatientScreenState();
}

class _MainPatientScreenState extends State<MainPatientScreen> {
  int _selectedIndex = 0;
  late final String currentUserId;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Aquí inyectamos las 4 pantallas de la barra de navegación
    _screens = [
      const PatientHomeScreen(),
      const PatientRunTrackerScreen(), // El mapa de GPS
      PatientDietScreen(patientId: currentUserId),
      const Center(
        child: Text(
          'Pantalla de Perfil en Construcción 🛠️',
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      ), // Placeholder temporal
    ];
  }

  @override
  Widget build(BuildContext context) {
    //const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.tealAccent.shade400.withValues(alpha: 0.3),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.home, color: Colors.teal),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.directions_run, color: Colors.teal),
            label: 'Cardio',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.restaurant, color: Colors.teal),
            label: 'Nutrición',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.grey),
            selectedIcon: Icon(Icons.person, color: Colors.teal),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
