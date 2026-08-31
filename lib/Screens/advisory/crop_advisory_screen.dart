// Crop Guardian - crop advisory (fertiliser, soil health, season plan)
import 'package:crop_guardian/l10n/app_localizations.dart';
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// One screen, three advisory modes. Results are cached locally so a farmer
// who asked once can read the answer again with no network.

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/data/local_database.dart';
import '../../core/location/location_service.dart';

enum AdvisoryMode { fertiliser, soil, plan }

class CropAdvisoryScreen extends StatefulWidget {
  const CropAdvisoryScreen({super.key});

  @override
  State<CropAdvisoryScreen> createState() => _CropAdvisoryScreenState();
}

class _CropAdvisoryScreenState extends State<CropAdvisoryScreen> {
  static const _crops = [
    'tomato', 'potato', 'onion', 'rice', 'wheat',
    'maize', 'cotton', 'ragi', 'groundnut', 'sugarcane',
  ];

  AdvisoryMode _mode = AdvisoryMode.fertiliser;
  String _crop = 'tomato';
  String? _state;
  Map<String, dynamic>? _data;
  bool _loading = false;
  bool _fromCache = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final farm = await LocationService.instance.load();
    if (mounted) setState(() => _state = farm?.state);
  }

  String get _path => switch (_mode) {
        AdvisoryMode.fertiliser => '/api/v1/advisory/fertiliser',
        AdvisoryMode.soil => '/api/v1/advisory/soil-health',
        AdvisoryMode.plan => '/api/v1/advisory/crop-plan',
      };

  String get _cacheKey => 'advisory_${_mode.name}_${_crop}_${_state ?? "in"}';

  String get _title => switch (_mode) {
        AdvisoryMode.fertiliser => 'Fertiliser guidance',
        AdvisoryMode.soil => 'Soil health',
        AdvisoryMode.plan => 'Season plan',
      };

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = ''; _data = null; _fromCache = false; });

    final params = {'crop': _crop};
    if (_state != null) params['state'] = _state!;

    final json = await ApiClient.instance.rawGet(_path, params);

    if (json != null) {
      await LocalDatabase.instance.cacheAdvisory(_cacheKey, jsonEncode(json));
      if (!mounted) return;
      setState(() { _data = json; _loading = false; });
      return;
    }

    // Offline - fall back to whatever this farmer asked for before.
    final cached = await LocalDatabase.instance
        .readAdvisory(_cacheKey, maxAge: const Duration(days: 30));
    if (!mounted) return;

    if (cached != null) {
      setState(() {
        _data = jsonDecode(cached['payload'] as String);
        _loading = false;
        _fromCache = true;
      });
    } else {
      setState(() {
        _loading = false;
        _error = 'No connection, and no saved advice for this crop yet.';
      });
    }
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
            Text(AppLocalizations.of(context).cropAdvisory,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _modeTabs(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).selectCrop,
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 8),
          _cropChips(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _fetch,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(_loading ? 'Getting advice...' : 'Get $_title'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error.isNotEmpty) _errorBox(),
          if (_data != null) ..._result(_data!),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _modeTabs() => Row(
        children: AdvisoryMode.values.map((m) {
          final active = m == _mode;
          final label = switch (m) {
            AdvisoryMode.fertiliser => 'Fertiliser',
            AdvisoryMode.soil => 'Soil',
            AdvisoryMode.plan => 'Plan',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _mode = m; _data = null; _error = ''; }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF34D399) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? const Color(0xFF022C22) : Colors.black87,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _cropChips() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _crops.map((c) {
          final active = c == _crop;
          return ChoiceChip(
            label: Text(c[0].toUpperCase() + c.substring(1)),
            selected: active,
            onSelected: (_) => setState(() { _crop = c; _data = null; }),
            selectedColor: const Color(0xFF34D399),
          );
        }).toList(),
      );

  List<Widget> _result(Map<String, dynamic> d) {
    final steps = (d['steps'] as List? ?? []);
    final warnings = (d['warnings'] as List? ?? []);

    return [
      if (_fromCache)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.offline_pin_outlined, size: 16, color: Color(0xFF047857)),
              SizedBox(width: 8),
              Expanded(
                child: Text('Saved advice, shown offline',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF047857))),
              ),
            ],
          ),
        ),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF022C22),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(d['summary'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.5)),
      ),
      const SizedBox(height: 18),
      ...steps.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF34D399),
                child: Text('${i + 1}',
                    style: const TextStyle(
                        color: Color(0xFF022C22),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['title'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14.5)),
                    const SizedBox(height: 5),
                    Text(s['detail'] ?? '',
                        style: const TextStyle(fontSize: 13.5, height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      if (warnings.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(AppLocalizations.of(context).watchOutFor,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...warnings.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 17, color: Colors.orange.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(w.toString(),
                        style: const TextStyle(fontSize: 13.5, height: 1.4)),
                  ),
                ],
              ),
            )),
      ],
    ];
  }

  Widget _errorBox() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text(_error, style: const TextStyle(fontSize: 13.5))),
          ],
        ),
      );
}
