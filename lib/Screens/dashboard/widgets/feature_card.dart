import 'package:crop_guardian/l10n/app_localizations.dart';
import 'package:crop_guardian/Screens/Sells_Screen/market_feed_screen.dart';
import 'package:crop_guardian/Screens/Sells_Screen/sell_item_screen.dart';
import 'package:crop_guardian/Screens/community_screen/community_screen.dart';
import 'package:crop_guardian/Screens/diagnosis_screen/diagnosis_screen.dart';
import 'package:crop_guardian/Screens/organic_screen/organic_solution_page.dart';
import 'package:crop_guardian/Screens/resources/resource_screen.dart';
import 'package:flutter/material.dart';

class FeatureSection extends StatelessWidget {
  const FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Header with Dual Language
          Text(
            AppLocalizations.of(context).powerfulFeatures,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B5E20),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 25),

          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>DiagnosisScreen()));
            },
            child: _buildMultiColorCard(
              title: AppLocalizations.of(context).aiDiagnosis,
              description: AppLocalizations.of(context).diagnosisDesc,
              icon: Icons.auto_awesome_rounded,
              // Gradient: Deep Green to Lime
              gradientColors: [const Color(0xFF1B5E20), const Color(0xFF4CAF50)],
            ),
          ),

          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>CommunityScreen()));
            },
            child: _buildMultiColorCard(
              title: AppLocalizations.of(context).community,
              description: AppLocalizations.of(context).communityDesc,
              icon: Icons.groups_3_rounded,
              // Gradient: Deep Orange to Amber
              gradientColors: [const Color(0xFFE65100), const Color(0xFFFFB300)],
            ),
          ),

          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ResourcesScreen()));
            },
            child: _buildMultiColorCard(
              title: AppLocalizations.of(context).resourceLibrary,
              description: AppLocalizations.of(context).resourceDesc,
              icon: Icons.menu_book_rounded,
              // Gradient: Royal Blue to Sky Blue
              gradientColors: [const Color(0xFF0D47A1), const Color(0xFF42A5F5)],
            ),
          ),

          InkWell(

            borderRadius: BorderRadius.circular(30),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>OrganicSolutionPage()));
            }
            ,
            child: _buildMultiColorCard(
              title: AppLocalizations.of(context).organicSolutions,
              description: AppLocalizations.of(context).organicDesc,
              icon: Icons.eco_rounded,
              // Gradient: Teal to Mint
              gradientColors: [const Color(0xFF004D40), const Color(0xFF26A69A)],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>MarketFeedScreen()));
            },
            child: _buildMultiColorCard(
              title: AppLocalizations.of(context).marketPlace,
              description: AppLocalizations.of(context).marketDesc,
              icon: Icons.menu_book_rounded,
              // Gradient: Royal Blue to Sky Blue
              gradientColors: [const Color(0xFF1A237E), const Color(0xFF2E7D32)],
// Deep Teal to Light Seafoam
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiColorCard({
    required String title,
    String hindiTitle = '',
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 140, // Fixed height for a uniform grid feel
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decorative Circle for visual flair
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Icon Section with Glass effect
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: Colors.white, size: 35),
                ),
                const SizedBox(width: 20),
                // Content Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
