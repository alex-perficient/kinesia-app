import 'package:flutter/material.dart';
// Asegúrate de que esta ruta apunte correctamente a tu archivo actual:
import 'dashboard_screen.dart'; 

class MainPhysioScreen extends StatefulWidget {
  const MainPhysioScreen({super.key});

  @override
  State<MainPhysioScreen> createState() => _MainPhysioScreenState();
}

class _MainPhysioScreenState extends State<MainPhysioScreen> {
  int _selectedIndex = 0;

  // Lista de las "Habitaciones" de nuestra app
  final List<Widget> _screens = [
    const DashboardPhysioScreen(), // Índice 0: Tu pantalla actual (Intacta)
    const Center(child: Text('📅 Calendario (En Construcción)', style: TextStyle(fontSize: 18, color: Colors.grey))), // Índice 1
    const Center(child: Text('📚 Biblioteca (En Construcción)', style: TextStyle(fontSize: 18, color: Colors.grey))), // Índice 2
    const Center(child: Text('⚙️ Perfil y Ajustes (En Construcción)', style: TextStyle(fontSize: 18, color: Colors.grey))), // Índice 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Muestra la pantalla según el botón presionado
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // Evita que los íconos se muevan o se oculten
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Pacientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Biblioteca',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}