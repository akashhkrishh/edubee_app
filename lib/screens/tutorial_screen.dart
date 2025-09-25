import 'package:flutter/material.dart';
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
  final QuestionRepository _questionRepository = QuestionRepository(QuestionService());
  late Future<List<Question>> _questionsFuture;
  List<Question> _allQuestions = [];
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadData();
  }

  Future<List<Question>> _loadData() async {
    final questions = await _questionRepository.getQuestions();
    setState(() {
      _allQuestions = questions;
      _categories = _questionRepository.getCategories(questions);
    });
    return questions;
  }

  Color _getColorForCategory(String category) {
    return AppConstants.categoryColors[category] ?? Colors.grey;
  }

  IconData _getIconForCategory(String category) {
    return AppConstants.categoryIcons[category] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          label: 'Tutorial Categories',
          child: const Text('Select a Category'),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Semantics(
              label: 'Loading Tutorial Categories',
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading categories...'),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Error loading categories',
                    child: Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    label: 'Retry loading categories',
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _questionsFuture = _loadData();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Semantics(
              label: 'Tutorial categories grid',
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final color = _getColorForCategory(category);
                    final icon = _getIconForCategory(category);

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          final categoryQuestions = _allQuestions.where((q) => q.category == category).toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionScreen(
                                questions: categoryQuestions,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Semantics(
                          label: category,
                          hint: 'Start $category tutorial',
                          button: true,
                          excludeSemantics: true,
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
                                  Icon(
                                    icon,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    category,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
}