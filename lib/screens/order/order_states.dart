import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderStatesPage extends StatefulWidget {
  const OrderStatesPage({Key? key}) : super(key: key);

  @override
  _OrderStatesPageState createState() => _OrderStatesPageState();
}

class _OrderStatesPageState extends State<OrderStatesPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> notifications = [];
  Map<String, dynamic>? selectedMessage;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    if (user == null) {
      setState(() {
        errorMessage = "User is not authenticated. Please log in.";
        isLoading = false;
      });
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("notifications")
          .where("userEmail", isEqualTo: user!.email)
          .get();

      final fetchedNotifications = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      setState(() {
        notifications = fetchedNotifications
            .where((notification) => !(notification['message'] as String)
                .contains("Reminder: You have"))
            .toList()
          ..sort((a, b) => (b['timestamp'] as DateTime)
              .compareTo(a['timestamp'] as DateTime));
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = "Error fetching notifications.";
        isLoading = false;
      });
      debugPrint("Error fetching notifications: $error");
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final docRef = FirebaseFirestore.instance.collection("notifications").doc(id);
      await docRef.update({'read': true});
      setState(() {
        notifications = notifications.map((message) {
          if (message['id'] == id) {
            message['read'] = true;
          }
          return message;
        }).toList();
      });
    } catch (error) {
      debugPrint("Error marking message as read: $error");
    }
  }

  void openMessageModal(Map<String, dynamic> message) {
    setState(() {
      selectedMessage = message;
    });
    if (!(message['read'] as bool)) {
      markAsRead(message['id']);
    }
  }

  void closeModal() {
    setState(() {
      selectedMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Status"),
        backgroundColor: const Color.fromARGB(255, 253, 186, 1),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : notifications.isEmpty
                  ? const Center(child: Text("No notifications found."))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final message = notifications[index];
                              final isRead = message['read'] as bool;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 3,
                                child: ListTile(
                                  title: Text(
                                    message['message'] ?? 'No message',
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${(message['timestamp'] as DateTime).toLocal()}",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: Icon(
                                    isRead
                                        ? Icons.check_circle_outline
                                        : Icons.notifications_active,
                                    color: isRead ? Colors.green : const Color.fromARGB(255, 255, 200, 2),
                                  ),
                                  onTap: () => openMessageModal(message),
                                ),
                              );
                            },
                          ),
                        ),
                        if (selectedMessage != null)
                          GestureDetector(
                            onTap: closeModal,
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    width: 300,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Message Details",
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text("Order ID: ${selectedMessage!['orderId']}"),
                                        const SizedBox(height: 4.0),
                                        Text("Message: ${selectedMessage!['message']}"),
                                        const SizedBox(height: 4.0),
                                        Text(
                                          "Date: ${(selectedMessage!['timestamp'] as DateTime).toLocal()}",
                                        ),
                                        const SizedBox(height: 4.0),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton(
                                            onPressed: closeModal,
                                            child: const Text("Close"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
