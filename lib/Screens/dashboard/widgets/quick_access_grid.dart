// Crop Guardian - quick access grid
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Every working feature reachable in one tap from the main screen. A farmer
// should not have to find a hidden menu to check tomorrow's disease risk.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../weather/weather_advisory_screen.dart';
import '../../expenses/expense_tracker_screen.dart';
import '../../advisory/crop_advisory_screen.dart';
import '../../alerts/alerts_screen.dart';
import '../../carbon/carbon_footprint_screen.dart';
import '../../resources/resource_screen.dart';
import '../../resources/pages/market_prices_page.dart';
import '../../resources/pages/government_schemes_page.dart';
import '../../resources/pages/learning_resources_page.dart';
import '../../community_screen/community_screen.dart';
import '../../Sells_Screen/market_feed_screen.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final items = <_QuickItem>[
      _QuickItem(t.weatherAdvisory, Icons.cloud_outlined,
          const Color(0xFF0284C7), () => const WeatherAdvisoryScreen()),
      _QuickItem(t.marketPrices, Icons.trending_up,
          const Color(0xFF047857), () => const _Standalone(title: 'Market Prices', child: MarketPricesPage())),
      _QuickItem(t.governmentSchemes, Icons.account_balance_outlined,
          const Color(0xFF1D4ED8), () => const _Standalone(title: 'Government Schemes', child: GovernmentSchemesPage())),
      _QuickItem('Learning', Icons.menu_book_outlined,
          const Color(0xFF7C2D12), () => const _Standalone(title: 'Learning', child: LearningResourcesPage())),
      _QuickItem(t.cropAdvisory, Icons.tips_and_updates_outlined,
          const Color(0xFFB45309), () => const CropAdvisoryScreen()),
      _QuickItem(t.emergencyAlerts, Icons.notifications_active_outlined,
          const Color(0xFFB91C1C), () => const AlertsScreen()),
      _QuickItem(t.farmExpenses, Icons.account_balance_wallet_outlined,
          const Color(0xFF6D28D9), () => const ExpenseTrackerScreen()),
      _QuickItem(t.community, Icons.forum_outlined,
          const Color(0xFF0F766E), () => CommunityScreen()),
      _QuickItem(t.marketPlace, Icons.storefront_outlined,
          const Color(0xFF9D174D), () => const MarketFeedScreen()),
      _QuickItem('Carbon', Icons.eco_outlined,
          const Color(0xFF3F6212), () => const CarbonFootprintScreen()),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.powerfulFeatures,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF022C22)),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _tile(context, items[i]),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, _QuickItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Get.to(item.builder),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.color, size: 28),
          ),
          const SizedBox(height: 7),
          Flexible(
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.25, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a Resources tab page so it can open as its own screen with an
/// app bar, instead of only being reachable inside the tabbed view.
class _Standalone extends StatelessWidget {
  final String title;
  final Widget child;
  const _Standalone({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: child,
    );
  }
}

class _QuickItem {
  final String label;
  final IconData icon;
  final Color color;
  final Widget Function() builder;

  _QuickItem(this.label, this.icon, this.color, this.builder);
}
