import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> userOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserOrders();
  }

  Future<void> fetchUserOrders() async {
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('OrderNow')
          .where('userEmail', isEqualTo: user!.email)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = querySnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();

      setState(() {
        userOrders = orders;
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching user orders: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Safely parse dynamic values to double
  double parseToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : userOrders.isEmpty
                ? const Center(
                    child: Text(
                      'No orders found.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: userOrders.length,
                    itemBuilder: (context, index) {
                      final order = userOrders[index];
                      final totalPrice = parseToDouble(order['totalPrice']);
                      final createdAt =
                          (order['createdAt'] as Timestamp).toDate();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text('Order ID: ${order['orderId']}'),
                          subtitle: Text(
                            'Total: Rs.${totalPrice.toStringAsFixed(2)}\nDate: ${createdAt.toLocal()}',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailsPage(
                                  order: order,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  // Safely parse dynamic values to double
  double parseToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List<dynamic>? ?? [];
    final totalPrice = parseToDouble(order['totalPrice']);
    final createdAt = (order['createdAt'] as Timestamp).toDate();
    final deliveryOption = order['deliveryOption'] ?? 'Unknown';

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Information
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID: ${order['orderId']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${createdAt.toLocal()}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Delivery Option: $deliveryOption',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (deliveryOption == 'Delivery' &&
                          order['address'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Delivery Address: ${order['address']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Items List
              Text(
                'Order Items',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final basePrice = parseToDouble(item['price']);
                  final discount = parseToDouble(item['discount']);
                  final customizePrice = parseToDouble(item['customizePrice']);
                  final quantity = item['quantity'] ?? 1;

                  final discountedPrice = basePrice * ((100 - discount) / 100);
                  final totalItemPrice =
                      (discountedPrice + customizePrice) * quantity;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        item['productName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantity: $quantity'),
                          Text(
                            'Item Total: Rs.${totalItemPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        'Rs.${basePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Total Price
              Card(
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  title: const Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    'Rs.${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
