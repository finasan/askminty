import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (Platform.isIOS) {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.interruptSpokenAudioAndMixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
      );

      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);

      // Pick an enhanced voice
      final voices = List<Map>.from(await _tts.getVoices);
      final best = voices.firstWhere(
            (v) {
          final locale = (v['locale'] ?? '').toString().toLowerCase();
          final id = (v['identifier'] ?? '').toString().toLowerCase();
          return locale.startsWith('en') && !id.contains('compact');
        },
        orElse: () => {'name': 'Samantha', 'locale': 'en-US'},
      );

      await _tts.setVoice({
        'name': best['name'],
        'locale': best['locale'],
      });

      await _tts.awaitSpeakCompletion(true);
    } else {
      // Android defaults are usually fine
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
    }

    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (!_initialized) await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
