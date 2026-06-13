import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS service wrapping flutter_tts with a clean async API and
/// proper completion / error callbacks.
///
/// We expose a state enum + callback hooks so the provider layer
/// can drive UI without leaking flutter_tts-specific types.
enum TtsStatus { idle, preparing, playing, completed, error }

class TtsService {
  TtsService();

  final FlutterTts _tts = FlutterTts();
  TtsStatus _status = TtsStatus.idle;
  String? _lastError;

  TtsStatus get status => _status;
  String? get lastError => _lastError;

  // Callbacks. Decoupled from flutter_tts so the rest of the app
  // doesn't import this package directly.
  VoidCallback? onStart;
  VoidCallback? onCompletion;
  ValueChanged<String>? onError;

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      // Slightly slower, kid-friendly pace.
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);

      // Try a friendly English voice if available; fall back to default.
      try {
        final voices = await _tts.getVoices;
        if (voices is List) {
          // Coerce each voice map to Map<String, String> as required
          // by setVoice, and prefer one that sounds kid-friendly.
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
              preferred ??= coerced; // remember first English voice as fallback
            }
          }
          if (preferred != null) {
            await _tts.setVoice(preferred);
          }
        }
      } catch (_) {
        // Voice selection is best-effort; ignore.
      }

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

  /// Begin speaking [text]. Returns once playback is triggered.
  /// The completion / error callbacks fire asynchronously.
  Future<void> speak(String text) async {
    try {
      _status = TtsStatus.preparing;
      _lastError = null;
      await _ensureInitialized();
      await _tts.stop();
      final result = await _tts.speak(text);
      // On some platforms, `speak` returns 0 on success, 1 on error.
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
    } catch (_) {/* noop */}
    _status = TtsStatus.idle;
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {/* noop */}
  }
}
