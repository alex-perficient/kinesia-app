import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinesia_app/services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha blanca asegurada
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Bandeja vacía', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkSlate)),
                  const SizedBox(height: 8),
                  const Text('No tienes notificaciones nuevas.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final isRead = data['isRead'] ?? true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : Colors.teal.shade50.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isRead ? Colors.grey.shade100 : Colors.teal.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.grey.shade50 : Colors.teal.shade50, 
                      shape: BoxShape.circle
                    ),
                    child: Icon(
                      isRead ? Icons.notifications_none : Icons.notifications_active,
                      color: isRead ? Colors.grey : Colors.teal,
                    ),
                  ),
                  title: Text(
                    data['title'] ?? '', 
                    style: TextStyle(fontWeight: isRead ? FontWeight.w600 : FontWeight.w900, color: darkSlate, letterSpacing: -0.5)
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(data['body'] ?? '', style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                  ),
                  onTap: () {
                    // Si no está leída, al tocarla le avisamos al cartero que la marque como leída
                    if (!isRead) {
                      NotificationService.markAsRead(docId);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}