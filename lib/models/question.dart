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
  /// Ny safidy ("choices") dia atao "shuffle" eto mba tsy ho voalohany
  /// mandrakariva ny valiny marina rehefa aseho amin'ny mpampiasa.
  factory Question.fromJson(Map<String, dynamic> json) {
    final List<String> originalChoices =
        List<String>.from(json['choices'] as List);
    final int originalCorrectIndex = json['correctIndex'] as int;
    final String correctText = originalChoices[originalCorrectIndex];

    final List<String> shuffledChoices = List<String>.from(originalChoices)
      ..shuffle();
    final int newCorrectIndex = shuffledChoices.indexOf(correctText);

    return Question(
      questionText: json['question'] as String,
      choices: shuffledChoices,
      correctIndex: newCorrectIndex,
      explanation: json['explanation'] as String,
    );
  }
}
