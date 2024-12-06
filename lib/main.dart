import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart'; // Login Screen
import 'screens/cart/cart_page.dart'; // Cart Page
import 'screens/home/home_page.dart'; // Home Page
import 'screens/order/orders_page.dart'; // Orders Page
import 'screens/menu/menu_page.dart'; // Menu Page
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'bika',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // Start with the splash screen
      routes: {
        '/': (context) => SplashScreen(), // Splash Screen Route
        '/login': (context) => LoginScreen(), // Login Screen Route
        '/home': (context) => HomePage(), // Home Screen Route
        '/cart': (context) => CartPage(), // Cart Screen Route
        '/orders': (context) => OrdersPage(), // Orders Screen Route
        '/menu': (context) => MenuPage(), // Menu Screen Route
      },
    );
  }
}


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAuthState();
  }

  Future<void> _checkUserAuthState() async {
    // Simulate a loading delay
    await Future.delayed(const Duration(seconds: 3));

    // Check if a user is logged in
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // If user is logged in, navigate to Home Page
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // If no user is logged in, navigate to Login Page
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFFCC01), // Splash screen background color
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/splash_logo.png', // Add your splash logo
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Bika',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
