import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinesia_app/services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverId', isEqualTo: userId)
            // No usamos orderBy aquí para no requerir un índice compuesto en la nube
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          
          // Ordenamiento local: Las más recientes primero
          docs.sort((a, b) {
            final tA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final tB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });

          if (docs.isEmpty) {
            return const Center(child: Text('No tienes notificaciones nuevas.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final isRead = data['isRead'] ?? true;

              return ListTile(
                // Cambiamos el color del fondo si no está leída
                tileColor: isRead ? Colors.transparent : Colors.teal.shade50,
                leading: Icon(
                  isRead ? Icons.notifications_none : Icons.notifications_active,
                  color: isRead ? Colors.grey : Colors.teal,
                ),
                title: Text(
                  data['title'] ?? '', 
                  style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)
                ),
                subtitle: Text(data['body'] ?? ''),
                onTap: () {
                  // Si no está leída, al tocarla le avisamos al cartero que la marque como leída
                  if (!isRead) {
                    NotificationService.markAsRead(docId);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}