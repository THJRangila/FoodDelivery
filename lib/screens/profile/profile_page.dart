import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String? profilePicture;
  bool isEditable = false;
  bool isLoading = true;
  bool isSaving = false;
  XFile? selectedImage;
  final Map<String, String> errors = {};

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    if (user == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _mobileController.text = data['mobile'] ?? '';
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['address'] ?? '';
          _cityController.text = data['city'] ?? '';
          profilePicture = data['image'] ?? 'https://via.placeholder.com/150';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveProfile() async {
    final validationErrors = validateFields();
    if (validationErrors.isNotEmpty) {
      setState(() {
        errors.clear();
        errors.addAll(validationErrors);
      });
      return;
    }

    setState(() {
      isEditable = false;
      isSaving = true;
    });

    try {
      String? uploadedImageUrl = profilePicture;

      if (selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profilePictures/${user!.uid}');
        final uploadTask = storageRef.putFile(File(selectedImage!.path));
        await uploadTask;
        uploadedImageUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': _nameController.text,
        'mobile': _mobileController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'image': uploadedImageUrl,
      }, SetOptions(merge: true));

      setState(() {
        profilePicture = uploadedImageUrl;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      print('Error saving profile: $e');
      setState(() {
        isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating profile.')),
      );
    }
  }

  Map<String, String> validateFields() {
    final errors = <String, String>{};
    if (_nameController.text.trim().isEmpty || _nameController.text.trim().length < 3) {
      errors['name'] = 'Name must be at least 3 characters long.';
    }
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!_mobileController.text.trim().contains(phoneRegex)) {
      errors['mobile'] = 'Enter a valid 10-digit mobile number.';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!_emailController.text.trim().contains(emailRegex)) {
      errors['email'] = 'Enter a valid email address.';
    }
    if (_addressController.text.trim().isEmpty ||
        _addressController.text.trim().length < 5) {
      errors['address'] = 'Address must be at least 5 characters long.';
    }
    if (_cityController.text.trim().isEmpty ||
        _cityController.text.trim().length < 2) {
      errors['city'] = 'City must be at least 2 characters long.';
    }
    return errors;
  }

  void handleEdit() {
    setState(() {
      isEditable = true;
    });
  }

  Future<void> selectImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = image;
        profilePicture = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.yellow[700]; // Your theme color
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: selectedImage != null
                                ? FileImage(File(selectedImage!.path))
                                : (profilePicture != null
                                    ? NetworkImage(profilePicture!)
                                    : const AssetImage('assets/default_avatar.png'))
                                        as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              color: themeColor,
                              onPressed: selectImage,
                              iconSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildTextField('Name', _nameController, 'name', themeColor),
                    buildTextField('Mobile', _mobileController, 'mobile', themeColor),
                    buildTextField('Email', _emailController, 'email', themeColor),
                    buildTextField('Address', _addressController, 'address', themeColor),
                    buildTextField('City', _cityController, 'city', themeColor),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 32),
                        ),
                        onPressed: isSaving ? null : (isEditable ? saveProfile : handleEdit),
                        child: isSaving
                            ? const CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              )
                            : Text(
                                isEditable ? 'Save' : 'Edit',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget buildTextField(
      String label, TextEditingController controller, String errorKey, Color? themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: themeColor)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: !isEditable,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            errorText: errors[errorKey],
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeColor!),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
