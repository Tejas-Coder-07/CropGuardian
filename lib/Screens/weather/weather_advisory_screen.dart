// Crop Guardian - weather and disease risk advisory
import 'package:crop_guardian/l10n/app_localizations.dart';
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Turns local weather into crop-specific disease warnings so a farmer can act
// before symptoms appear, rather than after damage is already visible.

import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/location/location_service.dart';

class WeatherAdvisoryScreen extends StatefulWidget {
  const WeatherAdvisoryScreen({super.key});

  @override
  State<WeatherAdvisoryScreen> createState() => _WeatherAdvisoryScreenState();
}

class _WeatherAdvisoryScreenState extends State<WeatherAdvisoryScreen> {
  static const _crops = [
    'All crops', 'tomato', 'potato', 'rice', 'grape', 'cotton',
  ];

  String _crop = 'All crops';
  WeatherAdvisory? _data;
  FarmLocation? _farm;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _farm = await LocationService.instance.load();
    if (_farm == null) {
      setState(() { _loading = false; _error = 'location'; });
      return;
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = ''; });
    final d = await ApiClient.instance.weatherAdvisory(
      lat: _farm!.latitude,
      lon: _farm!.longitude,
      crop: _crop == 'All crops' ? null : _crop,
    );
    if (!mounted) return;
    setState(() {
      _data = d;
      _loading = false;
      if (d == null) _error = 'network';
    });
  }

  Future<void> _setLocation() async {
    setState(() => _loading = true);
    final loc = await LocationService.instance.detectFromGps();
    if (!mounted) return;
    if (loc == null) {
      setState(() { _loading = false; _error = 'permission'; });
      return;
    }
    _farm = loc;
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          children: [
            Text(AppLocalizations.of(context).weatherAdvisory,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _setLocation,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _cropSelector(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error.isNotEmpty)
              _errorCard()
            else if (_data != null) ...[
              _currentWeather(_data!),
              const SizedBox(height: 16),
              if (_data!.cropConditions != null) ...[
                _conditionsCard(_data!.cropConditions!),
                const SizedBox(height: 16),
              ],
              _risksSection(_data!),
              const SizedBox(height: 16),
              _irrigationCard(_data!),
              const SizedBox(height: 14),
              Text(_data!.disclaimer,
                  style: const TextStyle(
                      fontSize: 11.5, color: Colors.black45, height: 1.4)),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _cropSelector() => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _crops.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = _crops[i];
            final active = c == _crop;
            return ChoiceChip(
              label: Text(c == 'All crops' ? c : c[0].toUpperCase() + c.substring(1)),
              selected: active,
              onSelected: (_) {
                setState(() => _crop = c);
                _fetch();
              },
              selectedColor: const Color(0xFF34D399),
              labelStyle: TextStyle(
                color: active ? const Color(0xFF022C22) : Colors.black87,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            );
          },
        ),
      );

  Widget _currentWeather(WeatherAdvisory w) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF022C22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFF34D399)),
                const SizedBox(width: 6),
                Text(w.location,
                    style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${w.tempC.toStringAsFixed(0)}°',
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(w.conditions,
                      style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _metric(Icons.water_drop_outlined, '${w.humidity}%', 'Humidity'),
                const SizedBox(width: 28),
                _metric(Icons.umbrella_outlined,
                    '${w.rainfallMm.toStringAsFixed(1)} mm', 'Rain (3h)'),
              ],
            ),
          ],
        ),
      );

  Widget _metric(IconData icon, String value, String label) => Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF34D399)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(label,
                  style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 11)),
            ],
          ),
        ],
      );

  Widget _conditionsCard(Map<String, dynamic> c) {
    final readings = (c['readings'] as List? ?? []);
    final allIdeal = c['all_ideal'] == true;
    final watch = (c['watch_for'] as List? ?? []);
    final prevent = (c['preventive'] as List? ?? []);

    Color statusColor(String s) => switch (s) {
          'ideal' => const Color(0xFF047857),
          'above' => Colors.orange.shade700,
          _ => Colors.blue.shade700,
        };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allIdeal ? const Color(0xFF34D399) : Colors.orange.shade200,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(allIdeal ? Icons.check_circle_outline : Icons.info_outline,
                  size: 18,
                  color: allIdeal
                      ? const Color(0xFF047857)
                      : Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c['summary'] ?? '',
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.35)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...readings.map((r) {
            final status = r['status'] as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r['detail'] ?? '',
                        style: const TextStyle(fontSize: 12.5, height: 1.4)),
                  ),
                ],
              ),
            );
          }),
          if (watch.isNotEmpty) ...[
            const Divider(height: 20),
            Text(AppLocalizations.of(context).watchOutFor,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            ...watch.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('- ' + w.toString(),
                      style: const TextStyle(fontSize: 12.5, height: 1.35)),
                )),
          ],
          if (prevent.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Good practice now',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857))),
                  const SizedBox(height: 7),
                  ...prevent.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text('- ' + p.toString(),
                            style: const TextStyle(fontSize: 12.5, height: 1.35)),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _risksSection(WeatherAdvisory w) {
    if (w.risks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF047857)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No weather-linked disease risk right now. Keep monitoring your crop.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).diseaseRiskWeather,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...w.risks.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: r.isHigh ? Colors.red.shade300 : Colors.orange.shade300,
                  width: 1.4,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: r.isHigh ? Colors.red.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(r.riskLevel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: r.isHigh
                                  ? Colors.red.shade800
                                  : Colors.orange.shade800,
                            )),
                      ),
                      const Spacer(),
                      Text(r.crop,
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(r.disease,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF022C22))),
                  const SizedBox(height: 6),
                  Text(r.reason,
                      style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.35)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 17, color: Color(0xFF047857)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r.action,
                              style: const TextStyle(fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _irrigationCard(WeatherAdvisory w) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.water, color: Color(0xFF0284C7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).irrigationAdvice,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(w.irrigationAdvice,
                      style: const TextStyle(fontSize: 13.5, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _errorCard() {
    final needsLocation = _error == 'location' || _error == 'permission';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(needsLocation ? Icons.location_off : Icons.wifi_off,
              size: 40, color: Colors.orange.shade700),
          const SizedBox(height: 14),
          Text(
            needsLocation
                ? 'Set your farm location to get weather advice for your area.'
                : 'Could not reach the weather service. Pull down to retry.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: needsLocation ? _setLocation : _fetch,
            icon: Icon(needsLocation ? Icons.my_location : Icons.refresh),
            label: Text(needsLocation ? 'Use my location' : 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF166534),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
