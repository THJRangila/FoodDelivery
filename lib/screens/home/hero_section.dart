import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onOrderNow;

  HeroSection({required this.onOrderNow});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Image.asset(
          'assets/biriyani-image.png.jpg', // Replace with your image asset path
          fit: BoxFit.cover,
          height: 290,
          width: double.infinity,
        ),

        // Overlay Gradient for Modern Look
        Container(
          height: 290,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Text Positioned at Center-Top
        Positioned(
          top: 30,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sri Lanka's No. 1 Biriyani",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.7),
                      offset: const Offset(2, 3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Delicious, Flavorful, and Authentic",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Ashen Image Positioned at Bottom-Right
        Positioned(
          bottom: -40,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Image.asset(
              'assets/Ashen1.png', // Replace with your image asset path
              height: 280,
              width: 240,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Button Positioned at Bottom-Left
        Positioned(
          bottom: 40,
          left: 20,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.shade700,
              elevation: 12,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: onOrderNow,
            child: Row(
              children: const [
                Icon(Icons.shopping_cart, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Order Now!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
