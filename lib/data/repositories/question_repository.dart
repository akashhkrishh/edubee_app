import 'package:edubee_app/data/models/question_model.dart';
import 'package:edubee_app/services/question_service.dart';

class QuestionRepository {
  final QuestionService _questionService;

  QuestionRepository(this._questionService);

  Future<List<Question>> getQuestions() async {
    return await _questionService.loadQuestions();
  }

  List<String> getCategories(List<Question> questions) {
    return _questionService.getCategories(questions);
  }
}