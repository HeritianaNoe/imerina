import 'package:flutter/material.dart';
import '../main.dart';

/// Mampiseho ny dialog "Momba ny appli" (About), miendrika rouge foncé / blanc.
void showMerinaAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: kPaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: const [
            Icon(Icons.account_balance, color: kDarkRed),
            SizedBox(width: 10),
            Text(
              'Quiz Imerina',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['Times New Roman', 'Noto Serif', 'serif'],
                color: kDarkRed,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ity appli ity dia quiz mikasika ny tantara sy ny "
                "kolontsain'ny Fanjakana Merina: ny mpanjaka nifandimby, "
                "ny fombandrazana, ary ny toe-javatra lehibe niainan'ny "
                "Fanjakana Merina.",
                style: TextStyle(fontSize: 14, height: 1.5, color: kInk),
              ),
              SizedBox(height: 16),
              Text(
                'Version: 1.0.0',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              SizedBox(height: 4),
              Text(
                '<> RASOLOMANANA Heritina Noe',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: kDarkRed),
            child: const Text('Hidio'),
          ),
        ],
      );
    },
  );
}
