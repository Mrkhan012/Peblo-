// Peblo widget and model tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:peblo/models/quiz_model.dart';

void main() {
  group('QuizQuestion.fromJson', () {
    test('parses a 4-option question', () {
      final q = QuizQuestion.fromJson({
        'question': 'What colour was Pip\'s lost gear?',
        'options': ['Red', 'Green', 'Blue', 'Yellow'],
        'answer': 'Blue',
      });
      expect(q.options.length, 4);
      expect(q.answer, 'Blue');
    });

    test('parses a 3-option question', () {
      final q = QuizQuestion.fromJson({
        'question': 'Who helped Pip?',
        'options': ['Owl', 'Squirrel', 'Chipmunk'],
        'answer': 'Owl',
      });
      expect(q.options.length, 3);
    });

    test('parses a 5-option question', () {
      final q = QuizQuestion.fromJson({
        'question': 'Pick a number',
        'options': ['1', '2', '3', '4', '5'],
        'answer': '3',
      });
      expect(q.options.length, 5);
    });

    test('throws when answer is not in options', () {
      expect(
        () => QuizQuestion.fromJson({
          'question': 'Bad',
          'options': ['a', 'b'],
          'answer': 'c',
        }),
        throwsFormatException,
      );
    });

    test('throws when options has fewer than 2 entries', () {
      expect(
        () => QuizQuestion.fromJson({
          'question': 'Bad',
          'options': ['only one'],
          'answer': 'only one',
        }),
        throwsFormatException,
      );
    });
  });
}
