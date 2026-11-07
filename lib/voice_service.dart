


import 'package:speech_to_text/speech_to_text.dart' as stt;


class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool isAvailable = false;
  String localeId = 'ru_RU';

  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function() onError,
  }) async {
    try {
      isAvailable = await _speech.initialize(
        onStatus: onStatus,
        onError: (_) => onError(),
      );

      if (isAvailable) {
        final locales = await _speech.locales();

        final kyrgyz = locales.where(
              (item) => item.localeId.toLowerCase().startsWith('ky'),
        );

        final russian = locales.where(
              (item) => item.localeId.toLowerCase().startsWith('ru'),
        );

        if (kyrgyz.isNotEmpty) {
          localeId = kyrgyz.first.localeId;
        } else if (russian.isNotEmpty) {
          localeId = russian.first.localeId;
        }
      }

      return isAvailable;
    } catch (_) {
      isAvailable = false;
      return false;
    }
  }

  Future<void> startListening({
    required void Function(String words, bool isFinal) onResult,
  }) async {
    if (!isAvailable) return;

    await _speech.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> dispose() async {
    await _speech.stop();
  }
}
