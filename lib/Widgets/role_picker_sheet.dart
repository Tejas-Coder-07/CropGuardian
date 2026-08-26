// Crop Guardian - role switcher
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering

import 'package:flutter/material.dart';
import '../core/user/role_controller.dart';

class RolePickerSheet extends StatelessWidget {
  const RolePickerSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const RolePickerSheet(),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: RoleController.instance,
      builder: (context, _) {
        final current = RoleController.instance.role;

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
              const Text('I am a...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'This changes what you see in the marketplace.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              _option(
                context,
                role: UserRole.farmer,
                active: current == UserRole.farmer,
                icon: Icons.agriculture,
                title: 'Farmer',
                subtitle: 'Sell my produce and accept bids',
              ),
              const SizedBox(height: 10),
              _option(
                context,
                role: UserRole.buyer,
                active: current == UserRole.buyer,
                icon: Icons.shopping_basket_outlined,
                title: 'Buyer',
                subtitle: 'Browse produce and place bids',
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _option(
    BuildContext context, {
    required UserRole role,
    required bool active,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
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
          await RoleController.instance.setRole(role);
          if (context.mounted) Navigator.pop(context);
        },
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFECFDF5),
          child: Icon(icon, color: const Color(0xFF047857)),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
        trailing: active
            ? const Icon(Icons.check_circle, color: Color(0xFF047857))
            : const Icon(Icons.circle_outlined, color: Colors.black26),
      ),
    );
  }
}