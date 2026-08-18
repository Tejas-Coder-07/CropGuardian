import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../login_screen.dart';

SignUpUser(String userName, String userPhone, String userEmail,
    String userPassword) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  try {
    await currentUser!.updateDisplayName(userName);
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .set({
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'userId': currentUser!.uid,
      'createdAt': DateTime.now(),
    }).then((value) => {
      FirebaseAuth.instance.signOut(),
      Get.off(() => LoginScreen()),
    });
    log("user Added");
  } on FirebaseException catch (e) {
    Fluttertoast.showToast(msg: "Eroor $e",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 15.0,
    );
    print("Eroor $e");
  }
}
