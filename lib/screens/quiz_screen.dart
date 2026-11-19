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

  // Dingana aorian'ny fanapahan-kevitra: 1) aseho ny valiny (maitso/mena),
  // 2) mivoaka mihilifilika ny safidy diso rehetra (eliminating),
  // 3) vao miditra ny valiny feno + ny bokotra manaraka (revealed).
  bool eliminating = false;
  bool revealed = false;

  // Pejy "miverina any am-piandohana" aseho aorian'ny diso, alohan'ny hanombohana
  // indray ny dingana.
  bool _showRetry = false;

  // Pejy fampahafantarana ny dingana manaraka: miseho kely rehefa vita ny
  // dingana iray, ary mandeha irery (tsy misy bokotra).
  bool _showStageIntro = false;
  int _pendingStageStart = 0;

  // Isan'ny dingana araka ny angon-drakitra (fa tsy ny constant fotsiny),
  // mba tsy hianjera raha latsaky ny 50 ny fanontaniana ao amin'ny JSON.
  int _totalStages = kTotalStages;

  Timer? _revealTimer;
  static const Duration _highlightDelay = Duration(milliseconds: 650);
  static const Duration _eliminateDuration = Duration(milliseconds: 600);

  // Fanontaniana aseho amin'ny dingana ankehitriny, miaraka amin'ny safidy
  // 3 na 4 (random) vaovao isaky ny miditra/miverina amin'ny dingana.
  List<Question> _stageQuestions = const [];

  // Ampitomboina isaky ny fanontaniana aseho, mba hisy animation foana
  // na dia mitovy aza ny fanontaniana tamin'ny fanandramana teo aloha.
  int _qSerial = 0;

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

  void _enterStage(List<Question> all, int stageStart) {
    final int stageSize = math.min(kQuestionsPerStage, all.length - stageStart);
    _totalStages = (all.length + kQuestionsPerStage - 1) ~/ kQuestionsPerStage;
    _stageOrder = List<int>.generate(stageSize, (i) => i)..shuffle();
    _stageQuestions = List<Question>.generate(
      stageSize,
      (i) => all[_questionIndexFor(stageStart, i)].randomized(),
    );
    _revealTimer?.cancel();
    setState(() {
      currentIndex = stageStart;
      selectedChoice = null;
      answered = false;
      eliminating = false;
      revealed = false;
      _showRetry = false;
      _showStageIntro = false;
      lastAnswerCorrect = null;
      _qSerial++;
    });
    _startTimer();
  }

  /// Fandaharana ny fiovan'ny efijery aorian'ny valiny.
  void _beginReveal() {
    _revealTimer?.cancel();
    _revealTimer = Timer(_highlightDelay, () {
      if (!mounted) return;
      setState(() => eliminating = true);
      _revealTimer = Timer(_eliminateDuration, () {
        if (!mounted) return;
        setState(() => revealed = true);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // Mamaky ny fanontaniana avy amin'ny assets/data/questions.json
    _questionsFuture = QuestionsLoader.loadMerinaQuestions();
    _questionsFuture.then(
      (all) {
        if (mounted && all.isNotEmpty) _enterStage(all, 0);
      },
      // Aseho ao amin'ny FutureBuilder ny hadisoana; aza avela tsy voaraikitra.
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _revealTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  DateTime? _deadline;

  void _startTimer() {
    _timer?.cancel();
    _deadline = DateTime.now().add(
      const Duration(seconds: kQuestionDurationSeconds),
    );
    setState(() => remainingSeconds = kQuestionDurationSeconds);
    // Mampiasa "deadline" fa tsy mihena 1 isaky ny tick: mitazona ny fotoana
    // marina na dia nijanona kely aza ny appli (background) na nitaredretra ny tick.
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted) return;
      final int left =
          (_deadline!.difference(DateTime.now()).inMilliseconds / 1000).ceil();
      if (left <= 0) {
        timer.cancel();
        setState(() => remainingSeconds = 0);
        _handleTimeUp();
      } else if (left != remainingSeconds) {
        setState(() => remainingSeconds = left);
      }
    });
  }

  /// Mandefa feo iray avy ao amin'ny assets (ohatra 'sounds/retry.wav').
  Future<void> _playAsset(String assetPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // Aza avela hijanona ny quiz raha misy olana amin'ny fandefasana feo.
    }
  }

  Future<void> _playSound(bool isCorrect) =>
      _playAsset(isCorrect ? 'sounds/correct.wav' : 'sounds/wrong.wav');

  void _handleTimeUp() {
    if (answered) return; // efa novaliana talohan'ny fahataperan'ny fotoana
    setState(() {
      selectedChoice = null; // tsy nisafidy valiny ny mpampiasa
      answered = true;
      lastAnswerCorrect = false;
    });
    _playSound(false);
    _beginReveal();
  }

  void _selectAnswer(Question currentQuestion, int index) {
    if (answered) return; // sakano ny fisafidianana indroa
    // Sakano ny tap amin'ny card taloha mbola mivoaka (animation) fa efa
    // fanontaniana vaovao no ankehitriny.
    if (_stageQuestions.isEmpty ||
        !identical(currentQuestion, _stageQuestions[indexWithinStage])) {
      return;
    }
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
    _beginReveal();
  }

  void _restartStage(List<Question> questions) {
    if (!_showRetry) return; // sakano ny tap indroa
    _enterStage(questions, stageStartIndex);
  }

  void _nextQuestion(List<Question> questions) {
    // Sakano ny tap indroa (na tap alohan'ny hiseho ny valiny) izay
    // handingana fanontaniana.
    if (!answered || !revealed || _showRetry || _showStageIntro) return;

    if (lastAnswerCorrect == false) {
      // Tsy nahamarina -> aseho aloha ny pejy "miverina any am-piandohana";
      // rehefa tsindrina ny "Manomboka" vao hiditra indray ny dingana
      // (random indray ny filaharan'ny fanontaniana sy ny safidy).
      _revealTimer?.cancel();
      setState(() {
        score = stageStartScore;
        _showRetry = true;
      });
      _playAsset('sounds/retry.wav'); // feo rehefa miseho ny pejy "miverina"
      return;
    }

    if (currentIndex < questions.length - 1) {
      final int nextIndex = currentIndex + 1;
      if (nextIndex % kQuestionsPerStage == 0) {
        // Vao miditra dingana vaovao: io no lasa vodi-marika vaovao
        // hiverenana raha misy diso ao anatin'io dingana io, ary random
        // indray ny filaharan'ny fanontaniana ho an'io dingana vaovao io.
        stageStartScore = score;
        _revealTimer?.cancel();
        setState(() {
          _pendingStageStart = nextIndex;
          _showStageIntro = true;
        });
        _playAsset('sounds/stage_complete.wav'); // feo: vita ny dingana
      } else {
        _revealTimer?.cancel();
        setState(() {
          currentIndex = nextIndex;
          selectedChoice = null;
          answered = false;
          eliminating = false;
          revealed = false;
          lastAnswerCorrect = null;
          _qSerial++;
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
            if (_stageQuestions.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: kDarkRed),
              );
            }
            final currentQuestion = _stageQuestions[indexWithinStage];
            final progress = (indexWithinStage + 1) / _stageQuestions.length;
            final double sidePad = size.width > 700 ? 0 : 20;

            final Widget quizView = KeyedSubtree(
              key: const ValueKey('quiz-view'),
              child: Stack(
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
                        padding: EdgeInsets.fromLTRB(sidePad, 8, sidePad, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card tokana: miverina, dingana, timer, info ary
                            // progression rehetra eo ambonin'ny fanontaniana.
                            Container(
                              padding:
                                  const EdgeInsets.fromLTRB(6, 6, 6, 14),
                              decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: kDarkRed.withValues(alpha: 0.10),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kDarkRed.withValues(alpha: 0.06),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeader(),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: _buildProgress(progress),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmall ? 12 : 16),
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
                                  key: ValueKey(_qSerial),
                                  child: _buildBody(currentQuestion, questions, isSmall),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            );

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 480),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (current != null) current],
              ),
              child: _showRetry
                  ? _RetryStageView(
                      key: ValueKey('retry-$_qSerial'),
                      stage: currentStage,
                      totalStages: _totalStages,
                      onStart: () => _restartStage(questions),
                    )
                  : _showStageIntro
                      ? _StageIntroView(
                          key: ValueKey('intro-$_pendingStageStart'),
                          completedStage: currentStage,
                          nextStage: currentStage + 1,
                          totalStages: _totalStages,
                          score: score,
                          onDone: () {
                            if (mounted && _showStageIntro) {
                              _enterStage(questions, _pendingStageStart);
                            }
                          },
                        )
                      : quizView,
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
                'Dingana $currentStage/$_totalStages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: List.generate(_totalStages, (i) {
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
                                : kDarkRed.withValues(alpha: 0.3),
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
                  backgroundColor: kDarkRed.withValues(alpha: 0.10),
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
                backgroundColor: kDarkRed.withValues(alpha: 0.10),
                valueColor: const AlwaysStoppedAnimation(kDarkRed),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${indexWithinStage + 1}/${_stageQuestions.length}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kInk.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // ---------- Fanontaniana + safidy + fanazavana ----------
  Widget _buildBody(Question q, List<Question> questions, bool isSmall) {
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
                    color: kGold.withValues(alpha: 0.14),
                    cell: 44,
                  ),
                ),
              ),
              // width: double.infinity -> tsy tapaka intsony ny card rehefa
              // fohy ny fanontaniana (ny Stack dia manome constraints "loose"
              // ho an'ny zanany tsy Positioned, ka nihena ny Container).
              Container(
                width: double.infinity,
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
                for (int i = 0; i < q.choices.length; i++)
                  _EliminableTile(
                    // Ny safidy diso rehetra no esorina (ny marina ihany no
                    // mijanona); mivoaka havia/havanana mifandimby izy ireo.
                    eliminated: eliminating && i != q.correctIndex,
                    direction: i.isEven ? -1 : 1,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildChoice(q, i, isSmall),
                    ),
                  ),
                if (revealed)
                  _SlideUpFadeIn(
                    key: ValueKey('result-$_qSerial'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (lastAnswerCorrect == false) _buildFailBanner(),
                          _buildExplanation(q, isSmall),
                        ],
                      ),
                    ),
                  ),
                // Bokotra: miakatra manaraka ny valiny (tsy mijanona any
                // ambany), kely, ary miseho kelikely aorian'ny valiny.
                if (revealed)
                  _SlideUpFadeIn(
                    key: ValueKey('next-$_qSerial'),
                    delayMs: 160,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _buildNextButton(questions, isSmall),
                      ),
                    ),
                  ),
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

    final Color border = isCorrect
        ? _okColor
        : isWrong
            ? _badColor
            : kDarkRed.withValues(alpha: 0.14);
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

    return Material(
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
                        : kDarkRed.withValues(alpha: 0.35),
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
        border: Border.all(color: kDarkRed.withValues(alpha: 0.10)),
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
                    color: kInk.withValues(alpha: 0.85),
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
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkRed,
          foregroundColor: kWhite,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: EdgeInsets.symmetric(
            horizontal: 22,
            vertical: isSmall ? 10 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _nextQuestion(questions),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (retry) ...[
              const Icon(Icons.replay_rounded, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              retry
                  ? 'Andramo indray ny dingana'
                  : (currentIndex < questions.length - 1
                      ? 'Manaraka'
                      : 'Hijery ny valiny'),
              style: TextStyle(
                fontSize: isSmall ? 14 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
    );
  }
}

/// Safidy iray izay mivoaka mihilifilika (havia/havanana) miaraka amin'ny
/// fahaverezan'ny hatsaran-tarehy, avy eo mikorontana ny haavony mba hisarihan'ny
/// safidy sisa miakatra tsara tarehy.
class _EliminableTile extends StatefulWidget {
  const _EliminableTile({
    required this.eliminated,
    required this.direction,
    required this.child,
  });

  final bool eliminated;

  /// -1 = mivoaka mankany havia, 1 = mankany havanana.
  final int direction;
  final Widget child;

  @override
  State<_EliminableTile> createState() => _EliminableTileState();
}

class _EliminableTileState extends State<_EliminableTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final Animation<double> _slide = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.65, curve: Curves.easeInCubic),
  );
  late final Animation<double> _collapse = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 1.0, curve: Curves.easeInOutCubic),
  );

  @override
  void initState() {
    super.initState();
    if (widget.eliminated) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant _EliminableTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eliminated && !oldWidget.eliminated) {
      _controller.forward();
    } else if (!widget.eliminated && oldWidget.eliminated) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: ReverseAnimation(_collapse),
      axisAlignment: -1,
      child: FadeTransition(
        opacity: ReverseAnimation(_slide),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: Offset(1.15 * widget.direction, 0),
          ).animate(_slide),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Miditra mihilifilika miakatra avy ambany miaraka amin'ny fade.
class _SlideUpFadeIn extends StatelessWidget {
  const _SlideUpFadeIn({super.key, required this.child, this.delayMs = 0});

  final Widget child;

  /// Fiandrasana (ms) alohan'ny hanombohan'ny animation.
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final int total = 420 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 28),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Pejy aseho rehefa diso ny mpampiasa: milaza fa miverina any am-piandohan'ny
/// dingana, miaraka amin'ny icon mihodina miverina (rewind) sy bokotra "Manomboka".
class _RetryStageView extends StatefulWidget {
  const _RetryStageView({
    super.key,
    required this.stage,
    required this.totalStages,
    required this.onStart,
  });

  final int stage;
  final int totalStages;
  final VoidCallback onStart;

  @override
  State<_RetryStageView> createState() => _RetryStageViewState();
}

class _RetryStageViewState extends State<_RetryStageView>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  // Peratra mitempo mitroka manodidina ny icon, miverimberina.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  Animation<double> _interval(double a, double b, Curve c) =>
      CurvedAnimation(parent: _entry, curve: Interval(a, b, curve: c));

  @override
  void dispose() {
    _entry.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Widget _slideFade(Animation<double> anim, double dy, Widget child) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, dy), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconAnim = _interval(0.0, 0.55, Curves.elasticOut);
    final spinAnim = _interval(0.0, 0.6, Curves.easeOutCubic);
    final titleAnim = _interval(0.35, 0.7, Curves.easeOutCubic);
    final textAnim = _interval(0.45, 0.8, Curves.easeOutCubic);
    final buttonAnim = _interval(0.65, 1.0, Curves.easeOutCubic);

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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- Icon: peratra mitempo + kitapo mihodina miverina ----
                    SizedBox(
                      height: 170,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, _) {
                                final double t = _pulse.value;
                                return Container(
                                  width: 96 + 64 * t,
                                  height: 96 + 64 * t,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: kDarkRed
                                          .withValues(alpha: 0.28 * (1 - t)),
                                      width: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ScaleTransition(
                              scale: iconAnim,
                              child: AnimatedBuilder(
                                animation: spinAnim,
                                builder: (context, child) =>
                                    Transform.rotate(
                                  // mihodina iray manontolo mivadika (rewind)
                                  angle: -2 * math.pi * spinAnim.value,
                                  child: child,
                                ),
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [kDarkRed, kDarkerRed],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    size: 52,
                                    color: kGold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _slideFade(
                      titleAnim,
                      0.25,
                      Text(
                        'Miverina any am-piandohana',
                        textAlign: TextAlign.center,
                        style: kDisplay(
                          size: 26,
                          color: kDarkRed,
                          weight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _slideFade(
                      textAnim,
                      0.25,
                      Text(
                        'Diso ny valinao, ka hiverina amin\'ny fanontaniana '
                        'voalohany amin\'ny dingana ${widget.stage}/${widget.totalStages} '
                        'ianao. Mivadika ny filaharan\'ny fanontaniana sy ny safidy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.45,
                          color: kInk.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _slideFade(
                      buttonAnim,
                      0.6,
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkRed,
                          foregroundColor: kWhite,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: widget.onStart,
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: const Text(
                          'Manomboka',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pejy fohy aseho rehefa vita ny dingana iray: manambara ny dingana manaraka
/// ary mandeha irery (tsy misy bokotra) rehefa feno ny tsipika ambany.
class _StageIntroView extends StatefulWidget {
  const _StageIntroView({
    super.key,
    required this.completedStage,
    required this.nextStage,
    required this.totalStages,
    required this.score,
    required this.onDone,
  });

  final int completedStage;
  final int nextStage;
  final int totalStages;
  final int score;
  final VoidCallback onDone;

  @override
  State<_StageIntroView> createState() => _StageIntroViewState();
}

class _StageIntroViewState extends State<_StageIntroView>
    with SingleTickerProviderStateMixin {
  static const Duration _total = Duration(milliseconds: 2800);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _total,
  );

  Animation<double> _iv(double a, double b, Curve curve) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) widget.onDone();
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _slideFade(Animation<double> a, double dy, Widget child) {
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position:
            Tween<Offset>(begin: Offset(0, dy), end: Offset.zero).animate(a),
        child: child,
      ),
    );
  }

  Widget _diamond(int i, Animation<double> pulse) {
    final bool done = i < widget.completedStage;
    final bool next = i == widget.nextStage - 1;
    Widget d = Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: next ? kGold : (done ? kDarkRed : Colors.transparent),
          border: Border.all(
            color: (done || next) ? kDarkRed : kDarkRed.withValues(alpha: 0.3),
            width: 1.3,
          ),
        ),
      ),
    );
    if (next) d = ScaleTransition(scale: pulse, child: d);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: d,
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = _iv(0.0, 0.2, Curves.elasticOut);
    final doneText = _iv(0.08, 0.28, Curves.easeOutCubic);
    final dots = _iv(0.22, 0.42, Curves.easeOutCubic);
    final pulse = Tween<double>(begin: 0.6, end: 1.35)
        .animate(_iv(0.4, 0.62, Curves.elasticOut));
    final title = _iv(0.4, 0.62, Curves.easeOutCubic);
    final sub = _iv(0.52, 0.74, Curves.easeOutCubic);

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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: badge,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2E7D4F),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 42,
                          color: kWhite,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _slideFade(
                      doneText,
                      0.3,
                      Text(
                        'Dingana ${widget.completedStage} vita!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kInk.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeTransition(
                      opacity: dots,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < widget.totalStages; i++)
                            _diamond(i, pulse),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    _slideFade(
                      title,
                      0.3,
                      Text(
                        'Dingana ${widget.nextStage}',
                        textAlign: TextAlign.center,
                        style: kDisplay(
                          size: 42,
                          color: kDarkRed,
                          weight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _slideFade(
                      sub,
                      0.3,
                      Text(
                        'Isa ankehitriny: ${widget.score} \u2022 Vonona ve?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: kInk.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Tsipika mameno mandritra ny fotoana: manondro fa
                    // mandeha irery ny dingana manaraka.
                    AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _c.value,
                          minHeight: 4,
                          backgroundColor: kDarkRed.withValues(alpha: 0.10),
                          valueColor: const AlwaysStoppedAnimation(kDarkRed),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
