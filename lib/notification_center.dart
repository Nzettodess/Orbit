import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firestore_service.dart';
import 'models.dart';

class NotificationCenter extends StatefulWidget {
  final String currentUserId;

  const NotificationCenter({super.key, required this.currentUserId});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<List<AppNotification>>(
        stream: _firestoreService.getNotifications(widget.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: notification.read ? Colors.grey : Colors.blue,
                ),
                title: Text(
                  notification.message,
                  style: TextStyle(
                    fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(notification.timestamp),
                ),
                onTap: () {
                  if (!notification.read) {
                    _firestoreService.markNotificationRead(notification.id);
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
