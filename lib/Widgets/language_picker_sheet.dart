// Crop Guardian - language switcher
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Native script only. A farmer who cannot read English should still be able
// to find their own language in this list.

import 'package:flutter/material.dart';
import '../core/language/language_controller.dart';

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({super.key});

  static const _options = [
    {'code': 'en', 'native': 'English', 'sub': 'English'},
    {'code': 'hi', 'native': 'हिंदी', 'sub': 'Hindi'},
    {'code': 'kn', 'native': 'ಕನ್ನಡ', 'sub': 'Kannada'},
  ];

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const LanguagePickerSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final current = LanguageController.instance.locale.languageCode;

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
              Icon(Icons.language, color: Color(0xFF047857)),
              SizedBox(width: 10),
              Text('भाषा / ಭಾಷೆ / Language',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ..._options.map((o) {
            final active = o['code'] == current;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFECFDF5) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? const Color(0xFF34D399) : Colors.grey.shade300,
                  width: active ? 1.6 : 1,
                ),
              ),
              child: ListTile(
                onTap: () async {
                  await LanguageController.instance.setLanguage(o['code']!);
                  if (context.mounted) Navigator.pop(context);
                },
                title: Text(o['native']!,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                subtitle: Text(o['sub']!,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                trailing: active
                    ? const Icon(Icons.check_circle, color: Color(0xFF047857))
                    : const Icon(Icons.circle_outlined, color: Colors.black26),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}