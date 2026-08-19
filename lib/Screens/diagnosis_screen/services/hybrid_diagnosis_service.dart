// Crop Guardian - hybrid diagnosis orchestrator
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Flow: on-device TFLite first -> if confident, answer offline.
//       If unsure or the farmer wants detail, escalate to cloud Gemini.

import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/data/local_database.dart';
import '../../../core/ml/offline_classifier.dart';
import '../models/diagnosis_model.dart';
import 'gemini_service.dart';

enum DiagnosisSource { onDevice, cloud, cloudEscalated }

class HybridResult {
  final DiagnosisSource source;
  final OfflinePrediction? offline;
  final DiagnosisModel? cloud;
  final int localScanId;
  final String? error;

  HybridResult({
    required this.source,
    required this.localScanId,
    this.offline,
    this.cloud,
    this.error,
  });

  bool get isOffline => source == DiagnosisSource.onDevice;
  bool get didEscalate => source == DiagnosisSource.cloudEscalated;
}

class HybridDiagnosisService {
  final GeminiService _gemini = GeminiService();
  final LocalDatabase _local = LocalDatabase.instance;

  /// Runs the on-device model first. Only calls the cloud when the phone
  /// is not confident enough, or when there is no usable result.
  Future<HybridResult> diagnose({
    required File imageFile,
    String? description,
    bool forceCloud = false,
  }) async {
    OfflinePrediction? prediction;

    if (!forceCloud) {
      try {
        prediction = await OfflineClassifier.instance.classify(imageFile);
      } catch (_) {
        prediction = null;
      }
    }

    // Phone is confident -> answer without any network at all.
    if (prediction != null && prediction.isConfident && !forceCloud) {
      final id = await _saveLocal(
        imageFile: imageFile,
        source: 'onDevice',
        cropType: prediction.cropType,
        issue: prediction.condition,
        confidence: prediction.confidence,
        payload: jsonEncode({
          'rawLabel': prediction.rawLabel,
          'isHealthy': prediction.isHealthy,
        }),
      );

      return HybridResult(
        source: DiagnosisSource.onDevice,
        offline: prediction,
        localScanId: id,
      );
    }

    // Not confident (or forced) -> escalate to cloud Gemini.
    try {
      final text = await _gemini.analyzeImage(imageFile, description);
      final parsed = _gemini.parseDiagnosisResponse(text);

      final id = await _saveLocal(
        imageFile: imageFile,
        source: forceCloud ? 'cloud' : 'cloudEscalated',
        cropType: parsed.cropType,
        issue: parsed.detectedIssue,
        confidence: parsed.confidenceScore,
        payload: jsonEncode(parsed.toJson()),
      );

      await _syncToFirestore(parsed, id);

      return HybridResult(
        source: forceCloud
            ? DiagnosisSource.cloud
            : DiagnosisSource.cloudEscalated,
        offline: prediction,
        cloud: parsed,
        localScanId: id,
      );
    } catch (e) {
      // Offline and cloud failed: fall back to the low-confidence guess
      // rather than showing the farmer nothing at all.
      if (prediction != null) {
        final id = await _saveLocal(
          imageFile: imageFile,
          source: 'onDevice',
          cropType: prediction.cropType,
          issue: prediction.condition,
          confidence: prediction.confidence,
          payload: jsonEncode({'lowConfidence': true}),
        );
        return HybridResult(
          source: DiagnosisSource.onDevice,
          offline: prediction,
          localScanId: id,
          error: null,
        );
      }
      return HybridResult(
        source: DiagnosisSource.cloud,
        localScanId: -1,
        error: e.toString(),
      );
    }
  }

  Future<int> _saveLocal({
    required File imageFile,
    required String source,
    required String cropType,
    required String issue,
    required double confidence,
    required String payload,
  }) async {
    return _local.insertScan({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'imagePath': imageFile.path,
      'cropType': cropType,
      'detectedIssue': issue,
      'severity': '',
      'confidence': confidence,
      'source': source,
      'payload': payload,
      'syncedToCloud': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _syncToFirestore(DiagnosisModel d, int localId) async {
    try {
      await FirebaseFirestore.instance.collection('diagnoses').add({
        ...d.toJson(),
        'confidence': d.confidenceScore,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'serverTimestamp': FieldValue.serverTimestamp(),
      });
      await _local.markScanSynced(localId);
    } catch (_) {
      // Stays queued locally; a later sync pass will pick it up.
    }
  }

  /// Farmer taps the tick or corrects the label. This is the training signal.
  Future<void> recordFeedback(int scanId, {String? correctedLabel}) async {
    await _local.confirmScan(scanId, correctedLabel: correctedLabel);
  }
}