import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';

/// Loko fototra ampiasaina manerana ny appli: rouge foncé sy blanc.
const Color kDarkRed = Color(0xFF7A0C0C);
const Color kDarkerRed = Color(0xFF4A0404);
const Color kWhite = Colors.white;

/// Loko fanampiny: taratasy mafana, volamena malefaka (fihaingoana royal),
/// ary ink fotsy-mena ho an'ny soratra.
const Color kPaper = Color(0xFFFAF6F3);
const Color kGold = Color(0xFFD8B26A);
const Color kInk = Color(0xFF2B1011);

/// Style serif ho an'ny lohateny sy ny fanontaniana. Tsy mila package fanampiny:
/// mampiasa serif misy amin'ny rafitra tsirairay.
TextStyle kDisplay({
  required double size,
  Color color = kWhite,
  FontWeight weight = FontWeight.w700,
  double height = 1.12,
  double spacing = 0,
}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'Noto Serif', 'serif'],
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mobile (Android/iOS) => portrait (mety kokoa amin'ny telefaonina).
  // Desktop (Windows/macOS/Linux) => portrait.
  final bool isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  await SystemChrome.setPreferredOrientations(
    isMobile
        ? [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]
        : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  // Status bar maivana mba hifanaraka amin'ny fond maizina.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: kDarkerRed,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final bool isDesktop = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  if (isDesktop) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(900, 680), 
      minimumSize: Size(900, 680),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Imerina',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

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
        scaffoldBackgroundColor: kPaper,
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
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kDarkRed,
            foregroundColor: kWhite,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        }),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: kDarkRed,
          linearTrackColor: Color(0xFFF3D6D6),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
