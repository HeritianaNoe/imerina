import 'dart:math' as math;

/// Modely mirakitra ny endrik'ny fanontaniana tsirairay ao amin'ny quiz.
class Question {
  final String questionText;
  final List<String> choices;
  final int correctIndex; // index ao amin'ny "choices" mifanaraka amin'ny valiny marina
  final String explanation; // fanazavana fohy aseho aorian'ny valiny

  const Question({
    required this.questionText,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
  });

  String get correctAnswer => choices[correctIndex];

  /// Mamorona Question iray avy amin'ny Map nalaina tao amin'ny fichier JSON.
  /// Tsy "shuffle" eto intsony: ny [randomized] no mikarakara ny safidy
  /// isaky ny aseho ny fanontaniana.
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionText: json['question'] as String,
      choices: List<String>.from(json['choices'] as List),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
    );
  }

  /// Mamerina Question vaovao misy safidy 3 na 4 (random), ao anatiny foana
  /// ny valiny marina, ary mifangaro ny filaharan'ny safidy.
  Question randomized([math.Random? rng]) {
    final math.Random r = rng ?? math.Random();
    final int wanted = math.min(r.nextBool() ? 3 : 4, choices.length);

    final String correct = choices[correctIndex];
    final List<String> wrong = <String>[
      for (int i = 0; i < choices.length; i++)
        if (i != correctIndex) choices[i],
    ]..shuffle(r);

    final List<String> picked = <String>[
      correct,
      ...wrong.take(wanted - 1),
    ]..shuffle(r);

    return Question(
      questionText: questionText,
      choices: picked,
      correctIndex: picked.indexOf(correct),
      explanation: explanation,
    );
  }
}
