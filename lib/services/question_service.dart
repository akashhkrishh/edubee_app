 import 'dart:convert';
import 'package:edubee_app/data/models/question_model.dart';
import 'package:flutter/services.dart';
import 'package:edubee_app/core/error/error_service.dart';
import 'package:flutter/foundation.dart';

class QuestionService {
  Future<List<Question>> loadQuestions() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/questions.json');
      final List<dynamic> jsonResponse = json.decode(jsonString);
      final questions = jsonResponse.map<Question>((q) => Question.fromJson(q)).toList();

      for (var question in questions) {
        final normalizedAnswer = question.answer.trim().toLowerCase();
        final normalizedChoice1 = question.choice1.trim().toLowerCase();
        final normalizedChoice2 = question.choice2.trim().toLowerCase();
        if (normalizedAnswer != 'a' &&
            normalizedAnswer != 'b' &&
            normalizedAnswer != '1' &&
            normalizedAnswer != '2' &&
            normalizedAnswer != normalizedChoice1 &&
            normalizedAnswer != normalizedChoice2) {
          if (kDebugMode) {
            print(
              'Warning: Invalid answer in question ID ${question.id}: '
                  'answer="$normalizedAnswer" does not match choice1="$normalizedChoice1", '
                  'choice2="$normalizedChoice2", or expected indices ("a", "b", "1", "2")',
            );
          }
        }
      }

      questions.sort((a, b) {
        final aIdMatch = RegExp(r'\d+').firstMatch(a.id);
        final bIdMatch = RegExp(r'\d+').firstMatch(b.id);

        if (aIdMatch != null && bIdMatch != null) {
          final aNum = int.tryParse(aIdMatch.group(0)!);
          final bNum = int.tryParse(bIdMatch.group(0)!);

          if (aNum != null && bNum != null) {
            return aNum.compareTo(bNum);
          }
        }
        return a.id.compareTo(b.id);
      });

      return questions;
    } catch (e, stackTrace) {
      if (kDebugMode) {}
      ErrorService.handleError(e, stackTrace);
      rethrow;
    }
  }

  List<String> getCategories(List<Question> questions) {
    final seen = <String>{};
    final orderedCategories = <String>[];
    for (var q in questions) {
      if (!seen.contains(q.category)) {
        seen.add(q.category);
        orderedCategories.add(q.category);
      }
    }
    return orderedCategories;
  }

  List<Question> filterQuestionsByCategory(
      List<Question> allQuestions, String? category) {
    if (category == null || category.toLowerCase() == 'all categories') {
      return allQuestions;
    }
    return allQuestions
        .where((q) => q.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}