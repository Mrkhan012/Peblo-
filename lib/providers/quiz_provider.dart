import 'package:flutter/foundation.dart';

enum QuizStatus { idle, wrong, success }

class QuizProvider extends ChangeNotifier {
  QuizStatus _status = QuizStatus.idle;
  String? _selectedOption;

  int _shakeTick = 0;

  QuizStatus get status => _status;
  String? get selectedOption => _selectedOption;
  int get shakeTick => _shakeTick;
  bool get isCorrect => _status == QuizStatus.success;

  void submit(String option, String correctAnswer) {
    _selectedOption = option;
    if (option == correctAnswer) {
      _status = QuizStatus.success;
    } else {
      _status = QuizStatus.wrong;
      _shakeTick++;
    }
    notifyListeners();
  }

  void reset() {
    _status = QuizStatus.idle;
    _selectedOption = null;
    notifyListeners();
  }
}
