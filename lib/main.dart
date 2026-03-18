import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es', null);
  runApp(const KinesiaApp());
}

class KinesiaApp extends StatelessWidget {
  const KinesiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KinesIA',
      debugShowCheckedModeBanner: false,
      theme: _buildPremiumTheme(), // Aplicamos el nuevo ADN Visual
      home: const AuthGate(), 
    );
  }

  // LA MAGIA DEL FACELIFT: El Tema Global Premium
  ThemeData _buildPremiumTheme() {
    // Paleta de colores "High Performance + Clinical"
    const Color primaryTeal = Color(0xFF0D9488); // Un Teal un poco más vibrante y moderno
    const Color darkSlate = Color(0xFF0F172A); // Casi negro/azul marino para textos (Super Premium)
    const Color surfaceGrey = Color(0xFFF8FAFC); // Gris ultra claro para los fondos de la app

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceGrey, // Fondo general limpio
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: const Color(0xFFF97316), // Naranja atlético (Vibe Strava) para acentos
        surface: surfaceGrey,
        onSurface: darkSlate,
      ),
      
      // TIPOGRAFÍA: Pesos fuertes y letras juntas para el look "Deportivo"
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: -1.0),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: darkSlate, letterSpacing: -0.5),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: darkSlate),
        bodyLarge: TextStyle(color: darkSlate),
        bodyMedium: TextStyle(color: Color(0xFF475569)), // Gris pizarra para subtítulos
      ),

      // APP BAR: Plana, moderna, texto oscuro y centrada
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceGrey,
        foregroundColor: darkSlate,
        elevation: 0,
        scrolledUnderElevation: 0, // Evita que se ponga gris al hacer scroll
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: darkSlate,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: darkSlate),
      ),

      // TARJETAS (Cards): Bordes muy curvos, sombras casi invisibles pero elegantes
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),  // withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Curva Strava/Apple
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // BOTONES PRINCIPALES: Altos, gruesos, esquinas redondeadas
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Más altos
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      // BOTONES SECUNDARIOS (Outlined)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 2), // Borde grueso
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      // INPUTS (Formularios): Estilo de "Burbuja" blanca con borde sutil
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
      ),

      // CHIPS (Para las métricas de RPE, EVA, etc.)
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}