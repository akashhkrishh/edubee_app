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
  int _questionTimeLimit = 45; // For resuming

  @override
  void initState() {
    super.initState();
    _loadPausedState();
  }

  Future<void> _loadPausedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('is_paused') == true) {
      final jsonStr = prefs.getString('paused_questions_json');
      if (jsonStr != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(jsonStr);
          final questions = jsonList.map((json) => Question.fromJson(json)).toList();
          if (mounted) {
            setState(() {
              _hasPausedQuiz = true;
              _pausedQuestions = questions;
              _pausedIndex = prefs.getInt('current_index') ?? 0;
              _pausedScore = prefs.getInt('score') ?? 0;
              _pausedTimeRemaining = prefs.getInt('paused_time') ?? 45;
              _originalTotal = prefs.getInt('original_total') ?? questions.length;
              _questionTimeLimit = prefs.getInt('question_time_limit') ?? 45;
            });
          }
        } catch (e) {
          await _clearPausedState(prefs);
        }
      } else {
        await _clearPausedState(prefs);
      }
    }
  }

  Future<void> _clearPausedState([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    await prefs.remove('is_paused');
    await prefs.remove('paused_questions_json');
    await prefs.remove('current_index');
    await prefs.remove('score');
    await prefs.remove('paused_time');
    await prefs.remove('original_total');
    await prefs.remove('question_time_limit');
    if (mounted) {
      setState(() {
        _hasPausedQuiz = false;
      });
    }
  }

  Future<void> _showResumeDialog() async {
    final prefs = await SharedPreferences.getInstance();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Resume Quiz?'),
        content: const Text('You have a quiz in progress. Continue or start a new one?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Start New'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearPausedState(prefs);
              _startNewQuiz();
            },
          ),
          ElevatedButton(
            child: const Text('Resume'),
            onPressed: () {
              Navigator.of(context).pop();
              _resumeQuiz();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startQuiz() async {
    if (_hasPausedQuiz) {
      await _showResumeDialog();
    } else {
      await _startNewQuiz();
    }
  }

  // NEW: Dialog to select time
  Future<int?> _showTimeSelectionDialog() async {
    return await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _TimeSelectorDialog();
      },
    );
  }

  Future<void> _startNewQuiz() async {
    // Show time selection dialog before starting
    final selectedTime = await _showTimeSelectionDialog();
    if (selectedTime == null || !mounted) return; // User cancelled

    setState(() => _isLoading = true);
    try {
      final allQuestions = await _questionService.loadQuestions();
      final quizQuestions = allQuestions.take(50).toList();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionScreen(
              questions: quizQuestions,
              isQuizMode: true,
              originalTotal: quizQuestions.length,
              questionTimeLimit: selectedTime, // Pass the selected time
            ),
          ),
        ).then((_) => _loadPausedState());
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
          questionTimeLimit: _questionTimeLimit, // Pass saved time limit
        ),
      ),
    ).then((_) => _loadPausedState());
  }

  @override
  Widget build(BuildContext context) {
    // ... UI build method remains largely the same ...
    final theme = Theme.of(context);
    String mainButtonText = _hasPausedQuiz ? 'Resume Quiz' : 'Start Quiz';
    IconData mainButtonIcon = _hasPausedQuiz ? Icons.play_arrow : Icons.shuffle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Mode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz, size: 80),
              const SizedBox(height: 24),
              Text(
                'Ready to Challenge Yourself?',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Test your knowledge with 50 random questions.\nYou can set the time limit for each question.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startQuiz,
                  style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  icon: _isLoading ? const SizedBox.shrink() : Icon(mainButtonIcon),
                  label: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                      : Text(mainButtonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSelectorDialog extends StatefulWidget {
  const _TimeSelectorDialog();

  @override
  State<_TimeSelectorDialog> createState() => _TimeSelectorDialogState();
}

class _TimeSelectorDialogState extends State<_TimeSelectorDialog> {
  int _selectedTime = 45; // Default value
  final int _minTime = 0;
  final int _maxTime = 120;
  final int _step = 5;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = _selectedTime.toString();
  }

  void _updateTime(int newValue) {
    setState(() {
      _selectedTime = newValue.clamp(_minTime, _maxTime);
      _controller.text = _selectedTime.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Time Per Question'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter time between 30 and 120 seconds (increments of 5):'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _selectedTime > _minTime
                    ? () => _updateTime(_selectedTime - _step)
                    : null,
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null) {
                      _updateTime(parsed);
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _selectedTime < _maxTime
                    ? () => _updateTime(_selectedTime + _step)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$_selectedTime seconds', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedTime);
          },
          child: const Text('Start'),
        ),
      ],
    );
  }
}
