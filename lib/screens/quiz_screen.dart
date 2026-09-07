import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../data/questions_loader.dart';
import '../main.dart';
import '../models/question.dart';
import '../widgets/about_dialog.dart';
import 'result_screen.dart';

/// Fe-potoana (segondra) omena ny mpampiasa isaky ny fanontaniana.
const int kQuestionDurationSeconds = 60;

/// Isan'ny fanontaniana ao amin'ny dingana tsirairay, sy ny isan'ny dingana.
const int kQuestionsPerStage = 10;
const int kTotalStages = 5;

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<Question>> _questionsFuture;

  int currentIndex = 0;
  int score = 0;
  int? selectedChoice;
  bool answered = false;
  bool? lastAnswerCorrect;

  // Isan'ny "score" tamin'ny fiantombohan'ny dingana ankehitriny;
  // averina amin'io raha tsy mahamarina ny mpampiasa (miverina amin'ny
  // fiantombohan'ny dingana).
  int stageStartScore = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _timer;
  int remainingSeconds = kQuestionDurationSeconds;

  int get currentStage => (currentIndex ~/ kQuestionsPerStage) + 1;
  int get stageStartIndex =>
      (currentIndex ~/ kQuestionsPerStage) * kQuestionsPerStage;
  int get indexWithinStage => currentIndex - stageStartIndex;

  // Filaharan'ny toerana ao anatin'ny dingana ankehitriny (0..9), ahafahana
  // "random" ny filaharan'ny fanontaniana isaky ny miditra na miverina
  // amin'ny dingana iray.
  List<int> _stageOrder = List<int>.generate(kQuestionsPerStage, (i) => i);

  int _questionIndexFor(int stageStart, int withinStage) =>
      stageStart + _stageOrder[withinStage];

  void _enterStage(int stageStart) {
    _stageOrder = List<int>.generate(kQuestionsPerStage, (i) => i)..shuffle();
    setState(() {
      currentIndex = stageStart;
      selectedChoice = null;
      answered = false;
      lastAnswerCorrect = null;
    });
    _startTimer();
  }

  @override
  void initState() {
    super.initState();
    // Mamaky ny fanontaniana avy amin'ny assets/data/questions.json
    _questionsFuture = QuestionsLoader.loadMerinaQuestions();
    _questionsFuture.then((_) => _enterStage(0));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => remainingSeconds = kQuestionDurationSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (remainingSeconds <= 1) {
        timer.cancel();
        setState(() => remainingSeconds = 0);
        _handleTimeUp();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  Future<void> _playSound(bool isCorrect) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource(isCorrect ? 'sounds/correct.wav' : 'sounds/wrong.wav'),
      );
    } catch (_) {
      // Aza avela hijanona ny quiz raha misy olana amin'ny fandefasana feo.
    }
  }

  void _handleTimeUp() {
    if (answered) return; // efa novaliana talohan'ny fahataperan'ny fotoana
    setState(() {
      selectedChoice = null; // tsy nisafidy valiny ny mpampiasa
      answered = true;
      lastAnswerCorrect = false;
    });
    _playSound(false);
  }

  void _selectAnswer(Question currentQuestion, int index) {
    if (answered) return; // sakano ny fisafidianana indroa
    _timer?.cancel();
    final bool isCorrect = index == currentQuestion.correctIndex;
    setState(() {
      selectedChoice = index;
      answered = true;
      lastAnswerCorrect = isCorrect;
      if (isCorrect) {
        score++;
      }
    });
    _playSound(isCorrect);
  }

  void _nextQuestion(List<Question> questions) {
    if (lastAnswerCorrect == false) {
      // Tsy nahamarina -> miverina amin'ny fiantombohan'ny dingana ankehitriny,
      // ka random indray ny filaharan'ny fanontaniana ao anatin'io dingana io.
      setState(() => score = stageStartScore);
      _enterStage(stageStartIndex);
      return;
    }

    if (currentIndex < questions.length - 1) {
      final int nextIndex = currentIndex + 1;
      if (nextIndex % kQuestionsPerStage == 0) {
        // Vao miditra dingana vaovao: io no lasa vodi-marika vaovao
        // hiverenana raha misy diso ao anatin'io dingana io, ary random
        // indray ny filaharan'ny fanontaniana ho an'io dingana vaovao io.
        stageStartScore = score;
        _enterStage(nextIndex);
      } else {
        setState(() {
          currentIndex = nextIndex;
          selectedChoice = null;
          answered = false;
          lastAnswerCorrect = null;
        });
        _startTimer();
      }
    } else {
      _timer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(score: score, total: questions.length),
        ),
      );
    }
  }

  Color _choiceColor(Question currentQuestion, int index) {
    if (!answered) return kWhite;
    if (index == currentQuestion.correctIndex) return const Color(0xFFD7F5DA); // vert malefaka
    if (index == selectedChoice) return const Color(0xFFF9D6D6); // mena malefaka
    return kWhite;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        title: FutureBuilder<List<Question>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                'Fanontaniana ${indexWithinStage + 1}/$kQuestionsPerStage',
              );
            }
            return const Text('Quiz Merina');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Momba ny appli',
            onPressed: () => showMerinaAboutDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kDarkRed),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Nisy olana teo am-pakana ny fanontaniana:\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: kDarkRed),
              ),
            );
          }

          final questions = snapshot.data!;
          final currentQuestion =
              questions[_questionIndexFor(stageStartIndex, indexWithinStage)];
          final progress = (indexWithinStage + 1) / kQuestionsPerStage;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: kDarkRed,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'D$currentStage/$kTotalStages',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kWhite,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedValue, child) {
                            return LinearProgressIndicator(
                              value: animatedValue,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFF3D6D6),
                              valueColor: const AlwaysStoppedAnimation(kDarkRed),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: remainingSeconds <= 10 ? Colors.red : kDarkRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${remainingSeconds}s',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: remainingSeconds <= 10 ? Colors.red : kDarkRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  currentQuestion.questionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kDarkRed,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: currentQuestion.choices.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 90,
                    ),
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () => _selectAnswer(currentQuestion, index),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _choiceColor(currentQuestion, index),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: kDarkRed,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: kWhite,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  currentQuestion.choices[index],
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (answered) ...[
                  if (lastAnswerCorrect == false)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9D6D6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedChoice == null
                            ? 'Tapitra ny fotoana! Hiverina amin\'ny fiantombohan\'ny dingana $currentStage ianao.'
                            : 'Diso! Hiverina amin\'ny fiantombohan\'ny dingana $currentStage ianao.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kDarkRed,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBEAEA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kDarkRed.withOpacity(0.3)),
                    ),
                    child: Text(
                      currentQuestion.explanation,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDarkRed,
                        foregroundColor: kWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => _nextQuestion(questions),
                      child: Text(
                        lastAnswerCorrect == false
                            ? 'Andramo indray ny dingana'
                            : (currentIndex < questions.length - 1
                                ? 'Manaraka'
                                : 'Hijery ny valiny'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
