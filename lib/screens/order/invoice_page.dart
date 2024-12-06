import 'dart:convert'; // For JSON decoding
import 'dart:io'; // For saving the file
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class InvoicePage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const InvoicePage({Key? key, required this.orderData}) : super(key: key);

  Future<void> downloadInvoice(BuildContext context) async {
    final pdf = pw.Document();
    final List items = orderData['items'] is String
        ? List<Map<String, dynamic>>.from(json.decode(orderData['items']))
        : (orderData['items'] ?? []);
    final double totalPrice =
        double.tryParse(orderData['totalPrice']?.toString() ?? '0') ?? 0.0;

    // Generate the invoice PDF
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BIKA EMBILIPITIYA',
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('No 50, Moraketiya Road,'),
                      pw.Text('Pallegama, Embilipitiya'),
                      pw.Text('Phone: 077-7123766'),
                      pw.Text('Email: bikaembilipitiya@gmail.com'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                            fontSize: 28, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Invoice #: ${orderData['id']}'),
                      pw.Text(
                        'Invoice Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                      ),
                      pw.Text('P.O.#: 12345'),
                      pw.Text('Due Date: 15 days from issue'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Billing and Shipping Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill To:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(orderData['userEmail'] ?? 'Guest'),
                      pw.Text(orderData['address'] ?? 'N/A'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Deliver To:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(orderData['userEmail'] ?? 'Guest'),
                      pw.Text(orderData['address'] ?? 'N/A'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Table Header
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('QTY',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('DESCRIPTION',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('UNIT PRICE',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('AMOUNT',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(),

              // Table Content
              ...items.map((item) {
                final itemName = item['productName'] ?? 'Unnamed Item';
                final quantity = item['quantity'] ?? 0;
                final price =
                    double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                final total = price * quantity;

                // Add customization options (if any)
                List<pw.Widget> customizationWidgets = [];
                if (item['customizeOptions'] != null) {
                  for (var option in item['customizeOptions']) {
                    double optionPrice =
                        double.tryParse(option['price'].toString()) ?? 0.0;
                    int optionQuantity =
                        int.tryParse(option['quantity'].toString()) ?? 1;
                    customizationWidgets.add(pw.Text(
                        '${option['item']} - Rs. ${optionPrice * optionQuantity}'));
                  }
                }

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('$quantity'),
                        pw.Text(itemName),
                        pw.Text('Rs. ${price.toStringAsFixed(2)}'),
                        pw.Text('Rs. ${total.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (customizationWidgets.isNotEmpty) ...customizationWidgets,
                  ],
                );
              }),

              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Subtotal: Rs. ${totalPrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Footer
              pw.Text('Terms & Conditions:'),
              pw.Text(
                'Payment is due within 15 days.\n'
                'Please make checks payable to: East Repair Inc.',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    try {
      // Save the PDF file
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/invoice_${orderData['id'] ?? 'N/A'}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      Fluttertoast.showToast(
        msg: 'Invoice downloaded successfully to $filePath',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Open the saved file (Optional)
      OpenFile.open(filePath);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to download invoice: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
Widget build(BuildContext context) {
  final List items = orderData['items'] is String
      ? List<Map<String, dynamic>>.from(json.decode(orderData['items']))
      : (orderData['items'] ?? []);

  final double totalPrice =
      double.tryParse(orderData['totalPrice']?.toString() ?? '0') ?? 0.0;

  return Scaffold(
    appBar: AppBar(
      title: const Text('Invoice'),
      backgroundColor: Colors.amber,
      centerTitle: true,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Invoice',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text('Order ID: ${orderData['id'] ?? 'N/A'}'),
          Text('Customer Email: ${orderData['userEmail'] ?? 'Guest'}'),
          Text('Delivery Option: ${orderData['deliveryOption'] ?? 'N/A'}'),
          if (orderData['deliveryOption'] == 'Delivery')
            Text('Address: ${orderData['address'] ?? 'N/A'}'),
          const Divider(height: 30),
          const Text(
            'Items:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No items available'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final itemName = item['productName'] ?? 'Unnamed Item';
                      final quantity = item['quantity'] ?? 0;
                      final price =
                          double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;

                      List<Widget> customizationWidgets = [];
                      if (item['customizeOptions'] != null) {
                        for (var option in item['customizeOptions']) {
                          customizationWidgets.add(Text(
                              '${option['item']} - Rs. ${option['price']}'));
                        }
                      }

                      return Card(
                        child: ListTile(
                          title: Text(itemName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quantity: $quantity'),
                              Text('Price: Rs. ${price.toStringAsFixed(2)}'),
                              ...customizationWidgets,
                            ],
                          ),
                          trailing: Text('Total: Rs. ${(price * quantity).toStringAsFixed(2)}'),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 30),

          // Center the total and the button
          Center(
            child: Column(
              children: [
                Text(
                  'Total: Rs. ${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => downloadInvoice(context),
                  child: const Text('Download Invoice'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


}
