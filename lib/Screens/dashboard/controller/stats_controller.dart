// Crop Guardian - dashboard statistics
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Counts include scans stored locally on the device, not just synced ones.
// An offline-first app must show the farmer their own activity immediately,
// even when nothing has reached the cloud yet.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../core/data/local_database.dart';

class StatsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDatabase _local = LocalDatabase.instance;

  var diagnosesCount = 0.obs;
  var farmersCount = 0.obs;

  /// Share of diagnoses the farmer confirmed as correct. This is real
  /// feedback, not the model's own confidence score.
  var agreementRate = 0.0.obs;
  var hasEnoughFeedback = false.obs;

  int _cloudDiagnoses = 0;
  int _localDiagnoses = 0;

  @override
  void onInit() {
    super.onInit();
    _listenToCloud();
    refreshLocal();
  }

  void _listenToCloud() {
    _db.collection('diagnoses').snapshots().listen((snap) {
      _cloudDiagnoses = snap.docs.length;
      _updateTotal();
    }, onError: (_) {});

    _db.collection('users').snapshots().listen((snap) {
      farmersCount.value = snap.docs.length;
    }, onError: (_) {});
  }

  /// Reads counts from the on-device store. Call after every scan so the
  /// dashboard moves immediately, online or not.
  Future<void> refreshLocal() async {
    try {
      final scans = await _local.recentScans(limit: 10000);
      _localDiagnoses = scans.length;

      final reviewed = scans.where((s) => (s['farmerConfirmed'] ?? 0) == 1).toList();
      if (reviewed.length >= 5) {
        final correct = reviewed
            .where((s) => s['correctedLabel'] == null ||
                (s['correctedLabel'] as String).trim().isEmpty)
            .length;
        agreementRate.value = (correct / reviewed.length) * 100;
        hasEnoughFeedback.value = true;
      } else {
        hasEnoughFeedback.value = false;
      }

      _updateTotal();
    } catch (_) {
      // Local DB unavailable - cloud count alone still renders.
    }
  }

  void _updateTotal() {
    // Local scans that already synced also exist in Firestore. Taking the
    // larger of the two avoids double counting without extra bookkeeping.
    diagnosesCount.value =
        _localDiagnoses > _cloudDiagnoses ? _localDiagnoses : _cloudDiagnoses;
  }
}