class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String answer;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List) {
      throw const FormatException(
        'Quiz JSON must contain an "options" array of strings.',
      );
    }
    final options = rawOptions
        .map((e) => e is String ? e : e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    if (options.length < 2) {
      throw const FormatException(
        'A quiz question must have at least 2 options.',
      );
    }
    if ((json['answer'] as String?) == null) {
      throw const FormatException('Quiz JSON must contain an "answer".');
    }
    if (!options.contains(json['answer'])) {
      throw const FormatException(
        'The "answer" must be present in the options array.',
      );
    }

    return QuizQuestion(
      id: (json['id'] as String?) ??
          'q_${DateTime.now().microsecondsSinceEpoch}',
      question: json['question'] as String,
      options: options,
      answer: json['answer'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'answer': answer,
      };
}
