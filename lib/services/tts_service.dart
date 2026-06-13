import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsStatus { idle, preparing, playing, completed, error, unavailable }

class TtsService {
  TtsService();

  final FlutterTts _tts = FlutterTts();
  TtsStatus _status = TtsStatus.idle;
  String? _lastError;
  Timer? _fallbackTimer;

  TtsStatus get status => _status;
  String? get lastError => _lastError;

  VoidCallback? onStart;
  VoidCallback? onCompletion;
  ValueChanged<String>? onError;

  bool _initialized = false;

  Future<bool> _checkEngineAvailable() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is List && engines.isNotEmpty) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final available = await _checkEngineAvailable();
      if (!available) {
        _status = TtsStatus.unavailable;
        _lastError = 'No TTS engine installed on this device.';
        onError?.call(_lastError!);
        return;
      }

      try {
        await _tts.setLanguage('en-US');
      } catch (_) {}
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);

      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}

      _tts.setStartHandler(() {
        _status = TtsStatus.playing;
        onStart?.call();
      });
      _tts.setCompletionHandler(() {
        _fallbackTimer?.cancel();
        _status = TtsStatus.completed;
        onCompletion?.call();
      });
      _tts.setErrorHandler((msg) {
        _fallbackTimer?.cancel();
        _status = TtsStatus.error;
        _lastError = msg;
        onError?.call(msg);
      });
      _tts.setCancelHandler(() {
        _fallbackTimer?.cancel();
        if (_status == TtsStatus.playing) {
          _status = TtsStatus.idle;
        }
      });

      _initialized = true;
    } catch (e) {
      _status = TtsStatus.error;
      _lastError = 'Failed to initialize TTS: $e';
      onError?.call(_lastError!);
    }
  }

  Future<void> speak(String text) async {
    try {
      _status = TtsStatus.preparing;
      _lastError = null;
      await _ensureInitialized();

      if (_status == TtsStatus.unavailable) {
        return;
      }

      await _tts.stop();
      final result = await _tts.speak(text);

      if (result == 1) {
        _status = TtsStatus.error;
        _lastError = 'TTS engine reported a failure.';
        onError?.call(_lastError!);
        return;
      }

      _fallbackTimer?.cancel();
      _fallbackTimer = Timer(const Duration(seconds: 30), () {
        if (_status == TtsStatus.playing) {
          _status = TtsStatus.completed;
          onCompletion?.call();
        }
      });
    } catch (e) {
      _fallbackTimer?.cancel();
      _status = TtsStatus.error;
      _lastError = e.toString();
      onError?.call(_lastError!);
    }
  }

  Future<void> stop() async {
    _fallbackTimer?.cancel();
    try {
      await _tts.stop();
    } catch (_) {}
    _status = TtsStatus.idle;
  }

  Future<void> speakFeedback(bool isCorrect) async {
    if (_status == TtsStatus.unavailable) return;
    final message = isCorrect
        ? 'Great job! That is correct!'
        : 'Oops! Try again, you can do it!';
    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {}
  }

  Future<void> dispose() async {
    _fallbackTimer?.cancel();
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
