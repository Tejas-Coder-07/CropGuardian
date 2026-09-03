// Crop Guardian - app footer
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardFooter extends StatelessWidget {
  const DashboardFooter({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      color: const Color(0xFF022C22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: Color(0xFF34D399), size: 20),
              const SizedBox(width: 8),
              const Text('Crop Guardian',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Offline-first crop health support for smallholder farmers.',
            style: TextStyle(
                color: Color(0xFFA7F3D0), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 18),
          _row(Icons.mail_outline, 'tejus.sgowda07@gmail.com',
              () => _open('mailto:tejus.sgowda07@gmail.com')),
          const SizedBox(height: 10),
          _row(Icons.phone_outlined, '+91 95130 65382',
              () => _open('tel:+919513065382')),
          const SizedBox(height: 10),
          _row(Icons.school_outlined,
              'Cambridge Institute of Engineering, Bengaluru', null),
          const SizedBox(height: 20),
          Container(height: 1, color: const Color(0xFF0B4A3A)),
          const SizedBox(height: 14),
          const Text(
            'Diagnosis runs on your device. Advisory guidance is indicative - '
            'confirm chemical use with your local agriculture officer.',
            style: TextStyle(
                color: Color(0xFF6B8F82), fontSize: 10.5, height: 1.5),
          ),
          const SizedBox(height: 10),
          const Text('(c) 2026 Team Maverick. All rights reserved.',
              style: TextStyle(color: Color(0xFF6B8F82), fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF34D399)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFFA7F3D0), fontSize: 12, height: 1.3)),
          ),
        ],
      ),
    );
  }
}