import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteOrdersPage extends StatefulWidget {
  const FavoriteOrdersPage({Key? key}) : super(key: key);

  @override
  _FavoriteOrdersPageState createState() => _FavoriteOrdersPageState();
}

class _FavoriteOrdersPageState extends State<FavoriteOrdersPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> favoriteOrders = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchFavoriteOrders();
  }

  Future<void> fetchFavoriteOrders() async {
    if (user == null) {
      setState(() {
        error = "User is not logged in.";
        isLoading = false;
      });
      return;
    }

    try {
      // Fetch confirmed orders
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('confirmedOrders')
          .where('userEmail', isEqualTo: user!.email)
          .get();

      final ordersMap = <String, Map<String, dynamic>>{};

      // Process orders and count occurrences of each product
      for (var doc in orderSnapshot.docs) {
        final items = List<Map<String, dynamic>>.from(doc['items'] ?? []);
        for (var item in items) {
          final productName = item['productName'];
          if (!ordersMap.containsKey(productName)) {
            ordersMap[productName] = {
              ...item,
              'orderCount': 0,
            };
          }
          ordersMap[productName]!['orderCount'] += 1;
        }
      }

      // Filter for products ordered at least 3 times
      final favoriteOrders = ordersMap.values
          .where((order) => order['orderCount'] >= 3)
          .toList();

      // Fetch product images from the Menu collection
      final menuSnapshot = await FirebaseFirestore.instance.collection('Menu').get();
      final menuItems = {for (var doc in menuSnapshot.docs) doc['productName']: doc['image']};

      // Assign images to favorite orders
      final favoriteOrdersWithImages = favoriteOrders.map((order) {
        return {
          ...order,
          'productImage': menuItems[order['productName']] ?? null,
        };
      }).toList();

      setState(() {
        this.favoriteOrders = favoriteOrdersWithImages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Error fetching favorite orders. Please try again.";
        isLoading = false;
      });
      print("Error fetching favorite orders: $e");
    }
  }

  void handleCardClick(Map<String, dynamic> order) {
    final formattedProductName = order['productName']
        .toString()
        .toLowerCase()
        .replaceAll(' ', '-');
    print("Navigating to: /menu-details/$formattedProductName");
    // Add your navigation logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Orders'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : favoriteOrders.isEmpty
                  ? const Center(
                      child: Text("No favorite orders found."),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3 / 4,
                      ),
                      itemCount: favoriteOrders.length,
                      itemBuilder: (context, index) {
                        final order = favoriteOrders[index];
                        return GestureDetector(
                          onTap: () => handleCardClick(order),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: order['productImage'] != null
                                      ? Image.network(
                                          order['productImage'],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : const Center(
                                          child: Text("No Image Available"),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order['productName'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Ordered ${order['orderCount']} times",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Price: Rs.${order['price']}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
