import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/quiz_model.dart';
import '../models/story_model.dart';
import '../services/tts_service.dart';

enum StoryPhase {
  initial,
  loadingStory,
  storyReady,
  preparing,
  playing,
  completed,
  error,
}

class StoryProvider extends ChangeNotifier {
  StoryProvider() {
    _wireTtsCallbacks();
  }

  final TtsService _tts = TtsService();

  Story? _story;
  QuizQuestion? _quiz;
  StoryPhase _phase = StoryPhase.initial;
  String? _errorMessage;

  Story? get story => _story;
  QuizQuestion? get quiz => _quiz;
  StoryPhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  TtsService get tts => _tts;

  bool get isPlaying => _phase == StoryPhase.playing;
  bool get isPreparing =>
      _phase == StoryPhase.preparing || _phase == StoryPhase.loadingStory;
  bool get isCompleted => _phase == StoryPhase.completed;
  bool get isError => _phase == StoryPhase.error;
  bool get canPlay => _story != null && !isPlaying && !isPreparing;

  void _wireTtsCallbacks() {
    _tts.onStart = () {
      _phase = StoryPhase.playing;
      notifyListeners();
    };
    _tts.onCompletion = () {
      _phase = StoryPhase.completed;
      notifyListeners();
    };
    _tts.onError = (msg) {
      _phase = StoryPhase.error;
      _errorMessage = msg;
      notifyListeners();
    };
  }

  Future<void> loadInitial() async {
    if (_story != null) return;
    _phase = StoryPhase.loadingStory;
    _errorMessage = null;
    notifyListeners();
    try {
      final fetched = await MockDataSource.fetchStory();
      _story = fetched;
      _quiz = MockDataSource.fetchQuiz();
      _phase = StoryPhase.storyReady;
    } catch (e) {
      _phase = StoryPhase.error;
      _errorMessage = 'Could not load story: $e';
    }
    notifyListeners();
  }

  Future<void> playStory() async {
    final text = _story?.text;
    if (text == null) return;
    _errorMessage = null;
    _phase = StoryPhase.preparing;
    notifyListeners();
    await _tts.speak(text);
  }

  Future<void> retry() async {
    if (_story == null) {
      await loadInitial();
    } else {
      _errorMessage = null;
      _phase = StoryPhase.storyReady;
      notifyListeners();
      await playStory();
    }
  }

  Future<void> stopStory() => _tts.stop();

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }
}
