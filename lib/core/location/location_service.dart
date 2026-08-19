// Crop Guardian - farmer location service
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// One source of truth for where the farm is. Price, weather, scheme and
// language services all read from here rather than asking separately.

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmLocation {
  final double latitude;
  final double longitude;
  final String district;
  final String state;
  final DateTime savedAt;

  FarmLocation({
    required this.latitude,
    required this.longitude,
    required this.district,
    required this.state,
    required this.savedAt,
  });

  String get label => district.isEmpty ? 'Location set' : '$district, $state';

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'district': district,
        'state': state,
        'savedAt': savedAt.toIso8601String(),
      };

  factory FarmLocation.fromJson(Map<String, dynamic> j) => FarmLocation(
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        district: j['district'] ?? '',
        state: j['state'] ?? '',
        savedAt: DateTime.parse(j['savedAt']),
      );
}

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  static const _kLat = 'farm_lat';
  static const _kLon = 'farm_lon';
  static const _kDistrict = 'farm_district';
  static const _kState = 'farm_state';
  static const _kSavedAt = 'farm_saved_at';

  FarmLocation? _cached;
  FarmLocation? get cached => _cached;

  /// Reads the saved farm location. Works offline - no network needed.
  Future<FarmLocation?> load() async {
    if (_cached != null) return _cached;
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kLat);
    final lon = prefs.getDouble(_kLon);
    if (lat == null || lon == null) return null;

    _cached = FarmLocation(
      latitude: lat,
      longitude: lon,
      district: prefs.getString(_kDistrict) ?? '',
      state: prefs.getString(_kState) ?? '',
      savedAt: DateTime.tryParse(prefs.getString(_kSavedAt) ?? '') ?? DateTime.now(),
    );
    return _cached;
  }

  Future<void> save(FarmLocation loc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLat, loc.latitude);
    await prefs.setDouble(_kLon, loc.longitude);
    await prefs.setString(_kDistrict, loc.district);
    await prefs.setString(_kState, loc.state);
    await prefs.setString(_kSavedAt, loc.savedAt.toIso8601String());
    _cached = loc;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_kLat, _kLon, _kDistrict, _kState, _kSavedAt]) {
      await prefs.remove(k);
    }
    _cached = null;
  }

  /// Requests permission and reads GPS. Returns null if the farmer declines
  /// or location services are off - callers should fall back to manual entry.
  Future<FarmLocation?> detectFromGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );

    var district = '';
    var state = '';
    try {
      final places = await Geocoding().placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (places.isNotEmpty) {
        final p = places.first;
        district = p.subAdministrativeArea ?? p.locality ?? '';
        state = p.administrativeArea ?? '';
      }
    } catch (_) {
      // Reverse geocoding needs network. Coordinates alone are still useful.
    }

    final loc = FarmLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      district: district,
      state: state,
      savedAt: DateTime.now(),
    );
    await save(loc);
    return loc;
  }

  /// Default app language based on the farmer's state.
  String suggestedLanguage() {
    switch (_cached?.state) {
      case 'Karnataka':
        return 'Kannada';
      case 'Maharashtra':
      case 'Uttar Pradesh':
      case 'Bihar':
      case 'Madhya Pradesh':
      case 'Rajasthan':
        return 'Hindi';
      default:
        return 'English';
    }
  }
}