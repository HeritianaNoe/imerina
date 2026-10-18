import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/merina_backdrop.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int total;

  const ResultScreen({super.key, required this.score, required this.total});

  String get _message {
    final ratio = score / total;
    if (ratio == 1.0) return "Mahavaky loha! Tena mahay tantara ianao.";
    if (ratio >= 0.7) return "Tsara be! Mahay ny tantaran'ny Merina ianao.";
    if (ratio >= 0.4) return "Tsara ihany, mbola misy hianarana kely.";
    return "Aza kivy, mianara bebe kokoa momba ny Merina.";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;
    final double ringSize = isSmall ? 170 : 210;
    final double ratio = total == 0 ? 0 : score / total;

    return Scaffold(
      body: MerinaBackdrop(
        topOpacity: 0.78,
        bottomOpacity: 0.95,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width > 500 ? 0 : 28,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Vitanao ny Quiz!',
                      textAlign: TextAlign.center,
                      style: kDisplay(size: isSmall ? 28 : 34),
                    ),
                    SizedBox(height: isSmall ? 24 : 36),
                    // Peratra isa: ny singa afovoany amin'ity efijery ity.
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ratio),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => SizedBox(
                        width: ringSize,
                        height: ringSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: v,
                                strokeWidth: 7,
                                color: kGold,
                                backgroundColor: kWhite.withOpacity(0.14),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$score',
                                  style: kDisplay(
                                      size: isSmall ? 56 : 72, height: 1),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'amin\'ny $total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: kWhite.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 24 : 36),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmall ? 15 : 17,
                        color: kWhite.withOpacity(0.88),
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: isSmall ? 32 : 44),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kWhite,
                          foregroundColor: kDarkRed,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              vertical: isSmall ? 15 : 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const QuizScreen()),
                          );
                        },
                        child: const Text(
                          'Averina indray',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kWhite,
                          side: BorderSide(
                              color: kWhite.withOpacity(0.5), width: 1.2),
                          padding: EdgeInsets.symmetric(
                              vertical: isSmall ? 15 : 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                        child: const Text(
                          'Miverina any am-boalohany',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
