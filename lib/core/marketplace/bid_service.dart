// Crop Guardian - silent bidding
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Sealed-bid auction. A buyer places one or more bids but cannot see anyone
// else's amount, so nobody can simply outbid by a rupee at the last second.
// When the seller's closing time passes, the highest bid wins and the result
// becomes visible to both sides.
//
// Firestore rules enforce the secrecy - a buyer can only read their own bid
// document. The UI is not the security boundary.

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

  factory Bid.fromDoc(DocumentSnapshot doc) {
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

class AuctionState {
  final DateTime? closesAt;
  final bool isOpen;
  final Duration? remaining;
  final int bidCount;

  AuctionState({
    required this.closesAt,
    required this.isOpen,
    required this.remaining,
    required this.bidCount,
  });

  String get countdownLabel {
    if (closesAt == null) return 'No closing time set';
    if (!isOpen) return 'Bidding closed';
    final r = remaining!;
    if (r.inDays > 0) return 'Closes in ${r.inDays}d ${r.inHours % 24}h';
    if (r.inHours > 0) return 'Closes in ${r.inHours}h ${r.inMinutes % 60}m';
    return 'Closes in ${r.inMinutes}m';
  }
}

class BidService {
  static final BidService instance = BidService._();
  BidService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference _bidsRef(String listingId) =>
      _db.collection('market_listings').doc(listingId).collection('bids');

  DocumentReference _listingRef(String listingId) =>
      _db.collection('market_listings').doc(listingId);

  /// Seller opens bidding by setting a closing time.
  Future<String?> openAuction({
    required String listingId,
    required DateTime closesAt,
    double? reservePrice,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Please log in first.';
    if (closesAt.isBefore(DateTime.now())) {
      return 'Closing time must be in the future.';
    }

    await _listingRef(listingId).set({
      'biddingClosesAt': Timestamp.fromDate(closesAt),
      'reservePrice': reservePrice,
      'biddingOpenedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return null;
  }

  /// Live auction status for a listing.
  Stream<AuctionState> auctionState(String listingId) =>
      _listingRef(listingId).snapshots().map((doc) {
        final d = doc.data() as Map<String, dynamic>?;
        final ts = d?['biddingClosesAt'] as Timestamp?;
        final closesAt = ts?.toDate();

        final now = DateTime.now();
        final isOpen = closesAt != null && closesAt.isAfter(now);

        // Bid count is fetched separately by the seller view, so a buyer -
        // who is not permitted to list bids - still gets the countdown.
        return AuctionState(
          closesAt: closesAt,
          isOpen: isOpen,
          remaining: isOpen ? closesAt.difference(now) : null,
          bidCount: 0,
        );
      });

  /// The current user's own bid, if they have placed one. Buyers see only this.
  Stream<Bid?> myBid(String listingId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _bidsRef(listingId).doc(uid).snapshots().map(
          (doc) => doc.exists ? Bid.fromDoc(doc) : null,
        );
  }

  /// All bids, highest first. Only readable by the seller.
  Stream<List<Bid>> allBids(String listingId) => _bidsRef(listingId)
      .orderBy('amount', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Bid.fromDoc).toList());

  /// Places or raises a sealed bid. The document id is the bidder uid, so a
  /// buyer has exactly one live bid and raising replaces it.
  Future<String?> placeBid({
    required String listingId,
    required double amount,
    required String bidderName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Please log in to place a bid.';
    if (amount <= 0) return 'Enter a valid amount.';

    final listing = await _listingRef(listingId).get();
    final d = listing.data() as Map<String, dynamic>?;

    if (d?['sellerId'] == user.uid) {
      return 'You cannot bid on your own listing.';
    }

    final ts = d?['biddingClosesAt'] as Timestamp?;
    if (ts == null) return 'Bidding has not opened on this listing yet.';
    if (ts.toDate().isBefore(DateTime.now())) return 'Bidding has closed.';

    final existing = await _bidsRef(listingId).doc(user.uid).get();
    if (existing.exists) {
      final prev = (existing.data() as Map<String, dynamic>)['amount'] as num;
      if (amount <= prev) {
        return 'Your new bid must be higher than your current bid.';
      }
    }

    await _bidsRef(listingId).doc(user.uid).set({
      'bidderId': user.uid,
      'bidderName': bidderName,
      'amount': amount,
      'placedAt': FieldValue.serverTimestamp(),
    });

    return null;
  }

  /// Winner once bidding has closed. Returns null while still open.
  Future<Bid?> winner(String listingId) async {
    final listing = await _listingRef(listingId).get();
    final d = listing.data() as Map<String, dynamic>?;
    final ts = d?['biddingClosesAt'] as Timestamp?;

    if (ts == null || ts.toDate().isAfter(DateTime.now())) return null;

    final snap = await _bidsRef(listingId)
        .orderBy('amount', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;

    final top = Bid.fromDoc(snap.docs.first);
    final reserve = (d?['reservePrice'] as num?)?.toDouble();
    if (reserve != null && top.amount < reserve) return null;

    return top;
  }
}
