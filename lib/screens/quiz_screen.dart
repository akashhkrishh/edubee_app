import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:edubee_app/screens/question_screen.dart';
import 'package:edubee_app/services/question_service.dart';
import 'package:edubee_app/data/models/question_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuestionService _questionService = QuestionService();
  bool _isLoading = false;
  bool _hasPausedQuiz = false;
  List<Question>? _pausedQuestions;
  int _pausedIndex = 0;
  int _pausedScore = 0;
  int _pausedTimeRemaining = 45;
  int _originalTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadPausedState();
  }

  Future<void> _loadPausedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('is_paused') && prefs.getBool('is_paused') == true) {
      final jsonStr = prefs.getString('paused_questions_json');
      if (jsonStr != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(jsonStr);
          final questions = jsonList.map<Question>(
                  (json) => Question.fromJson(json as Map<String, dynamic>)
          ).toList();
          setState(() {
            _hasPausedQuiz = true;
            _pausedQuestions = questions;
            _pausedIndex = prefs.getInt('current_index') ?? 0;
            _pausedScore = prefs.getInt('score') ?? 0;
            _pausedTimeRemaining = prefs.getInt('paused_time') ?? 45;
            _originalTotal = prefs.getInt('original_total') ?? questions.length;
          });
        } catch (e) {
          await _clearPausedState(prefs);
        }
      }
    }
  }

  Future<void> _clearPausedState([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    await prefs.setBool('is_paused', false);
    await prefs.remove('paused_questions_json');
    await prefs.remove('current_index');
    await prefs.remove('score');
    await prefs.remove('paused_time');
    await prefs.remove('original_total');
    if (mounted) {
      setState(() {
        _hasPausedQuiz = false;
        _pausedQuestions = null;
        _originalTotal = 0;
      });
    }
  }

  Future<void> _showResumeDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = Theme.of(context);
    final total = _originalTotal > 0 ? _originalTotal : (_pausedQuestions?.length ?? 50);
    final answered = _pausedIndex;
    final remaining = total - answered;
    final progressPercentage = (answered / total * 100).round();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paused Quiz Found',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              // Flexible(
              //   child: SizedBox(
              //     width: 70,
              //     height: 70,
              //     child: Stack(
              //       alignment: Alignment.center,
              //       children: [
              //         CircularProgressIndicator(
              //           value: answered / total,
              //           strokeWidth: 6,
              //           backgroundColor: Colors.grey.shade200,
              //           valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              //         ),
              //         Text(
              //           '$progressPercentage%',
              //           style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Total Questions: $total', style: const TextStyle(fontSize: 16, color: Colors.grey,)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('$answered', style: theme.textTheme.headlineSmall),
                                    const Text('Answered', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('$remaining', style: theme.textTheme.headlineSmall),
                                    const Text('Remaining', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('$_pausedScore', style: theme.textTheme.headlineSmall),
                                    const Text('Correct', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              const Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Time remaining: $_pausedTimeRemaining s',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'You have a quiz in progress. Would you like to continue where you left off or start a fresh quiz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                // Resume Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _resumeQuiz();
                    },
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text(
                      'Resume Quiz',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _clearPausedState(prefs);
                      _startNewQuiz();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Start New Quiz'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearPausedState(prefs);

              },
              child: const Text(
                  'Clear Quiz', style: TextStyle(fontSize: 16, color: Colors.red)
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );

      },
    );
  }

  Future<void> _startQuiz() async {
    if (_hasPausedQuiz) {
      await _showResumeDialog();
    } else {
      await _startNewQuiz();
    }
  }

  Future<void> _startNewQuiz() async {
    setState(() => _isLoading = true);
    try {
      final allQuestions = await _questionService.loadQuestions();
      // allQuestions.shuffle();
      final quizQuestions = allQuestions.take(50).toList();
      final total = quizQuestions.length;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionScreen(
              questions: quizQuestions,
              isQuizMode: true,
              originalTotal: total,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resumeQuiz() async {
    if (_pausedQuestions == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreen(
          questions: _pausedQuestions!,
          isQuizMode: true,
          currentIndex: _pausedIndex,
          score: _pausedScore,
          pausedTimeRemaining: _pausedTimeRemaining,
          originalTotal: _originalTotal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String buttonText = _hasPausedQuiz ? 'Resume Quiz' : 'Start Quiz';
    IconData buttonIcon = _hasPausedQuiz ? Icons.play_arrow : Icons.shuffle;

    IconData mainButtonIcon = _hasPausedQuiz ? Icons.play_arrow : Icons.play_arrow;
    String mainButtonText = _hasPausedQuiz ? 'Resume Quiz' : 'Start Quiz';


    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withAlpha((0.8 * 255).round()),
              theme.primaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Semantics(
                  header: true,
                  label: 'Quiz Mode Screen',
                  child: const Text('Quiz Mode'),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.quiz,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          child: Text(
                            'Ready to Challenge Yourself?',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          label: 'Quiz Information',
                          child: Text(
                            'Test your knowledge with 50 random questions.\nYou\'ll have 45 seconds for each question.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: 200,
                          height: 60,
                          child: Semantics(
                            button: true,
                            label: _isLoading ? 'Loading quiz questions' : mainButtonText,
                            hint: 'Begin a new quiz with 50 random questions${_hasPausedQuiz ? ' or resume paused quiz' : ''}',
                            enabled: !_isLoading,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _startQuiz,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: theme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.black,),
                              )
                                  : ExcludeSemantics(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(mainButtonIcon),
                                    const SizedBox(width: 8),
                                    Text(
                                      mainButtonText,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}