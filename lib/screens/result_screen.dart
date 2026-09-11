import 'package:flutter/material.dart';
import '../main.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int total;

  const ResultScreen({super.key, required this.score, required this.total});

  String get _message {
    final ratio = score / total;
    if (ratio == 1.0) return "Mahavaky loha! Tena mahay tantara ianao 🎉";
    if (ratio >= 0.7) return "Tsara be! Mahay ny tantaran'ny Merina ianao 👏";
    if (ratio >= 0.4) return "Tsara ihany, mbola misy hianarana kely 📚";
    return "Aza kivy, mianara bebe kokoa momba ny Merina 💪";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond image
          Image.asset(
            'assets/images/bg_merina.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [kDarkRed, kDarkerRed],
                  ),
                ),
              );
            },
          ),
          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kDarkRed.withOpacity(0.75),
                  kDarkerRed.withOpacity(0.92),
                ],
              ),
            ),
          ),
          // Contenu
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width > 500 ? 40.0 : 24.0,
                vertical: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmall ? 16 : 22),
                    decoration: BoxDecoration(
                      color: kWhite,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: isSmall ? 48 : 64,
                      color: kDarkRed,
                    ),
                  ),
                  SizedBox(height: isSmall ? 20 : 28),
                  Text(
                    'Vitanao ny Quiz!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmall ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: kWhite,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$score / $total',
                    style: TextStyle(
                      fontSize: isSmall ? 42 : 52,
                      fontWeight: FontWeight.bold,
                      color: kWhite,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmall ? 14 : 16,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: isSmall ? 32 : 44),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kWhite,
                        foregroundColor: kDarkRed,
                        elevation: 4,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmall ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QuizScreen()),
                        );
                      },
                      child: Text(
                        'Averina indray',
                        style: TextStyle(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kWhite,
                        side: const BorderSide(color: kWhite, width: 1.5),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmall ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Miverina any am-boalohany',
                        style: TextStyle(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
