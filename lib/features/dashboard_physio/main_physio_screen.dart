import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; 
import 'routine_library_screen.dart';
import 'physio_calendar_screen.dart';

class MainPhysioScreen extends StatefulWidget {
  const MainPhysioScreen({super.key});

  @override
  State<MainPhysioScreen> createState() => _MainPhysioScreenState();
}

class _MainPhysioScreenState extends State<MainPhysioScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardPhysioScreen(), 
    const PhysioCalendarScreen(), 
    const RoutineLibraryScreen(), 
    const Center(child: Text('⚙️ Perfil y Ajustes (En Construcción)', style: TextStyle(fontSize: 18, color: Colors.grey))), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      // LA NUEVA BARRA DE NAVEGACIÓN MATERIAL 3 (Estilo Premium)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.teal.shade100, // La píldora que envuelve el ícono activo
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha:0.5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.people, color: Colors.teal),
            label: 'Pacientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.calendar_month, color: Colors.teal),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.library_books, color: Colors.teal),
            label: 'Biblioteca',
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