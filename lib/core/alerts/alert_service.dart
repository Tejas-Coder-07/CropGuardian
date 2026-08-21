// Crop Guardian - emergency alert service
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Push alerts for weather emergencies and disease outbreaks. Alerts are
// triggered by an n8n workflow so a farmer is warned before damage happens.

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../location/location_service.dart';

class AlertService {
  static final AlertService instance = AlertService._();
  AlertService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'crop_alerts',
    'Crop Emergency Alerts',
    description: 'Weather warnings and disease outbreak alerts for your area',
    importance: Importance.high,
  );

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Show a banner even when the app is open, so a farmer mid-scan still
    // sees a hailstorm warning.
    FirebaseMessaging.onMessage.listen(_showLocal);

    await _registerDevice();
    _ready = true;
  }

  Future<void> _showLocal(RemoteMessage msg) async {
    final n = msg.notification;
    if (n == null) return;

    await _local.show(
      id: msg.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF166534),
        ),
      ),
    );
  }

  /// Saves the FCM token plus farm district so the n8n workflow can target
  /// alerts by area instead of spamming every user in the country.
  Future<void> _registerDevice() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _fcm.getToken();
    if (token == null) return;

    final farm = await LocationService.instance.load();

    await FirebaseFirestore.instance.collection('devices').doc(uid).set({
      'fcmToken': token,
      'district': farm?.district ?? '',
      'state': farm?.state ?? '',
      'latitude': farm?.latitude,
      'longitude': farm?.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (farm != null && farm.state.isNotEmpty) {
      final topic = farm.state.replaceAll(' ', '_').toLowerCase();
      await _fcm.subscribeToTopic('state_$topic');
    }
  }

  /// Alerts this farmer has received, newest first.
  Stream<List<Map<String, dynamic>>> alertStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}