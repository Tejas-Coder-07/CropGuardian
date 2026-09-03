// Crop Guardian - app language controller
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Remembers the farmer's language across restarts. On first launch it can be
// seeded from the farm's state, so a Karnataka farmer opens the app in Kannada
// rather than English.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  static final LanguageController instance = LanguageController._();
  LanguageController._();

  static const _key = 'app_language_code';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  static const supported = [
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
  ];

  String get languageName => switch (_locale.languageCode) {
        'hi' => 'हिंदी',
        'kn' => 'ಕನ್ನಡ',
        _ => 'English',
      };

  /// Name used for speech and Gemini prompts, which expect English labels.
  String get englishName => switch (_locale.languageCode) {
        'hi' => 'Hindi',
        'kn' => 'Kannada',
        _ => 'English',
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    Get.updateLocale(_locale);
    notifyListeners();
  }

  /// Called once after location is known, if the farmer has not chosen yet.
  Future<void> suggestFromState(String state) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_key) != null) return;

    final code = switch (state) {
      'Karnataka' => 'kn',
      'Maharashtra' || 'Uttar Pradesh' || 'Bihar' ||
      'Madhya Pradesh' || 'Rajasthan' => 'hi',
      _ => 'en',
    };
    await setLanguage(code);
  }
}
