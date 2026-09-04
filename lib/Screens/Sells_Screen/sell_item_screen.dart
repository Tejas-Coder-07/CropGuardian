import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SellItemScreen extends StatefulWidget {
  final String? editDocId;
  final Map<String, dynamic>? existingData;

  const SellItemScreen({super.key, this.editDocId, this.existingData});

  @override
  State<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _image;

  // Configuration for Cloudinary
  final String cloudName = "dbsesnq44";
  final String uploadPreset = "market";

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  DateTime? _biddingClosesAt;

  // New Dropdown Variables
  String selectedCategory = 'Vegetables';
  String selectedClass = 'Class 1';

  final List<String> categories = ['Fruits', 'Vegetables', 'Seeds'];
  final List<String> classes = ['Extra Class', 'Class 1', 'Class 2'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingData?['productName'] ?? "");
    _priceController = TextEditingController(text: widget.existingData?['price'] ?? "");
    _quantityController = TextEditingController(text: widget.existingData?['maxQuantity'] ?? "");
    _phoneController = TextEditingController(text: widget.existingData?['phone'] ?? "");
    _addressController = TextEditingController(text: widget.existingData?['address'] ?? "");

    if (widget.existingData != null) {
      selectedCategory = widget.existingData?['category'] ?? 'Vegetables';
      selectedClass = widget.existingData?['productClass'] ?? 'Class 1';
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  // ... existing imports ...

// UPDATED: In SellItemScreen, update the _submitPost function
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null && widget.editDocId == null) {
      Get.snackbar("Image Required", "Please pick a product photo");
      return;
    }

    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // --- NEW: FETCH USER DATA FROM FIRESTORE ---
      // This ensures we get the userName you saved in the SignUp Controller
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String currentUserName = "Farmer";
      String currentUserProfile = "";

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        currentUserName = userData['userName'] ?? user.displayName ?? "Farmer";
        // Ensure you have a 'userImage' field in your signup/profile if you want images
        currentUserProfile = userData['userImage'] ?? user.photoURL ?? "";
      }

      String imageUrl = widget.existingData?['imageUrl'] ?? "";
      if (_image != null) {
        final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
        final request = http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', _image!.path));
        final response = await request.send();
        final responseData = await response.stream.toBytes();
        imageUrl = jsonDecode(String.fromCharCodes(responseData))['secure_url'];
      }

      Map<String, dynamic> data = {
        'sellerId': user.uid,
        // Sealed bidding closes at this time. Set on the sell form so the
        // seller decides up front, rather than hunting for it later.
        if (_biddingClosesAt != null)
          'biddingClosesAt': Timestamp.fromDate(_biddingClosesAt!),
        'userName': currentUserName, // UPDATED: Now uses Firestore data
        'profileImageUrl': currentUserProfile, // UPDATED: Now uses Firestore data
        'productName': _nameController.text.trim(),
        'category': selectedCategory,
        'productClass': selectedClass,
        'price': _priceController.text.trim(),
        'maxQuantity': _quantityController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.editDocId != null) {
        await FirebaseFirestore.instance.collection('market_listings').doc(widget.editDocId).update(data);
      } else {
        await FirebaseFirestore.instance.collection('market_listings').add(data);
      }
      Get.back();
      Get.snackbar("Success", "Listing published successfully!");
    } catch (e) {
      Get.snackbar("Error", "Upload failed. Try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: Center(child: Text(widget.editDocId != null ? "Update Listing" : "Sell Item",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),)), backgroundColor: const Color(0xFF1B5E20)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                  child: _image != null ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_image!, fit: BoxFit.cover)) : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              // Category and Class Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedClass,
                      decoration: const InputDecoration(labelText: "Quality Class", border: OutlineInputBorder()),
                      items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => selectedClass = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Produce Name (e.g., Organic Onion)", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price (₹)", border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _quantityController, decoration: const InputDecoration(labelText: "Quantity (e.g., 500 KG)", border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 3)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (d == null || !mounted) return;
                  final t = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 18, minute: 0),
                  );
                  if (t == null || !mounted) return;
                  setState(() => _biddingClosesAt =
                      DateTime(d.year, d.month, d.day, t.hour, t.minute));
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Bidding closes (optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Buyers place sealed bids. Highest wins at closing.',
                  ),
                  child: Text(
                    _biddingClosesAt == null
                        ? 'Tap to set a closing time'
                        : _biddingClosesAt.toString().substring(0, 16),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Contact Phone", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: "Pickup Address", border: OutlineInputBorder())),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC6FF00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : () => _submitPost(), // FIXED ERROR
                  child: _isLoading ? const CircularProgressIndicator() : const Text("CONFIRM & PUBLISH", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
