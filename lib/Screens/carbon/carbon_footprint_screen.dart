// Crop Guardian - carbon footprint
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// A farmer enters what they used this season and sees where the emissions came
// from, with the biggest lever highlighted. Residue burning dominates when
// present, which is the point - it makes the case for stopping it.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CarbonFootprintScreen extends StatefulWidget {
  const CarbonFootprintScreen({super.key});

  @override
  State<CarbonFootprintScreen> createState() => _CarbonFootprintScreenState();
}

class _CarbonFootprintScreenState extends State<CarbonFootprintScreen> {
  final _fields = <String, TextEditingController>{
    'area_hectares': TextEditingController(text: '1'),
    'urea_kg': TextEditingController(),
    'dap_kg': TextEditingController(),
    'mop_kg': TextEditingController(),
    'pesticide_litres': TextEditingController(),
    'diesel_litres': TextEditingController(),
    'electricity_kwh': TextEditingController(),
    'manure_tonnes': TextEditingController(),
    'residue_burnt_tonnes': TextEditingController(),
  };

  static const _labels = {
    'area_hectares': 'Farm area (hectares)',
    'urea_kg': 'Urea used (kg)',
    'dap_kg': 'DAP used (kg)',
    'mop_kg': 'MOP used (kg)',
    'pesticide_litres': 'Pesticide (litres)',
    'diesel_litres': 'Diesel (litres)',
    'electricity_kwh': 'Pump electricity (kWh)',
    'manure_tonnes': 'Farmyard manure (tonnes)',
    'residue_burnt_tonnes': 'Crop residue burnt (tonnes)',
  };

  Map<String, dynamic>? _result;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _calculate() async {
    setState(() { _loading = true; _error = ''; });

    final body = <String, dynamic>{};
    for (final e in _fields.entries) {
      body[e.key] = double.tryParse(e.value.text.trim()) ?? 0;
    }

    final base = dotenv.env['API_BASE_URL'] ??
        'https://crop-guardian-api.onrender.com';

    try {
      final resp = await http
          .post(
            Uri.parse('$base/api/v1/carbon/footprint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;
      if (resp.statusCode == 200) {
        setState(() {
          _result = jsonDecode(resp.body);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Could not calculate. Try again.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No connection. This calculation needs internet.';
      });
    }
  }

  Color _ratingColor(String r) => switch (r) {
        'low' => const Color(0xFF047857),
        'moderate' => Colors.amber.shade800,
        'high' => Colors.orange.shade800,
        _ => Colors.red.shade700,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Column(
          children: [
            Text('Carbon Footprint',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('कार्बन फुटप्रिंट', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Enter what you used this season. Leave blank what does not apply.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ..._fields.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: e.value,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _labels[e.key],
                    border: const OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              )),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _calculate,
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: Text(_loading ? 'Calculating...' : 'Calculate footprint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error, style: const TextStyle(fontSize: 13)),
            ),
          ],
          if (_result != null) ..._resultView(_result!),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  List<Widget> _resultView(Map<String, dynamic> r) {
    final rating = r['rating'] as String;
    final color = _ratingColor(rating);
    final breakdown = (r['breakdown'] as List? ?? []);
    final suggestions = (r['suggestions'] as List? ?? []);

    return [
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF022C22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TOTAL EMISSIONS',
                style: TextStyle(
                    color: Color(0xFF34D399), fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${r['total_kg_co2e']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Text('kg CO2e',
                    style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 14)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(rating.toUpperCase(),
                      style: TextStyle(
                          color: color == const Color(0xFF047857)
                              ? const Color(0xFF34D399)
                              : color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Text('${r['per_hectare_kg_co2e']} kg per hectare',
                    style: const TextStyle(
                        color: Color(0xFFA7F3D0), fontSize: 12.5)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (breakdown.isNotEmpty) ...[
        const Text('Where it comes from',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Column(
            children: breakdown.map<Widget>((b) {
              final kg = (b['kg_co2e'] as num).toDouble();
              final isSink = kg < 0;
              final pct = ((b['share_pct'] as num).toDouble().abs()) / 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(b['source'],
                              style: const TextStyle(fontSize: 13.5)),
                        ),
                        Text(
                          '${isSink ? "" : "+"}${kg.toStringAsFixed(0)} kg',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isSink
                                ? const Color(0xFF047857)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: const Color(0xFFECFDF5),
                        valueColor: AlwaysStoppedAnimation(
                          isSink ? const Color(0xFF34D399) : Colors.orange.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
      const SizedBox(height: 16),
      if (suggestions.isNotEmpty) ...[
        const Text('How to reduce it',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...suggestions.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.eco_outlined,
                      size: 17, color: Color(0xFF047857)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.toString(),
                        style: const TextStyle(fontSize: 13, height: 1.45)),
                  ),
                ],
              ),
            )),
        if ((r['potential_saving_kg'] as num) > 0)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF34D399), width: 1.4),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_down, color: Color(0xFF047857)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Following these could cut about '
                    '${(r['potential_saving_kg'] as num).toStringAsFixed(0)} kg CO2e.',
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
      const SizedBox(height: 14),
      Text(r['disclaimer'] ?? '',
          style: const TextStyle(
              fontSize: 11.5, color: Colors.black45, height: 1.4)),
    ];
  }
}