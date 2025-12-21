import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file might not exist in production/web builds
    debugPrint("Note: .env file not found. Relying on --dart-define variables.");
  }
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable offline persistence with 15MB cache for PWA support
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 15 * 1024 * 1024, // 15MB
  );

  // Preload Google Fonts in background (don't block app start)
  GoogleFonts.pendingFonts([
    GoogleFonts.inter(),
  ]).then((_) {
    debugPrint('[Main] Google Fonts loaded');
  }).catchError((e) {
    debugPrint('[Main] Font loading error: $e');
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _listenToThemeChanges();
  }

  void _listenToThemeChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _userSubscription?.cancel();
      if (user != null) {
        _userSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            final mode = data?['themeMode'] as String?;
            print('[Main] Received user update. ThemeMode: $mode');
            
            if (mode != null) {
              setState(() {
                switch (mode) {
                  case 'light':
                    _themeMode = ThemeMode.light;
                    break;
                  case 'dark':
                    _themeMode = ThemeMode.dark;
                    break;
                  default:
                    _themeMode = ThemeMode.system;
                }
              });
            }
          }
        }, onError: (e) => print('[Main] Error listening to user: $e'));
      } else {
        setState(() {
          _themeMode = ThemeMode.system;
        });
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const HomeWithLogin(),
    );
  }
}
