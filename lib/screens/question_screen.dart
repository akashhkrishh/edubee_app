import 'dart:async';
import 'dart:convert';
import 'package:edubee_app/data/models/question_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edubee_app/controllers/usb_controller.dart';
import 'package:edubee_app/screens/results_screen.dart';
import 'package:edubee_app/screens/settings_screen.dart';
import 'package:edubee_app/services/background_music_service.dart';
import 'package:edubee_app/services/sound_service.dart';
import 'package:edubee_app/widgets/media_widget.dart';
import 'package:provider/provider.dart';
import 'package:edubee_app/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionScreen extends StatefulWidget {
  final List<Question> questions;
  final bool isQuizMode;
  final int questionTimeLimit;
  final int? currentIndex;
  final int? score;
  final int? pausedTimeRemaining;
  final int? originalTotal;

  const QuestionScreen({
    super.key,
    required this.questions,
    this.isQuizMode = false,
    required this.questionTimeLimit,
    this.currentIndex,
    this.score,
    this.pausedTimeRemaining,
    this.originalTotal,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late Question _currentQuestion;
  Timer? _timer;
  int _timerSeconds = 0;
  int? _selectedChoiceIndex;
  bool? _isCorrect;
  int _score = 0;
  final GlobalKey<MediaWidgetState> _mediaKey = GlobalKey<MediaWidgetState>();
  final BackgroundMusicService _musicService = BackgroundMusicService();
  late final SoundService _soundService;
  bool _hasAnswered = false;
  late final SettingsProvider _settingsProvider;
  StreamSubscription? _usbSubscription;
  bool _isPaused = false;
  late final int _totalQuestions;
  static const Duration _feedbackDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _soundService = SoundService();
    _currentIndex = widget.currentIndex ?? 0;
    _currentQuestion = widget.questions[_currentIndex];
    _score = widget.score ?? 0;
    _timerSeconds = widget.pausedTimeRemaining ?? widget.questionTimeLimit;
    _totalQuestions = widget.originalTotal ?? widget.questions.length;

    if (widget.isQuizMode) {
      _startTimer(_timerSeconds);
    }
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _musicService.stopBackgroundMusic();
    WidgetsBinding.instance.addObserver(this);

    final usbController = Provider.of<UsbController>(context, listen: false);
    _usbSubscription = usbController.answerStream.listen((answerIndex) {
      if (mounted) {
        _handleAnswer(answerIndex);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    if (_settingsProvider.isMusicEnabled) {
      _musicService.playBackgroundMusic();
    }
    _usbSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _musicService.stopBackgroundMusic();
    } else if (state != AppLifecycleState.resumed && !_isPaused) {
      _enterPauseState();
    }
  }

  void _pauseAllAudio() {
    _mediaKey.currentState?.stopPlayback();
  }

  void _resumeAllAudio() {
    _mediaKey.currentState?.resumePlayback();
  }

  void _enterPauseState() {
    if (!_isPaused) {
      setState(() {
        _isPaused = true;
        _timer?.cancel();
      });
      _pauseAllAudio();
    }
  }

  void _exitPauseState() {
    if (_isPaused) {
      setState(() {
        _isPaused = false;
        if (widget.isQuizMode) {
          _startTimer(_timerSeconds);
        }
      });
      _resumeAllAudio();
    }
  }

  Future<void> _savePausedState() async {
    if (!widget.isQuizMode) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = widget.questions.map((q) => q.toJson()).toList();
    await prefs.setBool('is_paused', true);
    await prefs.setString('paused_questions_json', jsonEncode(jsonList));
    await prefs.setInt('current_index', _currentIndex);
    await prefs.setInt('score', _score);
    await prefs.setInt('paused_time', _timerSeconds);
    await prefs.setInt('original_total', _totalQuestions);
    await prefs.setInt('question_time_limit', widget.questionTimeLimit);
  }

  Future<void> _clearPausedState() async {
    if (!widget.isQuizMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_paused');
    await prefs.remove('paused_questions_json');
    await prefs.remove('current_index');
    await prefs.remove('score');
    await prefs.remove('paused_time');
    await prefs.remove('original_total');
    await prefs.remove('question_time_limit');
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && !_hasAnswered && !_isPaused) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _handleAnswer(0);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        _handleAnswer(1);
        return true;
      }
    }
    return false;
  }

  void _startTimer([int? initialTime]) {
    _timerSeconds = initialTime ?? widget.questionTimeLimit;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) return;
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
        _handleAnswer(null);
      }
    });
  }

  Future<bool> _onWillPop() async {
    _enterPauseState();
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return widget.isQuizMode
            ? AlertDialog(
          title: const Text('Exit Quiz?'),
          content: const Text('Your progress will be saved. You can resume later.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save & Exit')),
          ],
        )
            : AlertDialog(
          title: const Text('Exit Tutorial?'),
          content: const Text('Your progress on this category will be saved.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Continue')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Exit')),
          ],
        );
      },
    );

    if (shouldExit == true) {
      return true; // Allow PopScope to handle the pop
    } else {
      _exitPauseState();
      return false; // Prevent pop
    }
  }

  void _handleAnswer(int? choiceIndex) {
    if (_hasAnswered) return;
    _hasAnswered = true;
    _timer?.cancel();
    _mediaKey.currentState?.stopPlayback();

    if (!mounted) return;
    setState(() {
      _selectedChoiceIndex = choiceIndex;
      if (choiceIndex != null) {
        _isCorrect = _currentQuestion.isCorrect(choiceIndex);
        if (_isCorrect! && widget.isQuizMode) {
          _score++;
        }
      } else {
        _isCorrect = false;
      }
    });

    if (_settingsProvider.isSfxEnabled) {
      if (_isCorrect ?? false) {
        _soundService.playCorrectSound();
      } else {
        _soundService.playIncorrectSound();
      }
    }

    Future.delayed(_feedbackDuration, () {
      if (mounted) {
        _resetAndGoToNext();
      }
    });
  }

  void _openPauseMenu() {
    _enterPauseState();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(widget.isQuizMode ? 'Quiz Paused' : 'Tutorial Paused'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exitPauseState();
            },
            child: const Text('Resume'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the pause menu
              if (widget.isQuizMode) {
                await _savePausedState();
                if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                // For tutorials, just go back one screen, returning progress
                if (mounted) Navigator.of(context).pop(_currentIndex);
              }
            },
            child: Text(widget.isQuizMode ? 'Save & Exit to Home' : 'Exit to Category Menu'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the pause menu
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))
                  .then((_) => _exitPauseState()); // Resume when returning
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAndGoToNext() async {
    _timer?.cancel();
    if (!mounted) return;

    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _currentQuestion = widget.questions[_currentIndex];
        _selectedChoiceIndex = null;
        _isCorrect = null;
        _hasAnswered = false;
        if (widget.isQuizMode) {
          _startTimer();
        }
      });
    } else {
      // Last question has been answered
      if (widget.isQuizMode) {
        await _clearPausedState();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(score: _score, totalQuestions: _totalQuestions),
            ),
          );
        }
      } else {
        // Tutorial finished, pop and return the total count of questions completed
        if (mounted) Navigator.pop(context, _currentIndex + 1);
      }
    }
  }

  // --- UI BUILDER METHODS ---

  Color _getButtonColor(int choiceIndex) {
    const Color color1 = Color(0xFFFE6A00);
    const Color color2 = Color(0xFF00AEEF);
    final Color defaultColor = choiceIndex == 0 ? color1 : color2;

    if (!_hasAnswered) return defaultColor;

    final isCorrectChoice = _currentQuestion.isCorrect(choiceIndex);
    if (isCorrectChoice) return Colors.green;
    if (_selectedChoiceIndex == choiceIndex) return Colors.red;
    return defaultColor.withOpacity(0.5);
  }

  Color _getBorderColor(int choiceIndex) {
    if (!_hasAnswered) return Colors.transparent;
    final isCorrect = _currentQuestion.isCorrect(choiceIndex);
    if (isCorrect) return Colors.green;
    if (_selectedChoiceIndex == choiceIndex) return Colors.red;
    return Colors.grey.withOpacity(0.5);
  }

  Widget _buildFeedbackIndicator() {
    if (_isCorrect == null) return const SizedBox(height: 70);
    final color = _isCorrect! ? Colors.green : Colors.red;
    final icon = _isCorrect! ? Icons.check_circle : Icons.cancel;
    final text = _isCorrect! ? 'Correct!' : 'Incorrect!';
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton.icon(
        onPressed: _hasAnswered
            ? null
            : () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Hint'),
              content: Text(_currentQuestion.hint),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
            ),
          );
        },
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('Show Hint'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }

  Widget _buildAnswerArea() {
    if (_currentQuestion.choiceType == 'image') {
      return SizedBox(
        height: 220, // Constrain the height of the row
        child: Row(
          children: [
            Expanded(
              child: _AnswerCard(
                text: _currentQuestion.choice1,
                imageUrl: _currentQuestion.choice1ImageUrl ?? '',
                onTap: () => _handleAnswer(0),
                borderColor: _getBorderColor(0),
                barColor: const Color(0xFFFE6A00),
                isDisabled: _hasAnswered,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AnswerCard(
                text: _currentQuestion.choice2,
                imageUrl: _currentQuestion.choice2ImageUrl ?? '',
                onTap: () => _handleAnswer(1),
                borderColor: _getBorderColor(1),
                barColor: const Color(0xFF00AEEF),
                isDisabled: _hasAnswered,
              ),
            ),
          ],
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildAnswerButton(0),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildAnswerButton(1),
          ),
        ],
      );

    }
  }

  Widget _buildAnswerButton(int choiceIndex) {
    final choiceText = choiceIndex == 0 ? _currentQuestion.choice1 : _currentQuestion.choice2;
    final buttonColor = _getButtonColor(choiceIndex);

    return ElevatedButton(
      onPressed: _hasAnswered ? null : () => _handleAnswer(choiceIndex),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        disabledBackgroundColor: buttonColor.withOpacity(0.8),
      ),
      child: Text(
        choiceText,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit == true && mounted) {
          if (widget.isQuizMode) {
            await _savePausedState();
            Navigator.of(context).pop();
          } else {
            // For tutorial mode, pop with the current progress index
            Navigator.of(context).pop(_currentIndex);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isQuizMode ? 'Question ${_currentIndex + 1} / $_totalQuestions' : 'Tutorial',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (widget.isQuizMode)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '$_timerSeconds s',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.pause, size: 28),
              onPressed: _openPauseMenu,
              tooltip: 'Pause',
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (widget.isQuizMode)
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / _totalQuestions,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    minHeight: 8,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          _currentQuestion.question,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        MediaWidget(
                          key: _mediaKey,
                          question: _currentQuestion,
                        ),
                        const SizedBox(height: 24),
                        if (!widget.isQuizMode) _buildHintButton(),
                        if (_hasAnswered)
                          _buildFeedbackIndicator()
                        else
                          SizedBox(height: widget.isQuizMode ? 70 : 0),
                        _buildAnswerArea(),
                      ],
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
}

// A theme-aware card for image-based answers.
class _AnswerCard extends StatelessWidget {
  final String text;
  final String imageUrl;
  final VoidCallback onTap;
  final Color borderColor;
  final Color barColor;
  final bool isDisabled;

  const _AnswerCard({
    required this.text,
    required this.imageUrl,
    required this.onTap,
    required this.borderColor,
    required this.barColor,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                padding: const EdgeInsets.all(8.0),
                child: imageUrl.isNotEmpty
                    ? Image.asset(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, size: 48),
                )
                    : const Center(child: Icon(Icons.image_not_supported, size: 48)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: barColor.withOpacity(isDisabled ? 0.5 : 1.0),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            )
          ],
        ),
      ),
    );
  }
}