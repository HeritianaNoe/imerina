import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/questions_loader.dart';
import '../main.dart';
import '../models/question.dart';
import '../widgets/about_dialog.dart';
import '../widgets/merina_backdrop.dart';
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

  static const Color _okColor = Color(0xFF2E7D4F);
  static const Color _okBg = Color(0xFFE8F4EC);
  static const Color _badColor = Color(0xFFB3261E);
  static const Color _badBg = Color(0xFFFCE9E7);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    // Fond mazava: soratra fotsy amin'ny status bar tsy hita, ka atao maizina.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: kPaper,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kPaper,
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
            final double sidePad = size.width > 700 ? 0 : 20;

            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/bg_merina.jpg',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.06),
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(sidePad, 4, sidePad, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 4),
                            _buildProgress(progress),
                            SizedBox(height: isSmall ? 14 : 20),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                switchInCurve: Curves.easeOutCubic,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.04, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                                layoutBuilder: (current, previous) => Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ...previous,
                                    if (current != null) current,
                                  ],
                                ),
                                child: KeyedSubtree(
                                  key: ValueKey(currentQuestion.questionText),
                                  child: _buildBody(currentQuestion, isSmall),
                                ),
                              ),
                            ),
                            if (answered) ...[
                              const SizedBox(height: 12),
                              _buildNextButton(questions, isSmall),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- Header: miverina, dingana, timer, info ----------
  Widget _buildHeader() {
    final bool urgent = remainingSeconds <= 10;
    final Color timerColor = urgent ? _badColor : kDarkRed;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          color: kDarkRed,
          tooltip: 'Miverina',
          onPressed: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dingana $currentStage/$kTotalStages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: List.generate(kTotalStages, (i) {
                  final bool done = i < currentStage - 1;
                  final bool active = i == currentStage - 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: active
                              ? kGold
                              : (done ? kDarkRed : Colors.transparent),
                          border: Border.all(
                            color: (active || done)
                                ? kDarkRed
                                : kDarkRed.withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: remainingSeconds / kQuestionDurationSeconds,
                  strokeWidth: 3,
                  color: timerColor,
                  backgroundColor: kDarkRed.withOpacity(0.10),
                ),
              ),
              Text(
                '$remainingSeconds',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: timerColor,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          color: kDarkRed,
          tooltip: 'Momba ny appli',
          onPressed: () => showMerinaAboutDialog(context),
        ),
      ],
    );
  }

  // ---------- Progression ao anatin'ny dingana ----------
  Widget _buildProgress(double progress) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: kDarkRed.withOpacity(0.10),
                valueColor: const AlwaysStoppedAnimation(kDarkRed),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${indexWithinStage + 1}/$kQuestionsPerStage',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kInk.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // ---------- Fanontaniana + safidy + fanazavana ----------
  Widget _buildBody(Question q, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fanontaniana: ny singa tsy hay hadino amin'ity efijery ity.
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: LambaPatternPainter(
                    color: kGold.withOpacity(0.14),
                    cell: 44,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isSmall ? 18 : 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kDarkRed, kDarkerRed],
                  ),
                ),
                child: Text(
                  q.questionText,
                  style: kDisplay(
                    size: isSmall ? 19 : 22,
                    weight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmall ? 12 : 16),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < q.choices.length; i++) ...[
                  _buildChoice(q, i, isSmall),
                  const SizedBox(height: 10),
                ],
                if (answered) ...[
                  const SizedBox(height: 4),
                  if (lastAnswerCorrect == false) _buildFailBanner(),
                  _buildExplanation(q, isSmall),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoice(Question q, int index, bool isSmall) {
    final bool isCorrect = answered && index == q.correctIndex;
    final bool isWrong = answered && index == selectedChoice && !isCorrect;
    final bool dimmed = answered && !isCorrect && !isWrong;

    final Color border = isCorrect
        ? _okColor
        : isWrong
            ? _badColor
            : kDarkRed.withOpacity(0.14);
    final Color bg = isCorrect
        ? _okBg
        : isWrong
            ? _badBg
            : kWhite;
    final Color badgeFill = isCorrect
        ? _okColor
        : isWrong
            ? _badColor
            : Colors.transparent;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dimmed ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAnswer(q, index),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isSmall ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border,
                width: (isCorrect || isWrong) ? 1.8 : 1.2,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeFill,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isCorrect || isWrong)
                          ? badgeFill
                          : kDarkRed.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: (isCorrect || isWrong)
                      ? Icon(
                          isCorrect ? Icons.check : Icons.close,
                          size: 17,
                          color: kWhite,
                        )
                      : Text(
                          String.fromCharCode(65 + index),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kDarkRed,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    q.choices[index],
                    style: TextStyle(
                      fontSize: isSmall ? 14 : 15,
                      height: 1.35,
                      color: kInk,
                      fontWeight:
                          isCorrect ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFailBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _badBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.replay, size: 18, color: _badColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selectedChoice == null
                  ? 'Tapitra ny fotoana! Hiverina amin\'ny fiantombohan\'ny dingana $currentStage ianao.'
                  : 'Diso! Hiverina amin\'ny fiantombohan\'ny dingana $currentStage ianao.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _badColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation(Question q, bool isSmall) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDarkRed.withOpacity(0.10)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: kGold,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  q.explanation,
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 14,
                    color: kInk.withOpacity(0.85),
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(List<Question> questions, bool isSmall) {
    final bool retry = lastAnswerCorrect == false;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkRed,
          foregroundColor: kWhite,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: isSmall ? 14 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _nextQuestion(questions),
        child: Text(
          retry
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
    );
  }
}
