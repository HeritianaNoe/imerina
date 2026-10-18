import 'package:flutter/material.dart';
import '../main.dart';

/// Fond iombonana: sary (raha misy), gradient mena maizina ary kilalao
/// diamondra malefaka mitovy amin'ny lamba akotofahana.
class MerinaBackdrop extends StatelessWidget {
  final Widget child;
  final double topOpacity;
  final double bottomOpacity;

  const MerinaBackdrop({
    super.key,
    required this.child,
    this.topOpacity = 0.72,
    this.bottomOpacity = 0.94,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fototra mena maizina: miseho raha tsy misy ny sary.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kDarkRed, kDarkerRed],
            ),
          ),
        ),
        Image.asset(
          'assets/images/bg_merina.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.expand(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                kDarkRed.withOpacity(topOpacity),
                kDarkerRed.withOpacity(bottomOpacity),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: LambaPatternPainter(color: kGold.withOpacity(0.10)),
          ),
        ),
        child,
      ],
    );
  }
}

/// Kilalao diamondra tsotra, misy diamondra kely ao anatin'ny iray isaky ny
/// roa, mba hanome fahatsapana lamba tenona tsy mitaky sary.
class LambaPatternPainter extends CustomPainter {
  final Color color;
  final double cell;

  const LambaPatternPainter({required this.color, this.cell = 56});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final double half = cell * 0.34;
    int row = 0;
    for (double y = 0; y < size.height + cell; y += cell, row++) {
      int col = 0;
      for (double x = 0; x < size.width + cell; x += cell, col++) {
        final c = Offset(x + cell / 2, y + cell / 2);
        canvas.drawPath(_diamond(c, half), paint);
        if ((row + col) % 2 == 0) {
          canvas.drawPath(_diamond(c, half * 0.45), paint);
        }
      }
    }
  }

  Path _diamond(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r, c.dy)
    ..close();

  @override
  bool shouldRepaint(covariant LambaPatternPainter old) =>
      old.color != color || old.cell != cell;
}
