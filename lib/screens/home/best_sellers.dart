import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../order/order_now_page.dart'; // Import your OrderNowPage

class BestSellers extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Promotions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder(
          stream: firestore.collection('web-promos').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No items found'));
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: snapshot.data!.docs.map((doc) {
                  final item = doc.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () {
                      // Navigate to the OrderNowPage with the selected item
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderNowPage(
                            orderItems: [
                              {
                                'productName': item['productName'],
                                'price': item['price'],
                                'image': item['image'],
                                'discount': item['discount'] ?? 0,
                                'quantity': 1, // Default quantity
                              }
                            ],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 4,
                      child: Column(
                        children: [
                          // Product Image
                          Image.network(
                            item['image'],
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 80);
                            },
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),

                          // Product Details
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text('Price: Rs. ${item['price']}'),
                                if (item['discount'] != null)
                                  Text('Discount: ${item['discount']}%'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
