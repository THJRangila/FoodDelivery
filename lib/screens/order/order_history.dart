import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> orderHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrderHistory();
  }

  Future<void> fetchOrderHistory() async {
  if (user == null) return;

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('confirmedOrders')
        .where('userEmail', isEqualTo: user!.email)
        .get();

    final orders = querySnapshot.docs.map((doc) {
      final data = doc.data();
      String formattedTimestamp = 'No timestamp available';

      if (data['timestamp'] != null) {
        final timestamp = data['timestamp'];
        if (timestamp is Timestamp) {
          formattedTimestamp = timestamp.toDate().toLocal().toString();
        } else if (timestamp is Map && timestamp.containsKey('seconds')) {
          final seconds = timestamp['seconds'] as int;
          formattedTimestamp =
              DateTime.fromMillisecondsSinceEpoch(seconds * 1000).toLocal().toString();
        }
      }

      return {
        'id': doc.id, // Use `doc.id` for the document ID
        'userEmail': data['userEmail'] ?? 'Unknown',
        'items': data['items'] ?? [],
        'totalPrice': data['totalPrice'] ?? 0.0,
        'status': data['status'] ?? 'Confirmed',
        'timestamp': formattedTimestamp,
      };
    }).toList();

    setState(() {
      orderHistory = orders;
      isLoading = false;
    });
  } catch (error) {
    // Handle any error here
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: const Color.fromARGB(255, 255, 179, 1),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : orderHistory.isEmpty
              ? const Center(
                  child: Text(
                    'No order history found.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: orderHistory.length,
                  itemBuilder: (context, index) {
                    final order = orderHistory[index];
                    final items = order['items'] as List;
                    final itemNames = items.isNotEmpty
                        ? items.map((item) => item['productName']).join(', ')
                        : 'No items available';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order ID: ${order['id']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('User Email: ${order['userEmail']}'),
                            const SizedBox(height: 8),
                            Text('Products: $itemNames'),
                            const SizedBox(height: 8),
                            Text(
                              'Total Price: Rs.${order['totalPrice'].toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            Text('Status: ${order['status']}'),
                            const SizedBox(height: 8),
                            Text('Timestamp: ${order['timestamp']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
