import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SilentBiddingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submit a silent bid (Amounts are sealed/hidden from other buyers)
  Future<bool> placeSilentBid({
    required String itemId,
    required double bidAmount,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final itemDoc = await _db.collection('market_items').doc(itemId).get();
      if (!itemDoc.exists) throw Exception("Item not found");

      final data = itemDoc.data()!;
      final DateTime endTime = (data['biddingEndTime'] as Timestamp).toDate();

      // Check if time limit expired
      if (DateTime.now().isAfter(endTime)) {
        debugPrint("Bidding time has ended for this item.");
        return false;
      }

      // Record bid in subcollection
      await _db.collection('market_items').doc(itemId).collection('bids').add({
        'bidderId': user.uid,
        'bidderName': user.displayName ?? 'Anonymous Farmer',
        'bidAmount': bidAmount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint("Error placing silent bid: $e");
      return false;
    }
  }

  /// Evaluates and declares the highest bidder once time limit expires
  Future<Map<String, dynamic>?> checkAndFinalizeWinner(String itemId) async {
    try {
      final itemDoc = await _db.collection('market_items').doc(itemId).get();
      if (!itemDoc.exists) return null;

      final data = itemDoc.data()!;
      final DateTime endTime = (data['biddingEndTime'] as Timestamp).toDate();

      if (DateTime.now().isBefore(endTime)) {
        return {'status': 'active', 'message': 'Bidding is still open'};
      }

      // Fetch highest bid
      final bidsSnapshot = await _db
          .collection('market_items')
          .doc(itemId)
          .collection('bids')
          .orderBy('bidAmount', descending: true)
          .limit(1)
          .get();

      if (bidsSnapshot.docs.isEmpty) {
        await _db.collection('market_items').doc(itemId).update({'status': 'expired_no_bids'});
        return {'status': 'closed', 'winner': null};
      }

      final winningBid = bidsSnapshot.docs.first.data();
      await _db.collection('market_items').doc(itemId).update({
        'status': 'closed',
        'winningBidderId': winningBid['bidderId'],
        'winningAmount': winningBid['bidAmount'],
      });

      return {
        'status': 'closed',
        'winningBidderId': winningBid['bidderId'],
        'winningAmount': winningBid['bidAmount'],
      };
    } catch (e) {
      debugPrint("Error finalizing winner: $e");
      return null;
    }
  }
}