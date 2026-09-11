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
    if (index == currentQuestion.correctIndex) {
      return const Color(0xFFD7F5DA); // vert malefaka
    }
    if (index == selectedChoice) return const Color(0xFFF9D6D6); // mena malefaka
    return kWhite;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        title: FutureBuilder<List<Question>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                'Fanontaniana ${indexWithinStage + 1}/$kQuestionsPerStage',
                style: TextStyle(fontSize: isSmall ? 16 : 18),
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Nisy olana teo am-pakana ny fanontaniana:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kDarkRed),
                ),
              ),
            );
          }

          final questions = snapshot.data!;
          final currentQuestion =
              questions[_questionIndexFor(stageStartIndex, indexWithinStage)];
          final progress = (indexWithinStage + 1) / kQuestionsPerStage;

          return Stack(
            children: [
              // Fond image maivana (optional)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg_merina.jpg',
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.08),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              // Contenu principal
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    size.width > 500 ? 32 : 16,
                    12,
                    size.width > 500 ? 32 : 16,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress + Stage + Timer
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kDarkRed,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'D$currentStage/$kTotalStages',
                              style: const TextStyle(
                                fontSize: 12,
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
                                    valueColor: const AlwaysStoppedAnimation(
                                        kDarkRed),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: remainingSeconds <= 10
                                ? Colors.red
                                : kDarkRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${remainingSeconds}s',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: remainingSeconds <= 10
                                  ? Colors.red
                                  : kDarkRed,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmall ? 12 : 16),
                      // Fanontaniana
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kWhite,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          currentQuestion.questionText,
                          style: TextStyle(
                            fontSize: isSmall ? 15 : 16,
                            fontWeight: FontWeight.bold,
                            color: kDarkRed,
                            height: 1.35,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmall ? 12 : 16),
                      // Safidy (choices)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Raha kely dia 1 column, raha lehibe dia 2
                            final crossAxisCount =
                                constraints.maxWidth > 400 ? 2 : 1;
                            final itemHeight = crossAxisCount == 1 ? 72.0 : 88.0;

                            return GridView.builder(
                              itemCount: currentQuestion.choices.length,
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                mainAxisExtent: itemHeight,
                              ),
                              itemBuilder: (context, index) {
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () =>
                                        _selectAnswer(currentQuestion, index),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _choiceColor(
                                            currentQuestion, index),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: answered &&
                                                  index ==
                                                      currentQuestion
                                                          .correctIndex
                                              ? Colors.green.shade400
                                              : answered &&
                                                      index == selectedChoice
                                                  ? Colors.red.shade300
                                                  : Colors.grey.shade200,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.06),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                              color: kDarkRed,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              String.fromCharCode(65 + index),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: kWhite,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              currentQuestion.choices[index],
                                              style: TextStyle(
                                                fontSize: isSmall ? 13 : 14,
                                                color: Colors.black87,
                                                height: 1.25,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // Feedback + Bouton manaraka
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
                            border: Border.all(
                                color: kDarkRed.withOpacity(0.3)),
                          ),
                          child: Text(
                            currentQuestion.explanation,
                            style: TextStyle(
                              fontSize: isSmall ? 13 : 14,
                              color: Colors.black87,
                              height: 1.35,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kDarkRed,
                              foregroundColor: kWhite,
                              elevation: 3,
                              padding: EdgeInsets.symmetric(
                                  vertical: isSmall ? 12 : 14),
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
                              style: TextStyle(
                                fontSize: isSmall ? 15 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
