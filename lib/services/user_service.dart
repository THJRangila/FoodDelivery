import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Import this for debugPrint

class UserService {
  Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = snapshot.data();
      debugPrint('Fetched data: $data');
      debugPrint('Data type: ${data.runtimeType}');

      if (data != null && data is Map<String, dynamic>) {
        return data; // Return the raw data as a Map
      } else {
        debugPrint('Error: Data is not in the expected format.');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      return null;
    }
  }
}
