import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;

  const ResultsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  String _getPerformanceMessage(double percentage) {
    if (percentage >= 90) {
      return 'Outstanding! 🌟';
    } else if (percentage >= 80) {
      return 'Great Job! 🎉';
    } else if (percentage >= 70) {
      return 'Well Done! 👏';
    } else if (percentage >= 60) {
      return 'Good Effort! 💪';
    } else {
      return 'Keep Practicing! 📚';
    }
  }

  Color _getBaseColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green.shade600;
    } else if (percentage >= 80) {
      return Colors.blue.shade600;
    } else if (percentage >= 70) {
      return Colors.amber.shade600;
    } else if (percentage >= 60) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  String _getPerformanceDescription(double percentage) {
    if (percentage >= 90) {
      return 'Excellent performance! You got most of the answers correct.';
    } else if (percentage >= 80) {
      return 'Very good performance! You got a high number of correct answers.';
    } else if (percentage >= 70) {
      return 'Good performance! You got many answers correct.';
    } else if (percentage >= 60) {
      return 'Fair performance. There is room for improvement.';
    } else {
      return 'Keep practicing to improve your score.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (score / totalQuestions) * 100;
    final baseColor = _getBaseColor(percentage);
    final performanceMessage = _getPerformanceMessage(percentage);
    final performanceDescription = _getPerformanceDescription(percentage);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor,
              baseColor.withAlpha((255 * 0.8).round()),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Semantics(
                  label: 'Quiz Results Page',
                  child: const Text('Quiz Results'),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        label: performanceMessage,
                        hint: performanceDescription,
                        child: Text(
                          performanceMessage,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withAlpha((255 * 0.9).round()),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withAlpha((255 * 0.15).round()),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Semantics(
                              label: 'Score Card Section',
                              child: Text(
                                'Your Score',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            MergeSemantics(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    score.toString(),
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: baseColor,
                                    ),
                                  ),
                                  Text(
                                    ' / $totalQuestions',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              label: 'Percentage score: ${percentage.round()}%',
                              child: Text(
                                '${percentage.round()}%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: baseColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Semantics(
                                button: true,
                                label: 'Return to Home Screen',
                                hint: 'Double tap to go back to the main menu',
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.popUntil(context, (route) => route.isFirst);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                    foregroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  icon: const Icon(Icons.home),
                                  label: const Text(
                                    'Return to Home',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: Semantics(
                                button: true,
                                label: 'Try Quiz Again',
                                hint: 'Double tap to restart the quiz with the same questions',
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.1).round()),
                                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text(
                                    'Try Again',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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