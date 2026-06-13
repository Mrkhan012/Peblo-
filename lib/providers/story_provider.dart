import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/quiz_model.dart';
import '../models/story_model.dart';
import '../services/tts_service.dart';

/// Lifecycle of the audio-playback → quiz-reveal flow.
enum StoryPhase {
  initial, // haven't pressed play yet
  loadingStory, // fetching story content
  storyReady, // story text shown, TTS not yet triggered
  preparing, // TTS is initializing / preparing
  playing, // TTS is narrating
  completed, // TTS finished, quiz will appear
  error, // something failed
}

/// State container for story playback + quiz reveal.
///
/// Why Provider? It is one of the three explicitly-listed options
/// in the brief (Provider / Riverpod / BLoC). Provider is the
/// lightest of the three — perfect for a mid-range Android device
/// where we want to minimize framework overhead. ChangeNotifier
/// makes "audio state changed → rebuild only the audio-aware
/// widgets" trivial via `Selector` / `Consumer`.
class StoryProvider extends ChangeNotifier {
  StoryProvider() {
    _wireTtsCallbacks();
  }

  // -------------------------------------------------------------------
  // Internal services / data
  // -------------------------------------------------------------------
  final TtsService _tts = TtsService();

  Story? _story;
  QuizQuestion? _quiz;
  StoryPhase _phase = StoryPhase.initial;
  String? _errorMessage;

  // -------------------------------------------------------------------
  // Public read-only state
  // -------------------------------------------------------------------
  Story? get story => _story;
  QuizQuestion? get quiz => _quiz;
  StoryPhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  TtsService get tts => _tts;

  // -------------------------------------------------------------------
  // Phase helpers used by the UI
  // -------------------------------------------------------------------
  bool get isPlaying => _phase == StoryPhase.playing;
  bool get isPreparing =>
      _phase == StoryPhase.preparing || _phase == StoryPhase.loadingStory;
  bool get isCompleted => _phase == StoryPhase.completed;
  bool get isError => _phase == StoryPhase.error;
  bool get canPlay => _story != null && !isPlaying && !isPreparing;

  // -------------------------------------------------------------------
  // Wire TTS callbacks once
  // -------------------------------------------------------------------
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

  // -------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------

  /// Load the story on first mount. The mock simulates a tiny
  /// network delay to demonstrate the loading state. Real backend
  /// would call the API via http here.
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

  /// Begin narration. The transition to `completed` happens
  /// inside the TTS completion callback, and is what triggers
  /// the quiz reveal in the UI.
  Future<void> playStory() async {
    final text = _story?.text;
    if (text == null) return;
    _errorMessage = null;
    _phase = StoryPhase.preparing;
    notifyListeners();
    await _tts.speak(text);
  }

  /// Retry after a failure — both for TTS errors and story load errors.
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

  /// Stop narration (e.g. user backgrounds the app).
  Future<void> stopStory() => _tts.stop();

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }
}
