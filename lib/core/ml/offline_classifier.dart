// Crop Guardian - on-device TFLite disease classifier
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// MobileNetV3-Large fine-tuned on PlantVillage (54,305 images, 38 classes).
// Runs fully offline. Falls back to cloud Gemini when confidence is low.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class OfflinePrediction {
  final String rawLabel;
  final String cropType;
  final String condition;
  final double confidence;
  final bool isHealthy;

  OfflinePrediction({
    required this.rawLabel,
    required this.cropType,
    required this.condition,
    required this.confidence,
    required this.isHealthy,
  });

  /// Below this we do not trust the on-device model and escalate to cloud AI.
  static const double confidenceThreshold = 0.70;

  /// Below this the model is effectively guessing - the crop is probably
  /// not one of the 38 classes it was trained on.
  static const double unknownThreshold = 0.45;

  bool get isConfident => confidence >= confidenceThreshold;

  /// True when the model does not recognise the crop at all.
  bool get isUnknownCrop => confidence < unknownThreshold;

  @override
  String toString() =>
      '$cropType / $condition (${(confidence * 100).toStringAsFixed(1)}%)';
}

class OfflineClassifier {
  static final OfflineClassifier instance = OfflineClassifier._();
  OfflineClassifier._();

  static const String _modelAsset = 'assets/ml/crop_model.tflite';
  static const String _labelsAsset = 'assets/ml/labels.txt';
  static const int _inputSize = 224;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  Future<void> load() async {
    if (isReady) return;
    _interpreter = await Interpreter.fromAsset(_modelAsset);
    final raw = await rootBundle.loadString(_labelsAsset);
    _labels = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  Future<OfflinePrediction?> classify(File imageFile) async {
    await load();
    if (!isReady) return null;

    final decoded = img.decodeImage(await imageFile.readAsBytes());
    if (decoded == null) return null;

    final resized =
        img.copyResize(decoded, width: _inputSize, height: _inputSize);

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r.toDouble(), p.g.toDouble(), p.b.toDouble()];
        }),
      ),
    );

    final output =
        List.generate(1, (_) => List.filled(_labels.length, 0.0));
    _interpreter!.run(input, output);

    final scores = output[0];
    var bestIndex = 0;
    var bestScore = scores[0];
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndex = i;
      }
    }

    return _toPrediction(_labels[bestIndex], bestScore);
  }

  OfflinePrediction _toPrediction(String rawLabel, double confidence) {
    final parts = rawLabel.split('___');
    final crop = parts.first.replaceAll('_', ' ').trim();
    final condition = parts.length > 1
        ? parts[1].replaceAll('_', ' ').trim()
        : 'Unknown';

    return OfflinePrediction(
      rawLabel: rawLabel,
      cropType: crop,
      condition: condition,
      confidence: confidence,
      isHealthy: condition.toLowerCase().contains('healthy'),
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}