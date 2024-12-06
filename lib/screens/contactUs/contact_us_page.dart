import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Showcase Banner
            Container(
              color: Colors.amberAccent,
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                "\"Explore tastes, discover joy.\"",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Contact Details
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Contact Details",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.amber),
                      title: const Text("Phone: 077-7123766"),
                      onTap: () => _launchURL("tel:0777123766"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.amber),
                      title: const Text(
                        "Location: No 50, Moraketiya Road, Pallegama, Embilipitiya",
                      ),
                      onTap: () => _launchURL("https://goo.gl/maps/5qjQwqr5VTE2"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.amber),
                      title: const Text("Email: bikaembilipitiya@gmail.com"),
                      onTap: () => _launchURL("mailto:bikaembilipitiya@gmail.com"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Follow Us Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Give us a follow",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16, // Space between icons
                      runSpacing: 16, // Space between rows of icons
                      children: [
                        GestureDetector(
                          onTap: () => _launchURL(
                              "https://www.instagram.com/asankanchandima?igsh=MTdub3NkdzN3NDV6cg=="),
                          child: Image.asset(
                            'assets/inster.png',
                            height: 50,
                            width: 50, // Adjust size to fit within card
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _launchURL(
                              "https://www.facebook.com/people/Bika-Embilipitiya-Restaurant-%E0%B6%B6%E0%B7%92%E0%B6%9A-%E0%B6%87%E0%B6%B9%E0%B7%92%E0%B6%BD%E0%B7%92%E0%B6%B4%E0%B7%92%E0%B6%A7%E0%B7%92%E0%B6%BA/61551519525412/"),
                          child: Image.asset(
                            'assets/fb.png',
                            height: 50,
                            width: 50, // Adjust size to fit within card
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _launchURL(
                              "https://www.tiktok.com/@biriyanikade?_t=8oxzwrN6MPC&_r=1"),
                          child: Image.asset(
                            'assets/tiktok.png',
                            height: 50,
                            width: 50, // Adjust size to fit within card
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
