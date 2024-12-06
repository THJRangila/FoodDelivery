import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../order/order_now_page.dart';

class MenuDetailsPage extends StatefulWidget {
  final String menuType;

  const MenuDetailsPage({Key? key, required this.menuType}) : super(key: key);

  @override
  _MenuDetailsPageState createState() => _MenuDetailsPageState();
}

class _MenuDetailsPageState extends State<MenuDetailsPage> {
  List<Map<String, dynamic>> menuItems = [];
  Map<String, int> quantities = {};
  Map<String, List<Map<String, dynamic>>> selectedCustomizeOptions = {}; // Multiple customizations
  Map<String, Map<String, int>> customizeQuantities = {}; // Quantities for each customize item
  bool isLoading = true;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchMenuItems();
  }

  Future<void> fetchMenuItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Menu')
          .where('menuType', isEqualTo: widget.menuType)
          .get();

      final items = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();

      setState(() {
        menuItems = items;
        quantities = {for (var item in items) item['id']: 1};
        selectedCustomizeOptions = {
          for (var item in items) item['id']: [],
        };
        customizeQuantities = {
          for (var item in items) item['id']: {},
        };
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching menu items: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleCustomizeChange(String itemId, dynamic value) {
    setState(() {
      if (selectedCustomizeOptions[itemId]?.contains(value) ?? false) {
        selectedCustomizeOptions[itemId]?.remove(value);
      } else {
        selectedCustomizeOptions[itemId]?.add(value);
      }

      // Reset the quantity for the newly added option
      if (customizeQuantities[itemId] != null &&
          !customizeQuantities[itemId]!.containsKey(value['item'])) {
        customizeQuantities[itemId]![value['item']] = 1;
      }
    });
  }

  void increaseQuantity(String itemId) {
    setState(() {
      quantities[itemId] = (quantities[itemId] ?? 1) + 1;
    });
  }

  void decreaseQuantity(String itemId) {
    setState(() {
      if (quantities[itemId]! > 1) {
        quantities[itemId] = quantities[itemId]! - 1;
      }
    });
  }

  void increaseCustomizeQuantity(String itemId, String customizeItem) {
    setState(() {
      if (customizeQuantities[itemId] != null) {
        customizeQuantities[itemId]![customizeItem] =
            customizeQuantities[itemId]![customizeItem]! + 1;
      }
    });
  }

  void decreaseCustomizeQuantity(String itemId, String customizeItem) {
    setState(() {
      if (customizeQuantities[itemId] != null &&
          customizeQuantities[itemId]![customizeItem]! > 1) {
        customizeQuantities[itemId]![customizeItem] =
            customizeQuantities[itemId]![customizeItem]! - 1;
      }
    });
  }

  Future<void> addToCart(Map<String, dynamic> item) async {
  if (user == null) {
    Fluttertoast.showToast(msg: "Please log in to add items to the cart.");
    return;
  }

  try {
    final cartCollection = FirebaseFirestore.instance
        .collection('users/${user!.email}/cart');

    // Check if the item already exists in the cart
    final querySnapshot = await cartCollection
        .where('productName', isEqualTo: item['productName'])
        .get();

    // Prepare customize details
    List<Map<String, dynamic>> customizeDetails = selectedCustomizeOptions[item['id']]?.map((option) {
      return {
        'item': option['item'],
        'price': option['price'],
        'quantity': customizeQuantities[item['id']]?[option['item']] ?? 1,
        'timestamp': DateTime.now().toString(), // Adding timestamp
      };
    }).toList() ?? [];

    if (querySnapshot.docs.isNotEmpty) {
      // If item exists in the cart, update the quantity
      final existingDoc = querySnapshot.docs.first;
      final existingQuantity = existingDoc['quantity'] ?? 0;

      await existingDoc.reference.update({
        'quantity': existingQuantity + quantities[item['id']]!,
        'customizeOptions': customizeDetails, // Update customizations
      });

      Fluttertoast.showToast(
        msg: '${item['productName']} quantity updated in cart.',
      );
    } else {
      // Add a new item to the cart
      await cartCollection.add({
        'productName': item['productName'],
        'quantity': quantities[item['id']]!,
        'price': item['price'],
        'discount': item['discount'] ?? 0,
        'customizeOptions': customizeDetails, // Add customizations
        'timestamp': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(msg: '${item['productName']} added to cart.');
    }
  } catch (error) {
    print('Error adding to cart: $error');
    Fluttertoast.showToast(msg: "Failed to add item to cart.");
  }
}


  void buyNow(Map<String, dynamic> item) {
    if (user == null) {
      Fluttertoast.showToast(msg: "Please log in to proceed.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderNowPage(
          orderItems: [
            {
              'productName': item['productName'],
              'quantity': quantities[item['id']]!,
              'price': item['price'],
              'discount': item['discount'] ?? 0,
              'customizeOptions': selectedCustomizeOptions[item['id']]?.map((option) {
                return {
                  'item': option['item'],
                  'price': option['price'],
                  'quantity': customizeQuantities[item['id']]?[option['item']] ?? 1,
                };
              }).toList() ?? [], // Ensure it's not null
            }
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuType),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final customizeOptions =
                    item['customizeItems'] as List<dynamic>? ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  child: Column(
                    children: [
                      // Image
                      Image.network(
                        item['image'] ?? '',
                        fit: BoxFit.cover,
                        height: 150,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 80),
                          );
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name and Price
                            Text(
                              item['productName'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Rs. ${item['price']}'),

                            // Dropdown for Customize Options (Multiple)
                            if (customizeOptions.isNotEmpty)
                              Column(
                                children: customizeOptions.map((option) {
                                  final itemId = item['id'];
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${option['item']} - Rs. ${option['price']}',
                                          ),
                                          Checkbox(
                                            value: selectedCustomizeOptions[
                                                    itemId]?.contains(option) ??
                                                false,
                                            onChanged: (bool? value) {
                                              handleCustomizeChange(
                                                  itemId, option);
                                            },
                                          ),
                                        ],
                                      ),
                                      // Quantity selector for each customization
                                      if (selectedCustomizeOptions[itemId]
                                              ?.contains(option) ??
                                          false)
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () => decreaseCustomizeQuantity(
                                                  itemId, option['item']),
                                            ),
                                            Text(
                                                '${customizeQuantities[itemId]?[option['item']] ?? 1}'),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () => increaseCustomizeQuantity(
                                                  itemId, option['item']),
                                            ),
                                          ],
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),

                            // Quantity Selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () =>
                                          decreaseQuantity(item['id']),
                                    ),
                                    Text('${quantities[item['id']]}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () =>
                                          increaseQuantity(item['id']),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => addToCart(item),
                                      child: const Text('Add to Cart'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => buyNow(item),
                                      child: const Text('Buy Now'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
