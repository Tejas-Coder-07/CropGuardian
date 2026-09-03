// Crop Guardian - emergency alerts
import 'package:crop_guardian/l10n/app_localizations.dart';
// Author: Tejas S <tejus.sgowda07@gmail.com>
import 'package:shared_preferences/shared_preferences.dart';
// Team Maverick - Cambridge Institute of Engineering

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/alerts/alert_service.dart';
import '../../core/location/location_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  FarmLocation? _farm;
  String? _watchDistrict;

  /// Districts a farmer might watch beyond their own - family land, a market
  /// they sell into, or a region where an outbreak is spreading toward them.
  static const _districts = [
    'Bengaluru Urban', 'Kolar', 'Chikkaballapur', 'Tumakuru', 'Mandya',
    'Mysuru', 'Hassan', 'Dharwad', 'Belagavi', 'Kalaburagi', 'Davanagere',
    'Pune', 'Nashik', 'Ahmednagar', 'Solapur', 'Nagpur',
  ];

  @override
  void initState() {
    super.initState();
    AlertService.instance.init();
    LocationService.instance.load().then((f) {
      if (mounted) setState(() => _farm = f);
    });
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() => _watchDistrict = prefs.getString('alert_watch_district'));
      }
    });
  }

  Color _severityColor(String s) => switch (s.toLowerCase()) {
        'critical' => Colors.red.shade700,
        'high' => Colors.orange.shade700,
        'medium' => Colors.amber.shade700,
        _ => Colors.blue.shade700,
      };

  IconData _typeIcon(String t) => switch (t.toLowerCase()) {
        'weather' => Icons.thunderstorm_outlined,
        'disease' => Icons.coronavirus_outlined,
        'pest' => Icons.pest_control_outlined,
        'market' => Icons.trending_down,
        _ => Icons.campaign_outlined,
      };

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
            Text(AppLocalizations.of(context).emergencyAlerts,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          _areaBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: AlertService.instance.alertStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final alerts = snap.data ?? [];
                if (alerts.isEmpty) return _emptyState();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (_, i) => _alertCard(alerts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDistrict() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Watch a district',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'Get warnings for somewhere other than your own farm - family land, or a region where disease is spreading.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.my_location, size: 20),
                    title: const Text('My farm location'),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  const Divider(height: 1),
                  ..._districts.map((d) => ListTile(
                        leading: const Icon(Icons.location_on_outlined, size: 20),
                        title: Text(d),
                        trailing: _watchDistrict == d
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF047857), size: 20)
                            : null,
                        onTap: () => Navigator.pop(context, d),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (picked.isEmpty) {
      await prefs.remove('alert_watch_district');
    } else {
      await prefs.setString('alert_watch_district', picked);
    }
    if (mounted) {
      setState(() => _watchDistrict = picked.isEmpty ? null : picked);
    }
  }

  Widget _areaBar() {
    final watching = _watchDistrict ?? _farm?.label;
    return InkWell(
      onTap: _pickDistrict,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: const Color(0xFFECFDF5),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                size: 16, color: Color(0xFF047857)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                watching == null
                    ? 'Tap to choose a district to watch'
                    : 'Watching ' + watching + ' for weather and outbreak warnings',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF047857)),
              ),
            ),
            const Icon(Icons.edit_location_alt_outlined,
                size: 16, color: Color(0xFF047857)),
          ],
        ),
      ),
    );
  }

  Widget _alertCard(Map<String, dynamic> a) {
    final severity = a['severity']?.toString() ?? 'info';
    final type = a['type']?.toString() ?? 'general';
    final color = _severityColor(severity);
    final ts = a['createdAt'];
    String when = '';
    try {
      if (ts != null) {
        when = DateFormat('d MMM, h:mm a').format(ts.toDate());
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon(type), size: 20, color: color),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              const Spacer(),
              Text(when,
                  style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 12),
          Text(a['title']?.toString() ?? '',
              style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF022C22))),
          const SizedBox(height: 6),
          Text(a['body']?.toString() ?? '',
              style: const TextStyle(fontSize: 13.5, height: 1.45)),
          if ((a['action']?.toString() ?? '').isNotEmpty) ...[
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
                      size: 16, color: Color(0xFF047857)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(a['action'].toString(),
                        style: const TextStyle(fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none,
                  size: 50, color: Colors.green.shade200),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).noAlertsRightNow,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              const Text(
                'You will be warned here about hailstorms, heavy rain,\n'
                'and disease outbreaks reported near your farm.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
              ),
            ],
          ),
        ),
      );
}
