import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _feedbackController = TextEditingController();
  final _subjectController = TextEditingController();
  final _dishNameController = TextEditingController();
  final _ratingCommentController = TextEditingController();
  double _starRating = 3.0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSubmittingFeedback = false;
  bool _isSubmittingRating = false;

  Future<void> submitFeedback() async {
    if (_subjectController.text.trim().isEmpty || _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject and feedback cannot be empty.")),
      );
      return;
    }

    setState(() {
      _isSubmittingFeedback = true;
    });

    try {
      final user = _auth.currentUser;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        String userName = userDoc.exists && userDoc.data()!.containsKey('name')
            ? userDoc['name']
            : user.displayName ?? "Anonymous";

        await _firestore.collection('contacts').add({
          'userId': user.uid,
          'name': userName,
          'email': user.email ?? 'No Email',
          'subject': _subjectController.text.trim(),
          'message': _feedbackController.text.trim(),
          'timestamp': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback submitted successfully!")),
        );

        _subjectController.clear();
        _feedbackController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in to submit feedback.")),
        );
      }
    } catch (e) {
      print("Error submitting feedback: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error submitting feedback.")),
      );
    } finally {
      setState(() {
        _isSubmittingFeedback = false;
      });
    }
  }

  Future<void> submitRating() async {
    if (_dishNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dish name cannot be empty.")),
      );
      return;
    }

    setState(() {
      _isSubmittingRating = true;
    });

    try {
      final user = _auth.currentUser;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        String userName = userDoc.exists && userDoc.data()!.containsKey('name')
            ? userDoc['name']
            : user.displayName ?? "Anonymous";

        await _firestore.collection('ratings').add({
          'userId': user.uid,
          'name': userName,
          'email': user.email ?? 'No Email',
          'dishName': _dishNameController.text.trim(),
          'rating': _starRating,
          'comment': _ratingCommentController.text.trim(),
          'timestamp': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rating submitted successfully!")),
        );

        _dishNameController.clear();
        _ratingCommentController.clear();
        _starRating = 3.0;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in to submit a rating.")),
        );
      }
    } catch (e) {
      print("Error submitting rating: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error submitting rating.")),
      );
    } finally {
      setState(() {
        _isSubmittingRating = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> retrieveFeedbacks() async {
    final feedbacksSnapshot =
        await _firestore.collection('contacts').orderBy('timestamp', descending: true).get();
    return feedbacksSnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> retrieveRatings() async {
    final ratingsSnapshot =
        await _firestore.collection('ratings').orderBy('timestamp', descending: true).get();
    return ratingsSnapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Feedback & Ratings"),
          centerTitle: true,
          backgroundColor: Colors.amber,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.feedback), text: "Feedback"),
              Tab(icon: Icon(Icons.star), text: "Ratings"),
              Tab(icon: Icon(Icons.list), text: "View All"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Feedback Section
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText: "Subject",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.subject),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _feedbackController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: "Feedback",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.feedback),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _isSubmittingFeedback ? null : submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: _isSubmittingFeedback
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Submit Feedback",
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Ratings Section
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _dishNameController,
                            decoration: const InputDecoration(
                              labelText: "Dish Name",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.restaurant_menu),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Slider(
                            value: _starRating,
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: _starRating.toString(),
                            onChanged: (value) {
                              setState(() {
                                _starRating = value;
                              });
                            },
                          ),
                          TextField(
                            controller: _ratingCommentController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: "Comment",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.comment),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _isSubmittingRating ? null : submitRating,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: _isSubmittingRating
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Submit Rating",
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // View All Section
            SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("All Feedbacks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: retrieveFeedbacks(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return const Text("Error loading feedbacks.");
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text("No feedback available.");
                      }

                      return ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: snapshot.data!
                            .map((feedback) => ListTile(
                                  title: Text(feedback['subject'] ?? "No Subject"),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(feedback['message'] ?? "No Message"),
                                      Text(feedback['name'] ?? "Anonymous",
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic, fontSize: 12)),
                                    ],
                                  ),
                                  trailing: Text(
                                    (feedback['timestamp'] as Timestamp)
                                        .toDate()
                                        .toLocal()
                                        .toString()
                                        .split('.')[0],
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("All Ratings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: retrieveRatings(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return const Text("Error loading ratings.");
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text("No ratings available.");
                      }

                      return ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: snapshot.data!
                            .map((rating) => Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(rating['dishName'] ?? "No Dish Name",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: List.generate(
                                            rating['rating'].toInt(),
                                            (index) => const Icon(Icons.star, color: Colors.amber),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(rating['comment'] ?? "No Comment"),
                                        const SizedBox(height: 5),
                                        Text(rating['name'] ?? "Anonymous",
                                            style: const TextStyle(
                                                fontStyle: FontStyle.italic, fontSize: 12)),
                                        const SizedBox(height: 5),
                                        Text(
                                          (rating['timestamp'] as Timestamp)
                                              .toDate()
                                              .toLocal()
                                              .toString()
                                              .split('.')[0],
                                          style:
                                              const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      );
                    },
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
