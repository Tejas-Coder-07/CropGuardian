import 'package:crop_guardian/Authentication/login_screen.dart';
import 'package:crop_guardian/Screens/diagnosis_screen/viewmodels/diagnosis_viewmodel.dart';
import 'package:crop_guardian/firebase_options.dart';
import 'package:crop_guardian/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    runApp(
        ChangeNotifierProvider(
          create: (_) => DiagnosisViewModel(
          ),
          child: const MyApp(),));
  }catch(e){
   SnackBar(content: Text("Firebase initialization error :$e"),);
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
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crop Guardian',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34D399)),
      ),
      home: user !=null ? VibrantFarmerSplash() : LoginScreen(),
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
