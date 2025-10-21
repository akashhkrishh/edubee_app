import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edubee_app/core/constants/app_constants.dart';
import 'package:edubee_app/data/models/question_model.dart';
import 'package:edubee_app/data/repositories/question_repository.dart';
import 'package:edubee_app/screens/question_screen.dart';
import 'package:edubee_app/services/question_service.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final QuestionRepository _questionRepository =
  QuestionRepository(QuestionService());
  late Future<List<Question>> _questionsFuture;
  List<Question> _allQuestions = [];
  List<String> _categories = [];

  Map<String, int> _completedCounts = {}; // category → completed count
  Map<String, double> _progress = {}; // category → completion %

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadData();
  }

  Future<List<Question>> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final questions = await _questionRepository.getQuestions();

    // Using `mounted` check before setState in async method
    if (!mounted) return questions;

    setState(() {
      _allQuestions = questions;
      _categories = _questionRepository.getCategories(questions);

      // Load saved progress from SharedPreferences
      for (final category in _categories) {
        final completed = prefs.getInt('completed_$category') ?? 0;
        final total =
            _allQuestions.where((q) => q.category == category).length;
        final percentage = total > 0 ? completed / total : 0.0;
        _completedCounts[category] = completed;
        _progress[category] = percentage;
      }
    });
    return questions;
  }

  Future<void> _saveProgress(String category, int completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('completed_$category', completed);
  }

  Color _getColorForCategory(String category) {
    return AppConstants.categoryColors[category] ?? Colors.grey;
  }

  IconData _getIconForCategory(String category) {
    return AppConstants.categoryIcons[category] ?? Icons.category;
  }

  void _updateCategoryProgress(String category, int newCompletedCount) {
    final total = _allQuestions.where((q) => q.category == category).length;
    // Ensure completed count does not exceed total
    final completed = newCompletedCount > total ? total : newCompletedCount;

    final percentage = total > 0 ? completed / total : 0.0;

    setState(() {
      _completedCounts[category] = completed;
      _progress[category] = percentage;
    });

    _saveProgress(category, completed);
  }

  Future<void> _navigateToQuestions(
      String category, List<Question> categoryQuestions, int startingIndex) async {
    // Navigate to QuestionScreen and wait for a result.
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreen(
          questions: categoryQuestions,
          isQuizMode: false,
          questionTimeLimit: 0,
          currentIndex: startingIndex,
        ),
      ),
    );

    // If the user came back with a progress value, update it.
    if (result != null) {
      final currentProgress = _completedCounts[category] ?? 0;
      if (result > currentProgress) {
        _updateCategoryProgress(category, result);
      } else if (startingIndex == 0) {
        // Handle case where user restarted and didn't finish
        _updateCategoryProgress(category, result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Category'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading categories...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _questionsFuture = _loadData();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final color = _getColorForCategory(category);
                  final icon = _getIconForCategory(category);

                  final total = _allQuestions
                      .where((q) => q.category == category)
                      .length;
                  final completed = _completedCounts[category] ?? 0;
                  final percentage = _progress[category] ?? 0.0;

                  return Card(
                    elevation: 4,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final categoryQuestions = _allQuestions
                            .where((q) => q.category == category)
                            .toList();

                        // Check if the category is fully completed
                        if (completed >= total) {
                          final shouldRestart = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Restart Tutorial?'),
                              content: const Text(
                                  'You have already completed this category. Would you like to start over?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Restart'),
                                ),
                              ],
                            ),
                          );

                          // If user confirms restart, reset progress and navigate
                          if (shouldRestart == true) {
                            _updateCategoryProgress(category, 0);
                            await _navigateToQuestions(category, categoryQuestions, 0);
                          }
                        } else {
                          // If not completed, resume from where they left off
                          await _navigateToQuestions(category, categoryQuestions, completed);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withAlpha((0.7 * 255).round()),
                              color,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, size: 40, color: Colors.white),
                              const SizedBox(height: 12),
                              Text(
                                category,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: percentage,
                                backgroundColor:
                                Colors.white.withOpacity(0.3),
                                color: Colors.white,
                                minHeight: 6,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$completed / $total completed (${(percentage * 100).toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}