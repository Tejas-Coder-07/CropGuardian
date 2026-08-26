// Crop Guardian - accessibility service
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Reads any screen aloud in the farmer's language, and scales text for older
// eyes. A farmer who cannot read should still be able to use every feature.

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../language/language_controller.dart';

class AccessibilityController extends ChangeNotifier {
  static final AccessibilityController instance = AccessibilityController._();
  AccessibilityController._();

  static const _kScale = 'a11y_text_scale';
  static const _kContrast = 'a11y_high_contrast';
  static const _kReadAloud = 'a11y_read_aloud';

  final FlutterTts _tts = FlutterTts();

  double _textScale = 1.0;
  bool _highContrast = false;
  bool _readAloudEnabled = false;
  bool _speaking = false;

  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  bool get readAloudEnabled => _readAloudEnabled;
  bool get isSpeaking => _speaking;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _textScale = prefs.getDouble(_kScale) ?? 1.0;
    _highContrast = prefs.getBool(_kContrast) ?? false;
    _readAloudEnabled = prefs.getBool(_kReadAloud) ?? false;

    _tts.setCompletionHandler(() {
      _speaking = false;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kScale, scale);
  }

  Future<void> setHighContrast(bool on) async {
    _highContrast = on;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kContrast, on);
  }

  Future<void> setReadAloud(bool on) async {
    _readAloudEnabled = on;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReadAloud, on);
    if (!on) await stop();
  }

  String _ttsLocale() => switch (LanguageController.instance.locale.languageCode) {
        'hi' => 'hi-IN',
        'kn' => 'kn-IN',
        _ => 'en-IN',
      };

  /// Speaks the given text in the farmer's language.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.setLanguage(_ttsLocale());
    await _tts.setSpeechRate(0.45);
    _speaking = true;
    notifyListeners();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
    notifyListeners();
  }

  Future<void> toggle(String text) async {
    if (_speaking) {
      await stop();
    } else {
      await speak(text);
    }
  }
}