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
import 'package:flutter/foundation.dart';

class QuestionScreen extends StatefulWidget {
  final List<Question> questions;
  final bool isQuizMode;
  final int? currentIndex;
  final int? score;
  final int? pausedTimeRemaining;
  final int? originalTotal;

  const QuestionScreen({
    super.key,
    required this.questions,
    this.isQuizMode = false,
    this.currentIndex,
    this.score,
    this.pausedTimeRemaining,
    this.originalTotal,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int _currentIndex = 0;
  late Question _currentQuestion;
  Timer? _timer;
  int _timerSeconds = 45;
  int? _selectedChoiceIndex;
  bool? _isCorrect;
  int _score = 0;
  int _totalTimeSpent = 0;
  int? _pausedTimeRemaining;
  final GlobalKey<MediaWidgetState> _mediaKey = GlobalKey<MediaWidgetState>();
  final BackgroundMusicService _musicService = BackgroundMusicService();
  late final SoundService _soundService;
  bool _hasAnswered = false;
  late final SettingsProvider _settingsProvider;
  StreamSubscription? _usbSubscription;
  bool _isPaused = false;
  late final int _totalQuestions;
  static const int _questionTimeLimit = 45;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _soundService = SoundService();
    _currentIndex = widget.currentIndex ?? 0;
    _currentQuestion = widget.questions[_currentIndex];
    _score = widget.score ?? 0;
    _timerSeconds = widget.pausedTimeRemaining ?? _questionTimeLimit;
    _totalQuestions = widget.originalTotal ?? widget.questions.length;
    _totalTimeSpent = _currentIndex * _questionTimeLimit;

    if (widget.isQuizMode) {
      startTimer(_timerSeconds);
    }
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _musicService.stopBackgroundMusic();

    final usbController = Provider.of<UsbController>(context, listen: false);
    _usbSubscription = usbController.answerStream.listen((answerIndex) {
      if (mounted) {
        if (kDebugMode) {
          print('USB input received: answerIndex=$answerIndex');
        }
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
    super.dispose();
  }

  Future<void> _savePausedState() async {
    if (!widget.isQuizMode) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = widget.questions.map((q) => q.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);

    await prefs.setBool('is_paused', true);
    await prefs.setString('paused_questions_json', jsonStr);
    await prefs.setInt('current_index', _currentIndex);
    await prefs.setInt('score', _score);
    await prefs.setInt('paused_time', _timerSeconds);
    await prefs.setInt('original_total', _totalQuestions);
  }

  Future<void> _clearPausedState() async {
    if (!widget.isQuizMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_paused', false);
    await prefs.remove('paused_questions_json');
    await prefs.remove('current_index');
    await prefs.remove('score');
    await prefs.remove('paused_time');
    await prefs.remove('original_total');
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && !_hasAnswered && !_isPaused) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        if (kDebugMode) {
          print('Keyboard input: Selected choice 1');
        }
        _handleAnswer(0);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        if (kDebugMode) {
          print('Keyboard input: Selected choice 2');
        }
        _handleAnswer(1);
        return true;
      }
    }
    return false;
  }

  void startTimer([int? initialTime]) {
    _timerSeconds = initialTime ?? _questionTimeLimit;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) return;
      setState(() {
        _timerSeconds--;
        if (_timerSeconds <= 0) {
          timer.cancel();
          _handleAnswer(null);
        }
      });
    });
  }

  Future<bool> _onPopInvoked(bool didPop) async {
    if (didPop) return true;

    if (!widget.isQuizMode) {
      return true;
    }
    if (!_isPaused) {
      await _showBackConfirmationDialog();
    }
    return false;
  }

  Future<void> _showBackConfirmationDialog() async {
    if (!mounted) return; // Add mounted check before setState
    setState(() {
      _isPaused = true;
      _pausedTimeRemaining = _timerSeconds;
      _timer?.cancel();
    });

    // final theme = Theme.of(context);
    final bool? shouldSaveAndExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Text('Return to Home?', style: TextStyle(fontWeight:FontWeight.bold ),),
            ],
          ),
          content: const Text(
            'Your quiz progress will be saved and you can resume later.',
            style: TextStyle(fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (mounted) Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (mounted) Navigator.of(context).pop(true);
                  }, // Save & Exit
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Save & Exit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldSaveAndExit == true) {
      await _savePausedState();
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      if (!mounted) return;
      setState(() {
        _isPaused = false;
        if (widget.isQuizMode) {
          startTimer(_pausedTimeRemaining);
        }
      });
    }
  }

  Future<void> _showSaveAndExitDialog() async {
    if (!mounted) return;
    Navigator.pop(context);

    final bool? shouldSaveAndExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Text('Return to Home?', style: TextStyle(fontWeight:FontWeight.bold ),),
            ],
          ),
          content: const Text(
            'Your quiz progress will be saved and you can resume later.',
            style: TextStyle(fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (mounted) Navigator.of(context).pop(false);
                  }, // Cancel
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (mounted) Navigator.of(context).pop(true);
                  }, // Save & Exit
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Save & Exit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        );

      },
    );

    if (shouldSaveAndExit == true) {
      await _savePausedState();
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else if (shouldSaveAndExit == false) {
      if (mounted) {
        togglePause(isReshow: true);
      }
    }
  }
  void _showPauseDialog({bool isReshow = false}) {
    if (!mounted) return;

    final theme = Theme.of(context);
    final questionsAnswered = _currentIndex;
    final progressPercentage = (_currentIndex / _totalQuestions * 100).round();

    if (!isReshow) {
      _isPaused = true;
      _pausedTimeRemaining = _timerSeconds;
      _timer?.cancel();
      _savePausedState();
    }

    const int timeLimit = _questionTimeLimit;

    // final timeElapsedForCurrentQuestion = timeLimit - (_pausedTimeRemaining ?? timeLimit);
    // final totalTimeElapsed = _totalTimeSpent + timeElapsedForCurrentQuestion; // Not used in display but calculated

    final int futureQuestionsCount = _totalQuestions - (_currentIndex + 1);

    final int totalTimeRemaining = (futureQuestionsCount * timeLimit) + (_pausedTimeRemaining ?? timeLimit);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quiz Paused',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: progressPercentage / 100,
                              strokeWidth: 4,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          ),
                          Text(
                            '$progressPercentage%',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Progress', style: theme.textTheme.labelMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Question ${questionsAnswered + 1} of $_totalQuestions', // Display current question
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_outlined, size: 18),
                              const SizedBox(width: 4),
                               Text('Score: $_score/$_totalQuestions', style: theme.textTheme.bodyLarge),
                              const SizedBox(width: 16),
                              const Icon(Icons.timer_outlined, size: 18),
                              const SizedBox(width: 4),
                              Text('Time: ${_formatTotalTime(totalTimeRemaining)}', style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!mounted) return;
                      Navigator.pop(context);
                      setState(() {
                        _isPaused = false;
                        if (widget.isQuizMode) {
                          startTimer(_pausedTimeRemaining);
                        }
                      });
                    },
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text('Resume Quiz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          ).then((_) {
                            if (mounted) {
                              togglePause(isReshow: true);
                            }
                          });
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: theme.colorScheme.onSurface,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (!mounted) return;

                          final bool? shouldRestart = await showDialog<bool>(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text(
                                  'Restart Quiz?',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: const Text(
                                  'Your current progress will be lost. Do you want to restart?',
                                  style: TextStyle(fontSize: 16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      if (mounted) Navigator.of(context).pop(false);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (mounted) Navigator.of(context).pop(true);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Restart'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldRestart == true) {
                            if (!mounted) return;
                            Navigator.pop(context);
                            await _clearPausedState();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restart'),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: widget.isQuizMode
                        ? _showSaveAndExitDialog
                        : () {
                      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Return to Home'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 0) seconds = 0;
    return '$seconds s';
  }

  String _formatTotalTime(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;

    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;

    String output = '';

    if (minutes > 0) {
      output += '$minutes min';
      if (seconds > 0) {
        output += ' ';
      }
    }

    if (seconds > 0 || output.isEmpty) {
      output += '$seconds sec';
    }

    return output;
  }
  void _showTutorialPauseDialog() {
    if (!mounted) return;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Tutorial Paused',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (!mounted) return;
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ).then((_) {
                        if (mounted) _showTutorialPauseDialog();
                      });
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings', style: TextStyle(fontSize: 18)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Return to Home', style: TextStyle(fontSize: 18)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                       backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> togglePause({bool isReshow = false}) async {
    if (!widget.isQuizMode) {
      if (mounted) _showTutorialPauseDialog();
      return;
    }

    if (!isReshow && !_isPaused) {
      if (!mounted) return;
      setState(() {
        _isPaused = true;
        _pausedTimeRemaining = _timerSeconds;
        _timer?.cancel();
      });
    }

    if (mounted) {
      _showPauseDialog(isReshow: isReshow);
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
      if (choiceIndex == null) {
        _isCorrect = false;
        if (kDebugMode) {
          print('No answer selected (timeout). Marked as incorrect.');
        }
      } else {
        final selectedAnswer = choiceIndex == 0 ? _currentQuestion.choice1 : _currentQuestion.choice2;
        final normalizedAnswer = _currentQuestion.answer.trim().toLowerCase();
        if (kDebugMode) {
          print('Question ID: ${_currentQuestion.id}');
          print('Choice1: "${_currentQuestion.choice1}"');
          print('Choice2: "${_currentQuestion.choice2}"');
          print('Selected answer: "$selectedAnswer" (choiceIndex: $choiceIndex)');
          print('Correct answer: "${_currentQuestion.answer}" (normalized: "$normalizedAnswer")');
        }
        if (normalizedAnswer == 'a' || normalizedAnswer == '1') {
          _isCorrect = choiceIndex == 0;
        } else if (normalizedAnswer == 'b' || normalizedAnswer == '2') {
          _isCorrect = choiceIndex == 1;
        } else {
          final normalizedSelected = selectedAnswer.trim().toLowerCase();
          _isCorrect = normalizedSelected == normalizedAnswer;
        }
        if (kDebugMode) {
          print('Is correct: $_isCorrect');
        }
        if (_isCorrect! && widget.isQuizMode) {
          _score++;
        }
      }

      if (widget.isQuizMode) {
        _totalTimeSpent += (_questionTimeLimit - _timerSeconds);
      }
    });

    if (_settingsProvider.isSfxEnabled) {
      if (_isCorrect ?? false) {
        _soundService.playCorrectSound();
      } else {
        _soundService.playIncorrectSound();
      }
    }

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      await _resetAndGoToNext();
    });
  }

  Color _getButtonColor(int choiceIndex) {
    final theme = Theme.of(context);
    if (_selectedChoiceIndex == null) {
      return theme.colorScheme.primary;
    }
    final normalizedAnswer = _currentQuestion.answer.trim().toLowerCase();
    bool isCorrectChoice;
    if (normalizedAnswer == 'a' || normalizedAnswer == '1') {
      isCorrectChoice = choiceIndex == 0;
    } else if (normalizedAnswer == 'b' || normalizedAnswer == '2') {
      isCorrectChoice = choiceIndex == 1;
    } else {
      final choiceText = choiceIndex == 0 ? _currentQuestion.choice1 : _currentQuestion.choice2;
      isCorrectChoice = choiceText.trim().toLowerCase() == normalizedAnswer;
    }
    if (_selectedChoiceIndex == choiceIndex) {
      return _isCorrect! ? Colors.green : Colors.red;
    }
    return isCorrectChoice ? Colors.green : theme.colorScheme.primary;
  }

  Future<void> _resetAndGoToNext() async {
    _timer?.cancel();
    _pausedTimeRemaining = null;
    _hasAnswered = false;
    if (_currentIndex < widget.questions.length - 1) {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _currentQuestion = widget.questions[_currentIndex];
        _selectedChoiceIndex = null;
        _isCorrect = null;
        if (widget.isQuizMode) {
          startTimer();
        }
      });
    } else {
      if (widget.isQuizMode) {
        await _clearPausedState();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                score: _score,
                totalQuestions: _totalQuestions,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  Widget _buildMediaWidget() {
    return MediaWidget(
      key: _mediaKey,
      question: _currentQuestion,
    );
  }

  Widget _buildFeedbackIndicator() {
    // final theme = Theme.of(context);
    if (_isCorrect == null) return const SizedBox.shrink();

    final color = _isCorrect! ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.2).round()),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isCorrect! ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 10),
          Text(
            _isCorrect! ? 'Correct!' : 'Incorrect!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintButton() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _selectedChoiceIndex != null
              ? null
              : () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: theme.colorScheme.surface,
                title: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber, size: 28),
                    const SizedBox(width: 10),
                    Text('Hint', style: TextStyle(fontSize: 22, color: theme.colorScheme.onSurface)),
                  ],
                ),
                content: Text(
                  _currentQuestion.hint,
                  style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (mounted) Navigator.pop(context);
                    },
                    child: Text('Got it', style: TextStyle(fontSize: 16, color: theme.colorScheme.primary)),
                  ),
                ],
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.withAlpha((255 * 0.1).round()),
            foregroundColor: Colors.amber.shade800,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            shadowColor: Colors.amber.withAlpha((255 * 0.3).round()),
          ),
          icon: const Icon(Icons.lightbulb_outline, size: 24),
          label: const Text('Show Hint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildAnswerButtonsRow() {
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

  Widget _buildAnswerButtonsColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAnswerButton(0),
        const SizedBox(height: 16),
        _buildAnswerButton(1),
      ],
    );
  }

  Widget _buildAnswerButton(int choiceIndex) {
    final theme = Theme.of(context);
    final choiceText = choiceIndex == 0 ? _currentQuestion.choice1 : _currentQuestion.choice2;
    final buttonColor = _getButtonColor(choiceIndex);
    final isDefaultColor = buttonColor == theme.colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: isDefaultColor
            ? theme.colorScheme.surface
            : buttonColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _selectedChoiceIndex != null ? null : () => _handleAnswer(choiceIndex),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(
          choiceText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDefaultColor
                ? theme.colorScheme.onSurface
                : Colors.white,
          ),
        ),
      ),
    );
  }

  double get _progressValue {
    if (_totalQuestions == 0) return 0.0;
    return (_currentIndex + 1) / _totalQuestions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
          ),
          child: SafeArea(
            child: Column(
              children: [
                AppBar(
                  title: Semantics(
                    header: true,
                    label: widget.isQuizMode ? 'Quiz Question' : 'Tutorial Question',
                    child: Text(
                      widget.isQuizMode ? 'Question ${_currentIndex + 1} / $_totalQuestions' : 'Tutorial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.pause,
                        size: 28,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: togglePause,
                      tooltip: 'Pause',
                    ),
                    if (widget.isQuizMode)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _formatTime(_timerSeconds),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),

                if (widget.isQuizMode)
                  LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    minHeight: 8,
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          _currentQuestion.question,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildMediaWidget(),
                        const SizedBox(height: 24),
                        if (!widget.isQuizMode) _buildHintButton(),
                        _buildFeedbackIndicator(),
                        const SizedBox(height: 24),
                        MediaQuery.of(context).size.width > 600
                            ? _buildAnswerButtonsRow()
                            : _buildAnswerButtonsColumn(),
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