// Crop Guardian - marketplace bidding
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Bids are append-only: once placed, nobody can edit or withdraw one. The
// highest bid is derived from the collection rather than stored on the
// listing, so two buyers bidding at the same moment cannot overwrite each
// other.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Bid {
  final String id;
  final String bidderId;
  final String bidderName;
  final double amount;
  final DateTime placedAt;

  Bid({
    required this.id,
    required this.bidderId,
    required this.bidderName,
    required this.amount,
    required this.placedAt,
  });

  factory Bid.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Bid(
      id: doc.id,
      bidderId: d['bidderId'] ?? '',
      bidderName: d['bidderName'] ?? 'Buyer',
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      placedAt: (d['placedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isMine => bidderId == FirebaseAuth.instance.currentUser?.uid;
}

class BidService {
  static final BidService instance = BidService._();
  BidService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference _bidsRef(String listingId) =>
      _db.collection('market_listings').doc(listingId).collection('bids');

  /// Live bid list for a listing, highest first.
  Stream<List<Bid>> bidStream(String listingId) => _bidsRef(listingId)
      .orderBy('amount', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Bid.fromDoc).toList());

  /// Highest bid so far, or null if none.
  Future<Bid?> highestBid(String listingId) async {
    final snap = await _bidsRef(listingId)
        .orderBy('amount', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Bid.fromDoc(snap.docs.first);
  }

  /// Places a bid. Rejects anything not above the current highest, so a buyer
  /// cannot underbid by accident when the list is stale on screen.
  Future<String?> placeBid({
    required String listingId,
    required double amount,
    required String bidderName,
    double? askingPrice,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Please log in to place a bid.';
    if (amount <= 0) return 'Enter a valid amount.';

    final highest = await highestBid(listingId);

    if (highest != null && amount <= highest.amount) {
      return 'Your bid must be higher than Rs ${highest.amount.toStringAsFixed(0)}.';
    }
    if (highest == null && askingPrice != null && amount < askingPrice * 0.5) {
      return 'Bid is far below the asking price. Enter a serious offer.';
    }

    await _bidsRef(listingId).add({
      'bidderId': user.uid,
      'bidderName': bidderName,
      'amount': amount,
      'placedAt': FieldValue.serverTimestamp(),
    });

    return null; // success
  }

  /// Bid count for a listing, for showing "3 bids" on the card.
  Stream<int> bidCount(String listingId) =>
      _bidsRef(listingId).snapshots().map((s) => s.docs.length);
}