import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/about_dialog.dart';
import '../widgets/merina_backdrop.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;
    final int totalQuestions = kTotalStages * kQuestionsPerStage;

    return Scaffold(
      body: MerinaBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 14),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    size.width > 500 ? 0 : 28,
                    4,
                    size.width > 500 ? 0 : 28,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.info_outline),
                          color: kWhite.withOpacity(0.8),
                          tooltip: "Momba ny appli",
                          onPressed: () => showMerinaAboutDialog(context),
                        ),
                      ),
                      const Spacer(flex: 2),
                      const _Emblem(),
                      SizedBox(height: isSmall ? 24 : 36),
                      Text(
                        'Quiz\nImerina',
                        style: kDisplay(
                          size: isSmall ? 52 : 64,
                          height: 1.02,
                          spacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Text(
                          "Fantaro ny tantaran'ny Fanjakana Merina",
                          style: TextStyle(
                            fontSize: isSmall ? 15 : 17,
                            height: 1.45,
                            color: kWhite.withOpacity(0.82),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmall ? 24 : 32),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            _Fact(value: '$kTotalStages', label: 'dingana'),
                            const _FactDivider(),
                            _Fact(
                                value: '$totalQuestions',
                                label: 'fanontaniana'),
                            const _FactDivider(),
                            _Fact(
                                value: '${kQuestionDurationSeconds}s',
                                label: 'isaky ny iray'),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kWhite,
                            foregroundColor: kDarkRed,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                                vertical: isSmall ? 16 : 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuizScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Manomboka ny Quiz',
                            style: TextStyle(
                              fontSize: isSmall ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: kWhite.withOpacity(0.45),
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
      ),
    );
  }
}

/// Emblema: diamondra volamena misy ny sary tranobe ao anatiny.
class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.7853981634,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                border: Border.all(color: kGold, width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.7853981634,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Icon(Icons.account_balance, size: 26, color: kDarkRed),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String value;
  final String label;
  const _Fact({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: kDisplay(size: 24, color: kGold)),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: kWhite.withOpacity(0.7)),
        ),
      ],
    );
  }
}

class _FactDivider extends StatelessWidget {
  const _FactDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        color: kWhite.withOpacity(0.22),
      );
}
