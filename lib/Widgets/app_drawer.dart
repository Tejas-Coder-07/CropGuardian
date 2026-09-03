import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crop_guardian/core/user/role_controller.dart';
import 'package:crop_guardian/l10n/app_localizations.dart';
import 'package:crop_guardian/Widgets/role_picker_sheet.dart';
import 'package:crop_guardian/Screens/weather/weather_advisory_screen.dart';
import 'package:crop_guardian/Widgets/accessibility_sheet.dart';
import 'package:crop_guardian/Screens/expenses/expense_tracker_screen.dart';
import 'package:crop_guardian/Screens/admin/admin_panel_screen.dart';
import 'package:crop_guardian/Screens/advisory/crop_advisory_screen.dart';
import 'package:crop_guardian/Screens/carbon/carbon_footprint_screen.dart';
import 'package:crop_guardian/Screens/alerts/alerts_screen.dart';
import 'package:crop_guardian/Widgets/language_picker_sheet.dart';
import 'package:crop_guardian/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth
import '../Authentication/login_screen.dart';
import '../Screens/community_screen/community_screen.dart';
import '../Screens/dashboard/dashboard_screen.dart';
import '../Screens/diagnosis_screen/diagnosis_screen.dart';
import '../Screens/farmer_profile/farmer_profile_screen.dart';
import '../Screens/resources/resource_screen.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;

  const AppDrawer({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          // 1. Background Decorative Gradient Strip
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFFC6FF00)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Column(
            children: [
              _buildModernHeader(context),
              const SizedBox(height: 20),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildGradientTile(
                        context,
                        title: AppLocalizations.of(context).dashboard,
                        icon: Icons.dashboard_customize_rounded,
                        index: 0,
                        onTap: () => Get.offAll(() => const DashboardScreen()),
                      ),
                      _buildGradientTile(
                        context,
                        title: AppLocalizations.of(context).aiDiagnosis,
                        icon: Icons.center_focus_strong_rounded,
                        index: 1,
                        onTap: () => Get.to(() => const DiagnosisScreen()),
                      ),
                      _buildGradientTile(
                        context,
                        title: AppLocalizations.of(context).community,
                        icon: Icons.forum_rounded,
                        index: 2,
                        onTap: () => Get.to(() => CommunityScreen()),
                      ),
                      _buildGradientTile(
                        context,
                        title: AppLocalizations.of(context).resources,
                        icon: Icons.auto_stories_rounded,
                        index: 3,
                        onTap: () => Get.to(() => const ResourcesScreen()),
                      ),
                      _buildGradientTile(
                        context,
                        title: AppLocalizations.of(context).weatherAdvisory,
                        icon: Icons.cloud_outlined,
                        index: 4,
                        onTap: () => Get.to(() => const WeatherAdvisoryScreen()),
                      ),
                      _buildGradientTile(
                        context,
                        title: AppLocalizations.of(context).farmExpenses,
                        icon: Icons.account_balance_wallet_outlined,
                        index: 5,
                        onTap: () => Get.to(() => const ExpenseTrackerScreen()),
                      ),
                      _buildGradientTile(
                        context,
                        title: AppLocalizations.of(context).cropAdvisory,
                        icon: Icons.tips_and_updates_outlined,
                        index: 6,
                        onTap: () => Get.to(() => const CropAdvisoryScreen()),
                      ),
                      _buildGradientTile(
                        context,
                        title: AppLocalizations.of(context).emergencyAlerts,
                        icon: Icons.notifications_active_outlined,
                        index: 7,
                        onTap: () => Get.to(() => const AlertsScreen()),
                      ),
                      _buildGradientTile(
                        context,
                        title: AppLocalizations.of(context).language,
                        icon: Icons.language,
                        index: 8,
                        onTap: () => LanguagePickerSheet.show(context),
                      ),
                      _buildGradientTile(
                        context,
                        title: "Buyer / Seller",
                        icon: Icons.swap_horiz,
                        index: 9,
                        onTap: () => RolePickerSheet.show(context),
                      ),
                      _buildGradientTile(
                        context,
                        title: "Accessibility",
                        icon: Icons.accessibility_new,
                        index: 10,
                        onTap: () => AccessibilitySheet.show(context),
                      ),
                      if (RoleController.instance.isAdmin)
                        _buildGradientTile(
                          context,
                        title: "Admin Panel",
                        icon: Icons.admin_panel_settings_outlined,
                        index: 11,
                        onTap: () => Get.to(() => const AdminPanelScreen()),
                      ),
                      _buildGradientTile(
                        context,
                        title: "Carbon Footprint",
                        icon: Icons.eco_outlined,
                        index: 12,
                        onTap: () => Get.to(() => const CarbonFootprintScreen()),
                      ),
                    ],
                  ),
                ),
              ),

              _buildBottomProfile(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, bottom: 40, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Icon(Icons.eco_rounded, color: Color(0xFF1B5E20), size: 40),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "CropGuardian",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Text(
            "Smart Agriculture",
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientTile(
      BuildContext context, {
        required String title,
        String hindi = '',
        required IconData icon,
        required int index,
        required VoidCallback onTap,
      }) {
    bool isActive = selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isActive
            ? const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        )
            : null,
        boxShadow: isActive
            ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[700],
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isActive ? Colors.white : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildBottomProfile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => Get.to(() => FarmerProfileScreen(userId: 'unique_id')),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFC6FF00),
                    child: Icon(Icons.person_rounded, color: Colors.black),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("My Profile", style: TextStyle(fontWeight: FontWeight.w900)),
                      Text(AppLocalizations.of(context).profile, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.settings_suggest_rounded, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          // --- UPDATED LOGOUT SECTION ---
          TextButton.icon(
            onPressed: () async {
              try {
                // 1. Logs out the user from Firebase server
                await FirebaseAuth.instance.signOut();

                // 2. Navigates to Login and deletes all previous screens from memory
                Get.offAll(() => const LoginScreen());

                // 3. Success feedback
                Get.snackbar(
                  "Success",
                  "Successfully Logged Out",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                );
              } catch (e) {
                Get.snackbar(
                  "Error",
                  "Logout failed: $e",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.red),
            label: Text(
              AppLocalizations.of(context).logout,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
