import 'package:crop_guardian/Authentication/login_screen.dart';
import 'package:crop_guardian/Screens/diagnosis_screen/viewmodels/diagnosis_viewmodel.dart';
import 'package:crop_guardian/core/user/role_controller.dart';
import 'package:crop_guardian/core/accessibility/accessibility_controller.dart';
import 'package:crop_guardian/firebase_options.dart';
import 'package:crop_guardian/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crop_guardian/core/alerts/alert_service.dart';
import 'package:crop_guardian/core/language/language_controller.dart';
import 'package:crop_guardian/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);
  try{
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
    );
    // Load after Firebase - RoleController reads FirebaseAuth.
    // Each is guarded so one failing service cannot block startup.
    try { await LanguageController.instance.load(); } catch (_) {}
    try { await RoleController.instance.load(); } catch (_) {}
    try { await AccessibilityController.instance.load(); } catch (_) {}
    try { AlertService.instance.init(); } catch (_) {}
    runApp(
        ChangeNotifierProvider(
          create: (_) => DiagnosisViewModel(
          ),
          child: const MyApp(),));
  }catch(e){
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text('Could not start Crop Guardian',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? user;
  @override
  void initState() {
    super.initState();
    user=FirebaseAuth.instance.currentUser;
    print(user?.uid.toString());
  }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([LanguageController.instance, AccessibilityController.instance]),
      builder: (context, _) {
        return GetMaterialApp(
          key: ValueKey(LanguageController.instance.locale.languageCode),
          debugShowCheckedModeBanner: false,
          title: 'Crop Guardian',
          locale: LanguageController.instance.locale,
          supportedLocales: LanguageController.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34D399)),
          ),
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: AccessibilityController.instance.textScale,
            maxScaleFactor: AccessibilityController.instance.textScale,
            child: child!,
          ),
          home: user != null ? VibrantFarmerSplash() : LoginScreen(),
        );
      },
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   return GetMaterialApp(
  //     debugShowCheckedModeBanner: false,
  //     title: 'Crop Guardian',
  //     theme: ThemeData(
  //       colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  //     ),
  //     // We wrap the home logic in a LayoutBuilder
  //     home: LayoutBuilder(
  //       builder: (context, constraints) {
  //         // Check if user is logged in
  //         if (user != null) {
  //           // IF LOGGED IN: Check screen width
  //           if (constraints.maxWidth > 800) {
  //             return const WebDashboard(); // Create this for website view
  //           } else {
  //             return const VibrantFarmerSplash(); //  existing mobile splash/home
  //           }
  //         } else {
  //           // IF NOT LOGGED IN: Show login
  //           return const LoginScreen();
  //         }
  //       },
  //     ),
  //   );
  // }
}
