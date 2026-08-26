// Crop Guardian - user role
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// A farmer sells produce; a buyer purchases it. Same account system, different
// marketplace view. Kept as a stored field rather than two account types so a
// farmer who also buys inputs can switch without a second login.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { farmer, buyer }

class RoleController extends ChangeNotifier {
  static final RoleController instance = RoleController._();
  RoleController._();

  static const _key = 'user_role';

  UserRole _role = UserRole.farmer;
  UserRole get role => _role;

  bool get isFarmer => _role == UserRole.farmer;
  bool get isBuyer => _role == UserRole.buyer;

  String get label => _role == UserRole.farmer ? 'Farmer' : 'Buyer';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _role = saved == 'buyer' ? UserRole.buyer : UserRole.farmer;
      notifyListeners();
      return;
    }

    // Fall back to whatever the account was created with.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final remote = doc.data()?['role'] as String?;
      if (remote != null) {
        _role = remote == 'buyer' ? UserRole.buyer : UserRole.farmer;
        await prefs.setString(_key, remote);
        notifyListeners();
      }
    } catch (_) {
      // Offline - farmer default is the safe assumption.
    }
  }

  Future<void> setRole(UserRole role) async {
    if (_role == role) return;
    _role = role;
    notifyListeners();

    final value = role == UserRole.buyer ? 'buyer' : 'farmer';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'role': value}, SetOptions(merge: true));
    } catch (_) {
      // Saved locally; will sync on next profile write.
    }
  }
}