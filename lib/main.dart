import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

/// Loko fototra ampiasaina manerana ny appli: rouge foncé sy blanc.
const Color kDarkRed = Color(0xFF7A0C0C);
const Color kDarkerRed = Color(0xFF4A0404);
const Color kWhite = Colors.white;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android/iOS => landscape (natsangana amin'ny sisiny).
  // Desktop (Windows/macOS/Linux) => portrait.
  // (Tsy misy fiantraikany ny setPreferredOrientations amin'ny web, fa azo antoka
  // ny miantso azy foana.)
  final bool isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  await SystemChrome.setPreferredOrientations(
    isMobile
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  runApp(const MerinaQuizApp());
}

class MerinaQuizApp extends StatelessWidget {
  const MerinaQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Merina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: kWhite,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kDarkRed,
          primary: kDarkRed,
          secondary: kDarkerRed,
          surface: kWhite,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kDarkRed,
          foregroundColor: kWhite,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kDarkRed,
            foregroundColor: kWhite,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: kDarkRed,
          linearTrackColor: Color(0xFFF3D6D6),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
