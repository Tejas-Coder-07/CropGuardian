import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crop_guardian/Widgets/bid_sheet.dart';
import 'package:crop_guardian/core/marketplace/bid_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'sell_item_screen.dart';

class MarketFeedScreen extends StatefulWidget {
  const MarketFeedScreen({super.key});

  @override
  State<MarketFeedScreen> createState() => _MarketFeedScreenState();
}

class _MarketFeedScreenState extends State<MarketFeedScreen> {
  // --- SEARCH FILTER LOGIC ---
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  void _showMenu(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Edit Post"),
              onTap: () {
                Get.back();
                Get.to(
                  () => SellItemScreen(editDocId: docId, existingData: data),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete Post"),
              onTap: () {
                FirebaseFirestore.instance
                    .collection('market_listings')
                    .doc(docId)
                    .delete();
                Get.back();
                Get.snackbar(
                  "Deleted",
                  "Post removed successfully",
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Marketplace",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('market_listings')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs.where((doc) {
            String pName = (doc['productName'] ?? "").toString().toLowerCase();
            return pName.contains(searchQuery);
          }).toList();

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var d = doc.data() as Map<String, dynamic>;

              // --- START OF UPDATED USER DATA LOGIC ---
              // We use a FutureBuilder to get the LATEST name/image from the "users" collection
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(d['sellerId'])
                    .get(),
                builder: (context, userSnapshot) {
                  String displayName = "Farmer";
                  String displayProfile = "";

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    displayName =
                        userData['userName'] ??
                        "Farmer"; // Gets name from your signup table
                    displayProfile =
                        userData['profileImageUrl'] ??
                        ""; // Gets image from your signup table
                  }

                  return Card(
                    margin: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: GestureDetector(
                            onTap: () {
                              if (displayProfile.isNotEmpty) {
                                Get.to(
                                  () => MarketFullScreenImage(
                                    imageUrl: displayProfile,
                                    tag:
                                        "profile_${d['sellerId']}_$index", // Unique tag for profile
                                  ),
                                );
                              }
                            },
                            child: Hero(
                              tag: "profile_${d['sellerId']}_$index",
                              child: CircleAvatar(
                                backgroundColor: Colors.green[50],
                                // This logic checks the post data 'd' first, then displayProfile from FutureBuilder
                                backgroundImage:
                                    (displayProfile != null &&
                                        displayProfile != "")
                                    ? NetworkImage(displayProfile)
                                    : (d['profileImageUrl'] != null &&
                                          d['profileImageUrl'] != "")
                                    ? NetworkImage(d['profileImageUrl'])
                                    : null,
                                child:
                                    ((displayProfile == null ||
                                            displayProfile == "") &&
                                        (d['profileImageUrl'] == null ||
                                            d['profileImageUrl'] == ""))
                                    ? Text(
                                        displayName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          // --- UPDATED: Showing the real name from user collection ---
                          title: Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            d['updatedAt'] != null
                                ? DateFormat('hh:mm a, dd MMM').format(
                                    (d['updatedAt'] as Timestamp).toDate(),
                                  )
                                : "",
                          ),
                          trailing: d['sellerId'] == currentUserId
                              ? IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () =>
                                      _showMenu(context, doc.id, d),
                                )
                              : null,
                        ),

                        // --- END OF UPDATED USER DATA LOGIC ---
                        if (d['imageUrl'] != null)
                          GestureDetector(
                            onTap: () => Get.to(
                              () => MarketFullScreenImage(
                                imageUrl: d['imageUrl'],
                                tag: doc.id,
                              ),
                            ),
                            child: Hero(
                              tag: doc.id,
                              child: Image.network(
                                d['imageUrl'],
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    d['productName'] ?? "",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      d['category'] ?? "Vegetable",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    "₹${d['price']}",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Qty: ${d['maxQuantity']}",
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "Grade: ${d['productClass'] ?? 'N/A'}",
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => BidSheet.show(
                                    context,
                                    listingId: doc.id,
                                    cropName: d['productName'] ?? 'Produce',
                                    askingPrice:
                                        (d['price'] as num?)?.toDouble() ?? 0,
                                    sellerId: d['sellerId'] ?? '',
                                  ),
                                  icon: const Icon(Icons.gavel, size: 17),
                                  label: StreamBuilder<AuctionState>(
                                    stream: BidService.instance
                                        .auctionState(doc.id),
                                    builder: (context, s) {
                                      final st = s.data;
                                      if (st == null) {
                                        return const Text('Bidding');
                                      }
                                      if (st.closesAt == null) {
                                        return Text(
                                          d['sellerId'] == currentUserId
                                              ? 'Open bidding'
                                              : 'Bidding not open yet',
                                        );
                                      }
                                      return Text(st.countdownLabel);
                                    },
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF047857),
                                    side: const BorderSide(
                                        color: Color(0xFF34D399)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const Divider(height: 25),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(d['phone'] ?? "No Contact"),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      d['address'] ?? "",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const SellItemScreen()),
        backgroundColor: const Color(0xFFC6FF00),
        icon: const Icon(Icons.add_shopping_cart, color: Colors.black),
        label: const Text(
          "SELL ITEM",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class MarketFullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const MarketFullScreenImage({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width,
            ),
          ),
        ),
      ),
    );
  }
}
