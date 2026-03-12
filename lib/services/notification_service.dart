import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  // Función maestra para enviar notificaciones a cualquier usuario
  static Future<void> sendNotification({
    required String receiverId, // A quién va dirigida (ID del paciente o del fisio)
    required String title,      // Ej. "Nueva Rutina"
    required String body,       // Ej. "Alejandro te ha asignado 3 ejercicios."
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': receiverId,
        'title': title,
        'body': body,
        'isRead': false, // Por defecto nace como "No leída"
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error al enviar notificación: $e');
    }
  }

  // Función para marcar una notificación como leída
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error al actualizar notificación: $e');
    }
  }
}