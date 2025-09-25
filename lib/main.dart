import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sports_app/firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sports_app/services/notification_service.dart';
import 'package:sports_app/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service for PWA
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sportify',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDF1A19), // Official Red
          brightness: Brightness.light,
          primary: const Color(0xFFDF1A19),
          secondary: const Color(0xFF002675),
          background: const Color(0xFFF8F9FA),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.copyWith(
            displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            bodyLarge: GoogleFonts.poppins(fontWeight: FontWeight.w400),
            bodyMedium: GoogleFonts.poppins(fontWeight: FontWeight.w400),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.grey.withValues(alpha: 0.1),
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFF1A1A1A),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          shadowColor: Colors.grey.withValues(alpha: 0.15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDF1A19), // Official Red
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFFDF1A19).withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      home: const HomeScreen(),

      debugShowCheckedModeBanner: false,
    );
  }
}