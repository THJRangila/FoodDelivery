import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../order/order_now_page.dart'; // Import your OrderNowPage

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> cartItems = [];
  List<String> selectedItems = [];
  bool isLoading = true;
  String menuMessage = '';

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .collection('cart')
          .get();

      setState(() {
        cartItems = snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        }).toList();
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching cart items: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Helper function to parse values to double
  double parseToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper function to parse values to int
  int parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Function to handle quantity update
  Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (user == null || newQuantity < 1) return;

    try {
      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .collection('cart')
          .doc(itemId)
          .update({'quantity': newQuantity});

      // Update local state
      setState(() {
        final index = cartItems.indexWhere((item) => item['id'] == itemId);
        if (index != -1) {
          cartItems[index]['quantity'] = newQuantity;
        }
        menuMessage = 'Quantity updated successfully!';
      });
    } catch (error) {
      print('Error updating quantity: $error');
      setState(() {
        menuMessage = 'Failed to update quantity. Please try again.';
      });
    }
  }

  void handleSelectItem(String itemId) {
    setState(() {
      if (selectedItems.contains(itemId)) {
        selectedItems.remove(itemId);
      } else {
        selectedItems.add(itemId);
      }
    });
  }

  void handleCheckout() {
    final selectedCartItems =
        cartItems.where((item) => selectedItems.contains(item['id'])).toList();

    if (selectedCartItems.isEmpty) {
      setState(() {
        menuMessage = 'Please select at least one item to proceed to checkout.';
      });
      return;
    }

    // Navigate to OrderNowPage with selectedCartItems
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderNowPage(
          orderItems: selectedCartItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : cartItems.isEmpty
            ? const Center(
                child: Text(
                  'Your cart is empty.',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final basePrice = parseToDouble(item['price']);
                        final discount = parseToDouble(item['discount']);
                        final quantity = parseToInt(item['quantity']);
                        final discountedPrice =
                            basePrice * ((100 - discount) / 100);
                        final totalPrice = discountedPrice * quantity;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: selectedItems.contains(item['id']),
                                      onChanged: (_) {
                                        handleSelectItem(item['id']);
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        item['productName'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        // Delete functionality
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user!.email)
                                            .collection('cart')
                                            .doc(item['id'])
                                            .delete();
                                        setState(() {
                                          cartItems.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Base Price: Rs. $basePrice'),
                                    Text('Discount: $discount%'),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Quantity: $quantity'),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            if (quantity > 1) {
                                              updateQuantity(
                                                  item['id'], quantity - 1);
                                            }
                                          },
                                        ),
                                        Text('$quantity'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            updateQuantity(
                                                item['id'], quantity + 1);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text('Total Price: Rs. $totalPrice'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber, // Yellow theme
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 16.0),
                        
                      ),
                      onPressed: handleCheckout,
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (menuMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        menuMessage,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              );
  }
}
