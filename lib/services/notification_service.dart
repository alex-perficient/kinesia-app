import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  /// Envía una alerta o notificación a la base de datos
  static Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    String type = 'general', // Puede ser 'urgent', 'info', 'general'
    String? patientId, // Opcional: para saber qué paciente detonó la alerta
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': receiverId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'patientId': patientId,
      });
      debugPrint('Notificación enviada a $receiverId');
    } catch (e) {
      debugPrint('Error al enviar notificación: $e');
    }
  }

  /// Marca una notificación específica como leída
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error al marcar como leída: $e');
    }
  }
}
