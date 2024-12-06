import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_details_page.dart'; // Import MenuDetailsPage

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _menuTypes = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
  }

  Future<void> _fetchMenuData() async {
    try {
      // Fetch menu items
      final itemsSnapshot = await FirebaseFirestore.instance.collection('Menu').get();
      final itemsData = itemsSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();

      // Fetch menu types
      final typesSnapshot = await FirebaseFirestore.instance.collection('menuTypes').get();
      final typesData = typesSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();

      setState(() {
        _menuItems = itemsData;
        _menuTypes = typesData;
        _filteredItems = itemsData;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching menu data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMenuItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _menuItems;
      } else {
        _filteredItems = _menuItems
            .where((item) =>
                item['productName'] != null &&
                item['productName'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OUR MENU',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        onChanged: _filterMenuItems,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search for foods',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Search Dropdown
                      if (_searchController.text.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: _filteredItems.isNotEmpty
                                ? _filteredItems.map((item) {
                                    return ListTile(
                                      title: Text(item['productName']),
                                      onTap: () {
                                        // Navigate to menu details
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MenuDetailsPage(
                                              menuType: item['menuType'] ?? 'Unknown',
                                            ),
                                          ),
                                        );
                                        _searchController.clear();
                                        _filterMenuItems('');
                                      },
                                    );
                                  }).toList()
                                : [
                                    const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text('No items found'),
                                    ),
                                  ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Menu Types Grid
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: _menuTypes.length,
                    itemBuilder: (context, index) {
                      final type = _menuTypes[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to menu details page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenuDetailsPage(
                                menuType: type['type'] ?? 'Unknown',
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                  child: Image.network(
                                    type['imageUrl'] ?? '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  type['type'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
