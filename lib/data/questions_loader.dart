import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/question.dart';

/// Mamaky ny fichier JSON ao amin'ny assets ary mamorona lisitry ny Question.
/// Ny angon-drakitra dia hita ao amin'ny: assets/data/questions.json
class QuestionsLoader {
  static Future<List<Question>> loadMerinaQuestions() async {
    final String jsonString =
        await rootBundle.loadString('assets/json/merina.json');
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    final List<dynamic> rawQuestions = jsonData['questions'] as List;

    return rawQuestions
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList();
  }
}
