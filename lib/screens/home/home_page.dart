import 'package:flutter/material.dart';
import '../../auth/auth_service.dart';
import '../login_screen.dart';
import 'hero_section.dart';
import 'banner_section.dart';
import 'best_sellers.dart';
import 'location_card.dart';
import '../menu/menu_page.dart';
import '../cart/cart_page.dart';
import '../profile/profile_page.dart';
import '../order/orders_page.dart';
import '../notifications/notifications_page.dart';
import '../order/order_states.dart';
import '../order/order_history.dart';
import '../order/favorite_orders.dart';
import '../feedback/feedback_page.dart';
import '../contactUs/contact_us_page.dart';
import '../assist/assist_page.dart'; // Import the Assistance Page
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService authService = AuthService();
  int _selectedIndex = 0;
  int cartCount = 0;
  int ordersCount = 0;
  int notificationCount = 0;
  bool isLoadingCounts = true;

  final List<String> _titles = ['Home', 'Menu', 'Cart', 'Orders', 'Profile'];

  @override
  void initState() {
    super.initState();
    fetchCounts();
    fetchUnreadNotificationCount();
  }

  Future<void> fetchCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => isLoadingCounts = true);
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users/${user.email}/cart')
          .get();
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('OrderNow')
          .where('userEmail', isEqualTo: user.email)
          .get();
      setState(() {
        cartCount = cartSnapshot.docs.length;
        ordersCount = ordersSnapshot.docs.length;
        isLoadingCounts = false;
      });
    } catch (e) {
      print('Error fetching counts: $e');
      setState(() => isLoadingCounts = false);
    }
  }

  Future<void> fetchUnreadNotificationCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final notificationSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userEmail', isEqualTo: user.email)
          .where('read', isEqualTo: false)
          .get();

      setState(() {
        notificationCount = notificationSnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching notification count: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      SingleChildScrollView(
        child: Column(
          children: [
            HeroSection(onOrderNow: () {
              setState(() {
                _selectedIndex = 1;
              });
            }),
            BannerSection(onExploreMore: () {
              setState(() {
                _selectedIndex = 1;
              });
            }),
            BestSellers(),
            LocationCard(),
          ],
        ),
      ),
      MenuPage(),
      CartPage(),
      OrdersPage(),
      ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_titles[_selectedIndex]),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationsPage()),
                  ).then((_) => fetchUnreadNotificationCount());
                },
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'Feedback':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FeedbackPage()),
                  );
                  break;
                case 'Contact Us':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContactUsPage()),
                  );
                  break;
                case 'Order History':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
                  );
                  break;
                case 'Order Details':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderStatesPage()),
                  );
                  break;
                case 'Favorite Orders':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FavoriteOrdersPage()),
                  );
                  break;
                case 'Assistance': // Navigate to Assistance page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AssistPage()),
                  );
                  break;
                case 'Logout':
                  await authService.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return const [
                PopupMenuItem(value: 'Feedback', child: Text('Feedback')),
                PopupMenuItem(value: 'Contact Us', child: Text('Contact Us')),
                PopupMenuItem(value: 'Order History', child: Text('Order History')),
                PopupMenuItem(value: 'Order Details', child: Text('Order Status')),
                PopupMenuItem(value: 'Favorite Orders', child: Text('Favorite Orders')),
                PopupMenuItem(value: 'Assistance', child: Text('Assistance')), // New option
                PopupMenuItem(value: 'Logout', child: Text('Logout')),
              ];
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cartCount > 0)
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.list),
                if (ordersCount > 0)
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$ordersCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
