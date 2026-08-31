// Crop Guardian - emergency alerts
import 'package:crop_guardian/l10n/app_localizations.dart';
// Author: Tejas S <tejus.sgowda07@gmail.com>
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

  @override
  void initState() {
    super.initState();
    AlertService.instance.init();
    LocationService.instance.load().then((f) {
      if (mounted) setState(() => _farm = f);
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
          if (_farm != null) _areaBar(),
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

  Widget _areaBar() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        color: const Color(0xFFECFDF5),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                size: 16, color: Color(0xFF047857)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Watching ${_farm!.label} for weather and outbreak warnings',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF047857)),
              ),
            ),
          ],
        ),
      );

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
