// Crop Guardian - phone authentication
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Many smallholder farmers have a phone number but no email address. Phone
// login removes that barrier entirely - no address to remember, no password
// to forget, just the number they already use every day.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  static final PhoneAuthService instance = PhoneAuthService._();
  PhoneAuthService._();

  final _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  /// Normalises whatever the farmer typed into E.164. Assumes India when no
  /// country code is given, which is the overwhelming majority of our users.
  String normalise(String input) {
    var n = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (n.startsWith('+')) return n;
    if (n.startsWith('91') && n.length == 12) return '+' + n;
    if (n.length == 10) return '+91' + n;
    return '+' + n;
  }

  bool isValid(String input) {
    final n = normalise(input);
    return RegExp(r'^\+[1-9]\d{9,14}$').hasMatch(n);
  }

  /// Sends the SMS code. onCodeSent fires when the farmer should be shown the
  /// code entry screen; onAutoVerified fires on Android when the SMS is read
  /// automatically and no typing is needed at all.
  Future<void> sendCode({
    required String phoneNumber,
    required void Function() onCodeSent,
    required void Function(UserCredential) onAutoVerified,
    required void Function(String) onError,
  }) async {
    final number = normalise(phoneNumber);

    await _auth.verifyPhoneNumber(
      phoneNumber: number,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential cred) async {
        try {
          final result = await _auth.signInWithCredential(cred);
          await _ensureUserDoc(result.user, number);
          onAutoVerified(result);
        } catch (e) {
          onError(e.toString());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.toString());
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Verifies the six digit code the farmer typed.
  Future<String?> verifyCode(String code, String phoneNumber) async {
    if (_verificationId == null) {
      return 'Please request a code first.';
    }
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code.trim(),
      );
      final result = await _auth.signInWithCredential(cred);
      await _ensureUserDoc(result.user, normalise(phoneNumber));
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Creates the user document on first phone login so the rest of the app -
  /// role, admin flag, profile - behaves the same as an email account.
  Future<void> _ensureUserDoc(User? user, String phone) async {
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) return;

    await ref.set({
      'userName': user.displayName ?? 'Farmer',
      'userPhone': phone,
      'userEmail': user.email ?? '',
      'userId': user.uid,
      'role': 'farmer',
      'createdAt': DateTime.now(),
    });
  }
}