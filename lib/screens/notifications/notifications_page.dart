import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> filteredNotifications = [];
  String activeCategory = 'all';
  Map<String, int> unreadCounts = {
    'all': 0,
    'promotion': 0,
    'customerPromo': 0,
    'contact': 0,
  };

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    if (user == null) return;

    final collections = [
      {'name': 'products', 'type': 'promotion', 'key': 'read'},
      {'name': 'customer-promos', 'type': 'customerPromo', 'key': 'read'},
      {'name': 'contacts', 'type': 'contact', 'key': 'read'},
    ];

    for (var collection in collections) {
      final snapshot = await FirebaseFirestore.instance.collection(collection['name']!).get();

      final data = snapshot.docs.map((doc) {
        final docData = doc.data();
        return {
          'id': doc.id,
          'message': docData['message'] ?? docData['description'] ?? '',
          'timestamp': docData['timestamp'],
          'read': docData[collection['key']] ?? false,
          'type': collection['type'],
        };
      }).toList();

      updateUnreadCounts(data, collection['type']!);
      setState(() {
        notifications.addAll(data);
      });
    }
    filterNotifications();
  }

  void updateUnreadCounts(List<Map<String, dynamic>> data, String type) {
    final unreadCount = data.where((n) => !(n['read'] as bool)).length;
    setState(() {
      unreadCounts[type] = unreadCount;
      unreadCounts['all'] = (unreadCounts['promotion'] ?? 0) +
          (unreadCounts['customerPromo'] ?? 0) +
          (unreadCounts['contact'] ?? 0);
    });
  }

  void filterNotifications() {
    setState(() {
      filteredNotifications = activeCategory == 'all'
          ? notifications
          : notifications.where((n) => n['type'] == activeCategory).toList();
    });
  }

  Future<void> markAsRead(String id, String type) async {
    try {
      final collectionName = type == 'promotion'
          ? 'products'
          : type == 'customerPromo'
              ? 'customer-promos'
              : 'contacts';
      final docRef = FirebaseFirestore.instance.collection(collectionName).doc(id);

      await docRef.update({'read': true});
      setState(() {
        notifications = notifications.map((n) {
          if (n['id'] == id) n['read'] = true;
          return n;
        }).toList();
        filterNotifications();
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> deleteNotification(String id, String type) async {
    try {
      final collectionName = type == 'promotion'
          ? 'products'
          : type == 'customerPromo'
              ? 'customer-promos'
              : 'contacts';
      final docRef = FirebaseFirestore.instance.collection(collectionName).doc(id);

      await docRef.delete();
      setState(() {
        notifications = notifications.where((n) => n['id'] != id).toList();
        filterNotifications();
      });
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color.fromARGB(255, 255, 179, 1),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Filter Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'promotion', 'customerPromo', 'contact']
                  .map((category) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            '${category[0].toUpperCase()}${category.substring(1)} '
                            '${(unreadCounts[category] ?? 0) > 0 ? '(${unreadCounts[category]})' : ''}',
                          ),
                          selected: activeCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              activeCategory = category;
                            });
                            filterNotifications();
                          },
                          selectedColor: const Color.fromARGB(255, 250, 171, 1),
                          backgroundColor: Colors.grey.shade300,
                          labelStyle: TextStyle(
                            color: activeCategory == category
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Notifications List
          Expanded(
            child: filteredNotifications.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      final isRead = notification['read'] as bool;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRead ? Colors.grey : const Color.fromARGB(255, 246, 184, 1),
                            child: Icon(
                              isRead ? Icons.notifications : Icons.notifications_active,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            notification['message'],
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            notification['timestamp'] != null
                                ? DateTime.fromMillisecondsSinceEpoch(
                                        notification['timestamp'].millisecondsSinceEpoch)
                                    .toLocal()
                                    .toString()
                                : 'Unknown date',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => markAsRead(notification['id'], notification['type']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteNotification(notification['id'], notification['type']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'No notifications found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
