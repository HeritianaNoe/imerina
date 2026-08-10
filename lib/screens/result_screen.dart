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
    return Scaffold(
      backgroundColor: kDarkRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: kWhite,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, size: 60, color: kDarkRed),
              ),
              const SizedBox(height: 24),
              const Text(
                'Vitanao ny Quiz!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$score / $total',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: kWhite,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kWhite,
                    foregroundColor: kDarkRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const QuizScreen()),
                    );
                  },
                  child: const Text(
                    'Averina indray',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kWhite,
                    side: const BorderSide(color: kWhite),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Miverina any am-boalohany',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
