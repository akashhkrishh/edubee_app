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

  // NEW FIELDS
  final String choiceType; // Can be 'text' or 'image'
  final String? choice1ImageUrl;
  final String? choice2ImageUrl;

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

    // NEW PARAMETERS
    required this.choiceType,
    this.choice1ImageUrl,
    this.choice2ImageUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      secondaryQuestion: json['secondaryQuestion'] ?? '',
      choice1: json['choice1'],
      choice2: json['choice2'],
      answer: json['answer'],
      hint: json['hint'] ?? 'No hint available.',
      category: json['category'],
      type: json['type'],
      mediaUrl: json['mediaUrl'] ?? '',

      // NEW MAPPINGS
      // Defaults to 'text' if not specified in the JSON
      choiceType: json['choiceType'] ?? 'text',
      choice1ImageUrl: json['choice1ImageUrl'], // Will be null if key doesn't exist
      choice2ImageUrl: json['choice2ImageUrl'], // Will be null if key doesn't exist
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

      // NEW MAPPINGS
      'choiceType': choiceType,
      'choice1ImageUrl': choice1ImageUrl,
      'choice2ImageUrl': choice2ImageUrl,
    };
  }

  // This method doesn't need to change as it only validates the text answer.
  bool isCorrect(int choiceIndex) {
    final selectedChoiceText = (choiceIndex == 0 ? choice1 : choice2).trim().toLowerCase();
    final correctAnswerText = answer.trim().toLowerCase();

    // Case 1: Answer is 'a'/'1' or 'b'/'2'
    if (correctAnswerText == 'a' || correctAnswerText == '1') {
      return choiceIndex == 0;
    }
    if (correctAnswerText == 'b' || correctAnswerText == '2') {
      return choiceIndex == 1;
    }

    // Case 2: Answer is the full text of the choice
    return selectedChoiceText == correctAnswerText;
  }
}