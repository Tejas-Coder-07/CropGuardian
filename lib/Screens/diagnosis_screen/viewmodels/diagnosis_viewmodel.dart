// Crop Guardian - diagnosis viewmodel
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/ml/offline_classifier.dart';
import '../../../core/language/language_controller.dart';
import '../models/diagnosis_model.dart';
import '../services/hybrid_diagnosis_service.dart';
import '../services/tts_service.dart';

class DiagnosisViewModel extends ChangeNotifier {
  final HybridDiagnosisService _service = HybridDiagnosisService();
  final TtsService _ttsService = TtsService();
  late stt.SpeechToText _speech;
  final TextEditingController descriptionController = TextEditingController();

  File? _selectedImage;
  String _description = '';
  // Read live from the controller rather than caching at construction, so
  // switching language in the drawer applies to the next diagnosis.
  String? _overrideLanguage;
  String get _selectedLanguage =>
      _overrideLanguage ?? LanguageController.instance.englishName;
  DiagnosisModel? _diagnosis;
  OfflinePrediction? _offlineResult;
  DiagnosisSource? _source;
  int _lastScanId = -1;
  bool _isLoading = false;
  bool _isEscalating = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _feedbackGiven = false;
  String _errorMessage = '';

  File? get selectedImage => _selectedImage;
  String get description => _description;
  String get selectedLanguage => _selectedLanguage;
  DiagnosisModel? get diagnosis => _diagnosis;
  OfflinePrediction? get offlineResult => _offlineResult;
  DiagnosisSource? get source => _source;
  bool get isLoading => _isLoading;
  bool get isEscalating => _isEscalating;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  bool get feedbackGiven => _feedbackGiven;
  String get errorMessage => _errorMessage;

  bool get hasResult => _diagnosis != null || _offlineResult != null;
  bool get answeredOffline => _source == DiagnosisSource.onDevice;
  bool get didEscalate => _source == DiagnosisSource.cloudEscalated;

  String get resultTitle {
    if (_diagnosis != null) return _diagnosis!.detectedIssue;
    if (_offlineResult != null) return _offlineResult!.condition;
    return '';
  }

  String get resultCrop {
    if (_diagnosis != null) return _diagnosis!.cropType;
    if (_offlineResult != null) return _offlineResult!.cropType;
    return '';
  }

  double get resultConfidence {
    if (_diagnosis != null) return _diagnosis!.confidenceScore;
    if (_offlineResult != null) return _offlineResult!.confidence;
    return 0;
  }

  DiagnosisViewModel() {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _ttsService.initialize();
    _speech = stt.SpeechToText();
    await _speech.initialize();
    OfflineClassifier.instance.load();
    _ttsService.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  void setImage(File image) {
    _selectedImage = image;
    _resetResult();
    notifyListeners();
  }

  void setDescription(String desc) {
    _description = desc;
    notifyListeners();
  }

  void setLanguage(String language) {
    final code = switch (language) {
      'Hindi' => 'hi',
      'Kannada' => 'kn',
      _ => 'en',
    };
    LanguageController.instance.setLanguage(code);
    _overrideLanguage = language;
    _ttsService.setLanguage(language);
    notifyListeners();
  }

  void _resetResult() {
    _diagnosis = null;
    _offlineResult = null;
    _source = null;
    _lastScanId = -1;
    _feedbackGiven = false;
    _errorMessage = '';
  }

  Future<void> performDiagnosis({bool forceCloud = false}) async {
    if (_selectedImage == null) {
      _errorMessage = 'Please select an image first';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _isEscalating = false;
    _resetResult();
    notifyListeners();

    final result = await _service.diagnose(
      imageFile: _selectedImage!,
      description: _description,
      forceCloud: forceCloud,
      language: _selectedLanguage,
    );

    _source = result.source;
    _offlineResult = result.offline;
    _diagnosis = result.cloud;
    _lastScanId = result.localScanId;
    _errorMessage = result.error ?? '';
    _isLoading = false;
    _isEscalating = false;
    notifyListeners();
  }

  Future<void> askExpertModel() async {
    _isEscalating = true;
    notifyListeners();
    await performDiagnosis(forceCloud: true);
  }

  Future<void> submitFeedback({String? correctedLabel}) async {
    if (_lastScanId < 0) return;
    await _service.recordFeedback(_lastScanId, correctedLabel: correctedLabel);
    _feedbackGiven = true;
    notifyListeners();
  }

  String _sttLocale() {
    switch (_selectedLanguage) {
      case 'Hindi':
        return 'hi_IN';
      case 'Kannada':
        return 'kn_IN';
      default:
        return 'en_IN';
    }
  }

  Future<void> speak() async {
    if (!hasResult) return;
    _isSpeaking = true;
    notifyListeners();
    final text = _diagnosis != null
        ? '${_diagnosis!.cropType}. ${_diagnosis!.detectedIssue}. ${_diagnosis!.description}'
        : '${_offlineResult!.cropType}. ${_offlineResult!.condition}.';
    await _ttsService.speak(text);
  }

  Future<void> toggleSpeech() async {
    if (_isSpeaking) {
      await stopSpeaking();
    } else {
      await speak();
    }
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    } else {
      final available = await _speech.initialize(
        onError: (e) => print('STT ERROR: ${e.errorMsg}'),
        onStatus: (s) => print('STT STATUS: $s'),
      );
      print('STT AVAILABLE: $available');
      if (available) {
        _isListening = true;
        _speech.listen(
          localeId: _sttLocale(),
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            partialResults: true,
            cancelOnError: false,
            autoPunctuation: true,
          ),
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 6),
          onResult: (r) {
          _description = r.recognizedWords;
            descriptionController.text = r.recognizedWords;
            descriptionController.selection = TextSelection.fromPosition(
              TextPosition(offset: descriptionController.text.length),
            );
          notifyListeners();
        });
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }
}
