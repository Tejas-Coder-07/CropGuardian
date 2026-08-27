// Crop Guardian - backend API client
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Talks to the Crop Guardian API on Render. Every call degrades gracefully:
// if the network is unavailable the caller gets null and can fall back to
// cached data rather than showing an error to a farmer standing in a field.

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MarketPrice {
  final String crop;
  final String mandi;
  final String district;
  final String state;
  final double? distanceKm;
  final double currentPrice;
  final double currentPricePerKg;
  final double forecast7d;
  final double forecast7dPerKg;
  final double changePct;
  final String recommendation;
  final String confidence;
  final List<Map<String, dynamic>> history;
  final String disclaimer;

  MarketPrice.fromJson(Map<String, dynamic> j)
      : crop = j['crop'] ?? '',
        mandi = j['mandi'] ?? '',
        district = j['district'] ?? '',
        state = j['state'] ?? '',
        distanceKm = (j['distance_km'] as num?)?.toDouble(),
        currentPrice = (j['current_price'] as num).toDouble(),
        currentPricePerKg = (j['current_price_per_kg'] as num).toDouble(),
        forecast7d = (j['forecast_7d'] as num).toDouble(),
        forecast7dPerKg = (j['forecast_7d_per_kg'] as num).toDouble(),
        changePct = (j['change_pct'] as num).toDouble(),
        recommendation = j['recommendation'] ?? '',
        confidence = j['confidence'] ?? '',
        history = List<Map<String, dynamic>>.from(j['history'] ?? []),
        disclaimer = j['disclaimer'] ?? '';

  bool get isRising => changePct > 0;
}

class DiseaseRisk {
  final String disease;
  final String crop;
  final String riskLevel;
  final String reason;
  final String action;

  DiseaseRisk.fromJson(Map<String, dynamic> j)
      : disease = j['disease'] ?? '',
        crop = j['crop'] ?? '',
        riskLevel = j['risk_level'] ?? '',
        reason = j['reason'] ?? '',
        action = j['action'] ?? '';

  bool get isHigh => riskLevel.toLowerCase() == 'high';
}

class WeatherAdvisory {
  final String location;
  final double tempC;
  final int humidity;
  final double rainfallMm;
  final String conditions;
  final List<DiseaseRisk> risks;
  final String irrigationAdvice;
  final String disclaimer;

  WeatherAdvisory.fromJson(Map<String, dynamic> j)
      : location = j['location'] ?? '',
        tempC = (j['temp_c'] as num).toDouble(),
        humidity = (j['humidity'] as num).toInt(),
        rainfallMm = (j['rainfall_mm'] as num).toDouble(),
        conditions = j['conditions'] ?? '',
        risks = (j['risks'] as List? ?? [])
            .map((r) => DiseaseRisk.fromJson(r))
            .toList(),
        irrigationAdvice = j['irrigation_advice'] ?? '',
        disclaimer = j['disclaimer'] ?? '';
}

class SchemeResult {
  final String title;
  final String summary;
  final String sourceUrl;
  final String sourceName;

  SchemeResult.fromJson(Map<String, dynamic> j)
      : title = j['title'] ?? '',
        summary = j['summary'] ?? '',
        sourceUrl = j['source_url'] ?? '',
        sourceName = j['source_name'] ?? '';
}

class SchemeAnswer {
  final String query;
  final String? answer;
  final List<SchemeResult> results;
  final String disclaimer;

  SchemeAnswer.fromJson(Map<String, dynamic> j)
      : query = j['query'] ?? '',
        answer = j['answer'],
        results = (j['results'] as List? ?? [])
            .map((r) => SchemeResult.fromJson(r))
            .toList(),
        disclaimer = j['disclaimer'] ?? '';
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  static String get _base =>
      dotenv.env['API_BASE_URL'] ?? 'https://crop-guardian-api.onrender.com';

  // Render free tier sleeps; first call can take ~50s to wake the service.
  static const _timeout = Duration(seconds: 60);

  Future<Map<String, dynamic>?> _get(String path, Map<String, String> params) async {
    try {
      final uri = Uri.parse('$_base$path').replace(queryParameters: params);
      final resp = await http.get(uri).timeout(_timeout);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<MarketPrice?> marketPrice({
    required String crop,
    required double lat,
    required double lon,
  }) async {
    final j = await _get('/api/v1/market/prices/$crop', {
      'lat': lat.toString(),
      'lon': lon.toString(),
    });
    return j == null ? null : MarketPrice.fromJson(j);
  }

  Future<List<String>> availableCrops() async {
    final j = await _get('/api/v1/market/crops', {});
    if (j == null) return [];
    return List<String>.from(j['crops'] ?? []);
  }

  Future<WeatherAdvisory?> weatherAdvisory({
    required double lat,
    required double lon,
    String? crop,
  }) async {
    final params = {'lat': lat.toString(), 'lon': lon.toString()};
    if (crop != null && crop.isNotEmpty) params['crop'] = crop;
    final j = await _get('/api/v1/weather/advisory', params);
    return j == null ? null : WeatherAdvisory.fromJson(j);
  }

  Future<SchemeAnswer?> searchSchemes({
    required String query,
    String? state,
  }) async {
    final params = {'q': query};
    if (state != null && state.isNotEmpty) params['state'] = state;
    final j = await _get('/api/v1/schemes/search', params);
    return j == null ? null : SchemeAnswer.fromJson(j);
  }

  /// Escape hatch for endpoints without a typed model yet.
  Future<Map<String, dynamic>?> rawGet(String path, Map<String, String> params) =>
      _get(path, params);

  /// Asks the deployed Lyzr scheme agent. Returns null on any failure so the
  /// caller can fall back to the Tavily search tab.
  Future<Map<String, dynamic>?> askAgent(String message, {String? sessionId}) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_base/api/v1/agent/ask'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              if (sessionId != null) 'session_id': sessionId,
            }),
          )
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isReachable() async {
    final j = await _get('/health', {});
    return j != null;
  }
}