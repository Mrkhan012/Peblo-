import 'package:flutter/foundation.dart';

enum QuizStatus { idle, wrong, success }

/// State container for the data-driven quiz.
///
/// The provider only knows:
///  - which option the user tapped
///  - whether to show a "shake" feedback
///  - whether the quiz has been solved
///
/// The actual question/options/answer live in the QuizQuestion
/// model. To swap in a new question, just push a new model — no
/// UI changes required.
class QuizProvider extends ChangeNotifier {
  QuizStatus _status = QuizStatus.idle;
  String? _selectedOption;

  /// A monotonic counter the UI watches to fire its shake
  /// animation. Incrementing it tells the widget "shake again",
  /// without us having to ship a controller reference around.
  int _shakeTick = 0;

  QuizStatus get status => _status;
  String? get selectedOption => _selectedOption;
  int get shakeTick => _shakeTick;
  bool get isCorrect => _status == QuizStatus.success;

  /// Submit a chosen option. Updates state and notifies.
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

  /// Reset back to idle so the same quiz can be retried.
  void reset() {
    _status = QuizStatus.idle;
    _selectedOption = null;
    notifyListeners();
  }
}
