import 'package:flutter/material.dart';

class AssistPage extends StatelessWidget {
  AssistPage({Key? key}) : super(key: key);

  // Assistance topics and solutions
  final List<Map<String, String>> assistanceTopics = [
    {
      "title": "How to place an order?",
      "solution": "Navigate to the Menu, select items, add them to your cart, and proceed to checkout."
    },
    {
      "title": "How to contact us?",
      "solution": "You can contact us via the 'Contact Us' page or email us at bikaembilipitiya@gmail.com."
    },
    {
      "title": "How to update profile?",
      "solution": "Go to the Profile section, click Edit Profile, make changes, and save them."
    },
    {
      "title": "How to add items to the cart?",
      "solution": "On the product page, click the Add to Cart button. The item will be added to your cart."
    },
    {
      "title": "How to track your order?",
      "solution": "Navigate to the Orders section, find your order, and view its status."
    },
  ];

  // Method to show solution popup
  void showSolutionDialog(BuildContext context, String title, String solution) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(solution),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistance'),
        backgroundColor: Colors.amber,
      ),
      body: ListView.builder(
        itemCount: assistanceTopics.length,
        itemBuilder: (context, index) {
          final topic = assistanceTopics[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(
                topic['title']!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.help_outline, color: Colors.blue),
              onTap: () {
                showSolutionDialog(context, topic['title']!, topic['solution']!);
              },
            ),
          );
        },
      ),
    );
  }
}
