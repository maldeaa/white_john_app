import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:white_john_app/screens/main_menu.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BlackjackApp());
}

class BlackjackApp extends StatelessWidget {
  const BlackjackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Colors.black,
          secondary: Colors.grey,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, fontFamily: 'SF Pro'),
          headlineSmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF Pro',
              color: Colors.white),
        ),
      ),
      home: MainMenu(),
    );
  }
}
