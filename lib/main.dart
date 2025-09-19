import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sports_app/firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sports_app/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wafy Sports',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F8),
        primaryColor: const Color(0xFFE81C61),
        textTheme: GoogleFonts.manropeTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F8),
          elevation: 0,
          surfaceTintColor: Color(0xFFF5F5F8),
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
              color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        // The problematic cardTheme property has been removed.
        // Styling is now handled by CustomCard widget.
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}