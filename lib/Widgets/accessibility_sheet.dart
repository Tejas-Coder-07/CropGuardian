// Crop Guardian - accessibility settings
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering

import 'package:flutter/material.dart';
import '../core/accessibility/accessibility_controller.dart';

class AccessibilitySheet extends StatelessWidget {
  const AccessibilitySheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const AccessibilitySheet(),
      );

  @override
  Widget build(BuildContext context) {
    final a11y = AccessibilityController.instance;

    return AnimatedBuilder(
      animation: a11y,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(20),
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
              const Row(
                children: [
                  Icon(Icons.accessibility_new, color: Color(0xFF047857)),
                  SizedBox(width: 10),
                  Text('Accessibility',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: a11y.readAloudEnabled,
                activeThumbColor: const Color(0xFF047857),
                onChanged: (v) => a11y.setReadAloud(v),
                title: const Text('Read screens aloud',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'A speaker button appears on each screen. Tap it to hear the page.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Text size',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Aa', style: TextStyle(fontSize: 15 * a11y.textScale)),
              Slider(
                value: a11y.textScale,
                min: 0.9,
                max: 1.6,
                divisions: 7,
                activeColor: const Color(0xFF34D399),
                label: '${(a11y.textScale * 100).toInt()}%',
                onChanged: (v) => a11y.setTextScale(v),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: a11y.highContrast,
                activeThumbColor: const Color(0xFF047857),
                onChanged: (v) => a11y.setHighContrast(v),
                title: const Text('High contrast',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Darker text and stronger borders for bright sunlight.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}