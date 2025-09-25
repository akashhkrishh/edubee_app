class Question {
  final String id;
  final String question;
  final String secondaryQuestion;
  final String choice1;
  final String choice2;
  final String answer;
  final String hint;
  final String category;
  final String type;
  final String mediaUrl;

  Question({
    required this.id,
    required this.question,
    required this.secondaryQuestion,
    required this.choice1,
    required this.choice2,
    required this.answer,
    required this.hint,
    required this.category,
    required this.type,
    required this.mediaUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      secondaryQuestion: json['secondaryQuestion'],
      choice1: json['choice1'],
      choice2: json['choice2'],
      answer: json['answer'],
      hint: json['hint'],
      category: json['category'],
      type: json['type'],
      mediaUrl: json['mediaUrl'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'secondaryQuestion': secondaryQuestion,
      'choice1': choice1,
      'choice2': choice2,
      'answer': answer,
      'hint': hint,
      'category': category,
      'type': type,
      'mediaUrl': mediaUrl,
    };
  }
}