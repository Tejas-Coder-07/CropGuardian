import 'package:crop_guardian/l10n/app_localizations.dart';
import 'package:crop_guardian/responsive_page.dart';
import 'package:flutter/material.dart';

import '../../Widgets/app_drawer.dart';
import 'widgets/feature_card.dart';
import 'widgets/quick_access_grid.dart';
import 'widgets/dashboard_footer.dart';
import '../../core/location/location_service.dart';
import 'widgets/hero_section.dart';
import 'widgets/stats_row.dart';
import 'widgets/trust_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _ensureLocation();
  }

  /// Asks for location once on first launch. Price, weather, alerts and
  /// scheme results are all keyed off where the farm is, so without this
  /// every one of those screens opens asking the farmer to set it manually.
  Future<void> _ensureLocation() async {
    final saved = await LocationService.instance.load();
    if (saved != null) return;
    await LocationService.instance.detectFromGps();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4FFF8),
        drawer: AppDrawer(selectedIndex: 0),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Padding(
            padding: const EdgeInsets.only(left: 45),
            child: Row(
              children: [
                Image.asset('assets/images/flogo.png',height: 35,width: 35,),
                SizedBox(width: 10,),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "CropGuardian",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                      ),

                    ]
                ),
              ],
            ),
          ),
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.menu, color: Colors.black),
          //     onPressed: () {},
          //   )
          // ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              HeroSection(),
              StatsRow(),
              const QuickAccessGrid(),
              TrustSection(),
              const DashboardFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
