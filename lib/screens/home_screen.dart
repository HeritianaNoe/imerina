import 'package:flutter/material.dart';
import '../main.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== FOND IMAGE =====
          // Apetraho ny sary ao amin'ny: assets/images/bg_merina.jpg
          // Raha tsy misy dia mampiasa gradient mena maizina.
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
          // Overlay maizina mba hahazoana hamaky tsara ny soratra
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kDarkRed.withOpacity(0.70),
                  kDarkerRed.withOpacity(0.88),
                ],
              ),
            ),
          ),
          // Contenu
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width > 500 ? 48.0 : 24.0,
                vertical: 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
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
                      Icons.account_balance,
                      size: isSmall ? 48 : 64,
                      color: kDarkRed,
                    ),
                  ),
                  SizedBox(height: isSmall ? 20 : 28),
                  // Titre
                  Text(
                    'Quiz Imerina',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmall ? 28 : 36,
                      fontWeight: FontWeight.bold,
                      color: kWhite,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    "Fantaro ny tantaran'ny Fanjakana Merina",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmall ? 14 : 16,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: isSmall ? 36 : 52),
                  // Bouton Manomboka
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kWhite,
                        foregroundColor: kDarkRed,
                        elevation: 4,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmall ? 14 : 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
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
