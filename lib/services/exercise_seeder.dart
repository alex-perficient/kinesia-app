import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ExerciseSeeder {
  static Future<void> seedDatabase() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final WriteBatch batch = firestore.batch();
    final CollectionReference exercisesRef = firestore.collection(
      'global_exercises',
    );

    // Aquí está nuestra "Materia Prima" de conocimientos biomecánicos
    final List<Map<String, dynamic>> globalExercises = [
      {
        'name': 'Sentadilla Búlgara',
        'category': 'Fuerza',
        'primaryMuscle': 'Cuádriceps / Glúteo',
        'equipment': 'Peso Corporal / Mancuernas',
        'difficulty': 'Intermedio',
        'description':
            'Apoya un pie en un banco trasero y desciende controlando el peso con la pierna delantera. Excelente para desequilibrios musculares.',
        'videoUrl': '', // Espacio para tus futuros videos
      },
      {
        'name': 'Puente de Glúteo (Glute Bridge)',
        'category': 'Rehabilitación',
        'primaryMuscle': 'Glúteo Mayor',
        'equipment': 'Peso Corporal',
        'difficulty': 'Principiante',
        'description':
            'Acostado boca arriba con rodillas flexionadas, eleva la cadera contrayendo los glúteos. Fundamental para dolor lumbar y amnesia glútea.',
        'videoUrl': '',
      },
      {
        'name': 'Rotación Externa de Hombro',
        'category': 'Rehabilitación',
        'primaryMuscle': 'Manguito Rotador',
        'equipment': 'Banda Elástica',
        'difficulty': 'Principiante',
        'description':
            'Pega el codo a las costillas y tira de la banda hacia afuera. Vital para la estabilidad del hombro.',
        'videoUrl': '',
      },
      {
        'name': 'Plancha Abdominal (Plank)',
        'category': 'Fuerza',
        'primaryMuscle': 'Core / Transverso Abdominal',
        'equipment': 'Peso Corporal',
        'difficulty': 'Intermedio',
        'description':
            'Mantén la columna neutra apoyando antebrazos y puntas de los pies. Evita arquear la zona lumbar.',
        'videoUrl': '',
      },
      {
        'name': 'Extensión de Cuádriceps (Isométrica)',
        'category': 'Rehabilitación',
        'primaryMuscle': 'Cuádriceps',
        'equipment': 'Ninguno',
        'difficulty': 'Principiante',
        'description':
            'Sentado, extiende la rodilla por completo y mantén la contracción durante 5 segundos. Ideal post-cirugía de rodilla.',
        'videoUrl': '',
      },
      {
        'name': 'Remo con Banda Elástica',
        'category': 'Rehabilitación',
        'primaryMuscle': 'Dorsal Ancho / Romboides',
        'equipment': 'Banda Elástica',
        'difficulty': 'Principiante',
        'description':
            'Tracciona la banda hacia el ombligo juntando las escápulas. Ayuda a corregir la postura encorvada.',
        'videoUrl': '',
      },
      {
        'name': 'Movilidad Gato-Camello',
        'category': 'Movilidad',
        'primaryMuscle': 'Columna Vertebral',
        'equipment': 'Peso Corporal',
        'difficulty': 'Principiante',
        'description':
            'En posición de cuadrupedia, arquea la espalda hacia arriba (gato) y luego húndela hacia abajo (camello) lentamente.',
        'videoUrl': '',
      },
      {
        'name': 'Elevación de Talones',
        'category': 'Fuerza',
        'primaryMuscle': 'Pantorrillas (Gastrocnemios)',
        'equipment': 'Peso Corporal / Escalón',
        'difficulty': 'Principiante',
        'description':
            'Eleva los talones soportando el peso en las puntas de los pies. Baja lentamente. Refuerza el tendón de Aquiles.',
        'videoUrl': '',
      },
      {
        'name': 'Estiramiento de Isquiotibiales',
        'category': 'Flexibilidad',
        'primaryMuscle': 'Isquiotibiales',
        'equipment': 'Ninguno',
        'difficulty': 'Principiante',
        'description':
            'Sentado o de pie, inclínate hacia adelante desde la cadera manteniendo la espalda recta hasta sentir tensión en la parte posterior del muslo.',
        'videoUrl': '',
      },
      {
        'name': 'Press Militar con Mancuernas',
        'category': 'Fuerza',
        'primaryMuscle': 'Deltoides',
        'equipment': 'Mancuernas',
        'difficulty': 'Intermedio',
        'description':
            'Empuja las mancuernas por encima de la cabeza hasta extender los brazos por completo. Mantén el core firme.',
        'videoUrl': '',
      },
    ];

    try {
      for (var exercise in globalExercises) {
        // Generamos un nuevo documento vacío y obtenemos su referencia
        DocumentReference docRef = exercisesRef.doc();
        // Le agregamos un timestamp de creación
        exercise['createdAt'] = FieldValue.serverTimestamp();
        // Agregamos la operación de escritura al lote (batch)
        batch.set(docRef, exercise);
      }

      // Ejecutamos todas las escrituras de un solo golpe
      await batch.commit();
      if (kDebugMode) {
        print(
          '✅ ¡Semilla plantada! ${globalExercises.length} ejercicios inyectados en Firestore.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inyectando ejercicios: $e');
      }
    }
  }
}
