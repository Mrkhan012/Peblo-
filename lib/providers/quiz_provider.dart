import 'package:flutter/foundation.dart';

enum QuizStatus { idle, wrong, success }

class QuizProvider extends ChangeNotifier {
  QuizStatus _status = QuizStatus.idle;
  String? _selectedOption;
  int _shakeTick = 0;
  int _attemptCount = 0;
  bool _voicePlayed = false;
  int _correctCount = 0;
  int _completedCount = 0;
  int _firstTryCount = 0;
  int _currentQuestionAttempts = 0;

  QuizStatus get status => _status;
  String? get selectedOption => _selectedOption;
  int get shakeTick => _shakeTick;
  bool get isCorrect => _status == QuizStatus.success;
  int get attemptCount => _attemptCount;
  bool get voicePlayed => _voicePlayed;
  int get correctCount => _correctCount;
  int get completedCount => _completedCount;
  int get firstTryCount => _firstTryCount;

  void submit(String option, String correctAnswer) {
    _selectedOption = option;
    _attemptCount++;
    _currentQuestionAttempts++;
    _voicePlayed = false;

    if (option == correctAnswer) {
      _status = QuizStatus.success;
      _correctCount++;
      _completedCount++;
      if (_currentQuestionAttempts == 1) {
        _firstTryCount++;
      }
    } else {
      _status = QuizStatus.wrong;
      _shakeTick++;
    }
    notifyListeners();
  }

  void markVoicePlayed() {
    _voicePlayed = true;
    notifyListeners();
  }

  void resetForNewQuestion() {
    _status = QuizStatus.idle;
    _selectedOption = null;
    _shakeTick = 0;
    _attemptCount = 0;
    _voicePlayed = false;
    _currentQuestionAttempts = 0;
    notifyListeners();
  }

  void reset() {
    _status = QuizStatus.idle;
    _selectedOption = null;
    _shakeTick = 0;
    _attemptCount = 0;
    _voicePlayed = false;
    _correctCount = 0;
    _completedCount = 0;
    _firstTryCount = 0;
    _currentQuestionAttempts = 0;
    notifyListeners();
  }
}
