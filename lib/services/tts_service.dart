import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsStatus { idle, preparing, playing, completed, error }

class TtsService {
  TtsService();

  final FlutterTts _tts = FlutterTts();
  TtsStatus _status = TtsStatus.idle;
  String? _lastError;

  TtsStatus get status => _status;
  String? get lastError => _lastError;

  VoidCallback? onStart;
  VoidCallback? onCompletion;
  ValueChanged<String>? onError;

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);

      try {
        final voices = await _tts.getVoices;
        if (voices is List) {
          Map<String, String>? preferred;
          for (final v in voices) {
            if (v is Map) {
              final coerced = <String, String>{};
              v.forEach((k, val) {
                coerced[k.toString()] = val?.toString() ?? '';
              });
              final name = (coerced['name'] ?? '').toLowerCase();
              final locale = (coerced['locale'] ?? '').toLowerCase();
              final isEnglish = locale.startsWith('en');
              final isFriendly = name.contains('female') ||
                  name.contains('samantha') ||
                  name.contains('karen') ||
                  name.contains('google') ||
                  name.contains('natural');
              if (isEnglish && isFriendly) {
                preferred = coerced;
                break;
              }
              preferred ??= coerced;
            }
          }
          if (preferred != null) {
            await _tts.setVoice(preferred);
          }
        }
      } catch (_) {}

      _tts.setStartHandler(() {
        _status = TtsStatus.playing;
        onStart?.call();
      });
      _tts.setCompletionHandler(() {
        _status = TtsStatus.completed;
        onCompletion?.call();
      });
      _tts.setErrorHandler((msg) {
        _status = TtsStatus.error;
        _lastError = msg;
        onError?.call(msg);
      });
      _tts.setCancelHandler(() {
        if (_status == TtsStatus.playing) {
          _status = TtsStatus.idle;
        }
      });

      _initialized = true;
    } catch (e) {
      _status = TtsStatus.error;
      _lastError = 'Failed to initialize TTS: $e';
      rethrow;
    }
  }

  Future<void> speak(String text) async {
    try {
      _status = TtsStatus.preparing;
      _lastError = null;
      await _ensureInitialized();
      await _tts.stop();
      final result = await _tts.speak(text);
      if (result == 1) {
        _status = TtsStatus.error;
        _lastError = 'TTS engine reported a failure.';
        onError?.call(_lastError!);
      }
    } catch (e) {
      _status = TtsStatus.error;
      _lastError = e.toString();
      onError?.call(_lastError!);
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _status = TtsStatus.idle;
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
