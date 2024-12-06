import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'invoice_page.dart';
import 'dart:math';

class OrderNowPage extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;

  const OrderNowPage({Key? key, required this.orderItems}) : super(key: key);

  @override
  _OrderNowPageState createState() => _OrderNowPageState();
}

class _OrderNowPageState extends State<OrderNowPage> {
  double totalPrice = 0.0;
  TextEditingController addressController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  String deliveryOption = 'Take Away'; // Default to Take Away

  @override
  void initState() {
    super.initState();
    calculateTotalPrice();
    fetchUserAddress(); // Fetch user's address if logged in
  }

  // Fetch user's address from Firestore (if available)
  Future<void> fetchUserAddress() async {
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        final userAddress = userDoc.data()?['address'] ?? '';
        setState(() {
          addressController.text = userAddress; // Autofill the address field if available
        });
      }
    } catch (error) {
      print('Error fetching user address: $error');
    }
  }

  // Generate custom order ID
  String generateOrderId() {
    final random = Random();
    const orderPrefix = 'OD';
    final orderNumber = random.nextInt(9999999); // Generates a random number between 0 and 9999999
    return '$orderPrefix${orderNumber.toString().padLeft(7, '0')}'; // Format: ODXXXXXXX
  }

  // Calculate the total price of the order, including customized items
  void calculateTotalPrice() {
    double total = 0.0;
    for (var item in widget.orderItems) {
      double price = double.tryParse(item['price'].toString()) ?? 0.0;
      int quantity = int.tryParse(item['quantity'].toString()) ?? 1;

      total += price * quantity;

      // Add customize item prices if any
      for (var option in item['customizeOptions'] ?? []) {
        double optionPrice = double.tryParse(option['price'].toString()) ?? 0.0;
        int optionQuantity = int.tryParse(option['quantity'].toString()) ?? 1;
        total += optionPrice * optionQuantity;
      }
    }

    setState(() {
      totalPrice = total;
    });
  }

  // Place the order
  Future<void> placeOrder() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please log in to place the order")),
      );
      return;
    }

    if (deliveryOption == 'Delivery' && addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a delivery address")),
      );
      return;
    }

    try {
      final orderData = {
        'id': generateOrderId(),  // Generate custom order ID
        'userEmail': user!.email,
        'userName': user!.displayName ?? 'Guest', // Pass the logged-in user's name
        'items': widget.orderItems.map((item) {
          return {
            'productName': item['productName'],
            'price': item['price'],
            'quantity': item['quantity'],
            'discount': item['discount'] ?? '0',
            'image': item['image'],
            'customizeOptions': item['customizeOptions'] ?? [],  // Include customization options
          };
        }).toList(),
        'totalPrice': totalPrice,
        'address': addressController.text,
        'deliveryOption': deliveryOption,
        'createdAt': FieldValue.serverTimestamp(), // Use Firestore timestamp
      };

      final orderCollection = FirebaseFirestore.instance.collection('OrderNow');

      // Use the generated orderId as the document ID
      await orderCollection.doc(orderData['id'] as String?).set(orderData);

      // Pass the actual orderData to the InvoicePage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => InvoicePage(orderData: orderData)),
      );
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Summary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ We accept cash on delivery only. ⚠️ If you want to cancel the order, contact our hotline within 5 minutes.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Dropdown for selecting 'Take Away' or 'Delivery'
            DropdownButton<String>(
              value: deliveryOption,
              onChanged: (value) {
                setState(() {
                  deliveryOption = value!;
                  if (deliveryOption == 'Delivery') {
                    fetchUserAddress(); // Fetch and autofill address when 'Delivery' is selected
                  } else {
                    addressController.clear(); // Clear address for 'Take Away'
                  }
                });
              },
              items: const [
                DropdownMenuItem(value: 'Take Away', child: Text('Take Away')),
                DropdownMenuItem(value: 'Delivery', child: Text('Delivery')),
              ],
            ),

            // Address input field for Delivery option
            if (deliveryOption == 'Delivery')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Delivery Address',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

            // Display order items
            Expanded(
              child: ListView.builder(
                itemCount: widget.orderItems.length,
                itemBuilder: (context, index) {
                  final item = widget.orderItems[index];
                  final basePrice = double.tryParse(item['price'].toString()) ?? 0.0;
                  final quantity = int.tryParse(item['quantity'].toString()) ?? 1;
                  final totalItemPrice = basePrice * quantity;

                  // Build customization options if available
                  List<Widget> customizationWidgets = [];
                  if (item['customizeOptions'] != null) {
                    for (var option in item['customizeOptions']) {
                      double optionPrice = double.tryParse(option['price'].toString()) ?? 0.0;
                      int optionQuantity = int.tryParse(option['quantity'].toString()) ?? 1;
                      customizationWidgets.add(
                        Text(
                          '${option['item']} - Rs. ${optionPrice * optionQuantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }
                  }

                  return Card(
                    child: ListTile(
                      title: Text(item['productName'] ?? 'Item'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Qty: ${item['quantity']} - Total: Rs.${totalItemPrice.toStringAsFixed(2)}'),
                          ...customizationWidgets, // Show customizations here
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            widget.orderItems.removeAt(index);
                            calculateTotalPrice(); // Recalculate total price after removal
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Centered total price display
            Center(
              child: Text(
                "Total: Rs. $totalPrice",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

            // Centered Place Order Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow, // Yellow background color
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0), // Rounded corners
                  ),
                  elevation: 5, // Adds shadow for a raised effect
                ),
                onPressed: placeOrder,
                child: const Text(
                  "Place Order",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Text color (black to contrast with yellow)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
