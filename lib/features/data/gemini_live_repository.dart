import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:virtual_hamroh/env/env.dart';

part 'gemini_live_repository.g.dart';

/// Serverdan kelgan xabar turlari. UI shu orqali audio/matn/holatga
/// reaksiya beradi.
sealed class LiveServerEvent {}

/// Model gapirayotganda kelayotgan audio bo'lagi (24kHz, 16-bit PCM).
class LiveAudioChunk extends LiveServerEvent {
  LiveAudioChunk(this.bytes);
  final Uint8List bytes;
}

/// Model o'z navbatini tugatdi (gapirib bo'ldi).
class LiveTurnComplete extends LiveServerEvent {}

/// Foydalanuvchi gapira boshlagani uchun model o'z javobini to'xtatdi
/// (barge-in / interruption).
class LiveInterrupted extends LiveServerEvent {}

/// Ulanishda yoki oqim davomida xatolik yuz berdi.
class LiveError extends LiveServerEvent {
  LiveError(this.message);
  final String message;
}

/// Sessiya muvaffaqiyatli ochildi va audio yuborishga tayyor.
class LiveSetupComplete extends LiveServerEvent {}

/// Gemini Live API (BidiGenerateContent) bilan bitta suhbat sessiyasini
/// boshqaradi. Har chaqiriqda WebSocket orqali doimiy ulanish ochiladi,
/// mikrofondan kelgan PCM audio shu orqali yuboriladi, javob audiosi esa
/// stream sifatida qaytariladi.
///
/// Chat/HTTP repository'dan farqi: bu yerda tarix serverning o'zida
/// saqlanadi (sessiya davomida), Dart tomonda alohida xabar tarixi
/// yuritilmaydi.
class GeminiLiveRepository {
  GeminiLiveRepository();

  static const _model = 'gemini-3.1-flash-live-preview';

  // Ikkala Gemini kalit orasida almashtirish uchun — chat/TTS repository
  // bilan bir xil mantiq, lekin bu yerda alohida hisoblanadi, chunki Live
  // sessiya boshlanganda bitta kalitga "yopishib" qoladi (sessiya davomida
  // kalit almashtirilmaydi — WebSocket qayta ulanishni talab qiladi).
  int _keyIndex = 0;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _eventController = StreamController<LiveServerEvent>.broadcast();

  Stream<LiveServerEvent> get events => _eventController.stream;

  bool get isConnected => _channel != null;

  String get _nextKey {
    final key = Env.geminiApiKeys[_keyIndex % Env.geminiApiKeys.length];
    return key;
  }

  /// Sessiyani ochadi va setup xabarini yuboradi. `systemPrompt` — Mimi'ning
  /// xarakteri va hozirgi holati (mood, xotira) — chunki Live API ham
  /// stateless boshlanadi, shaxsiyat setup bosqichida beriladi.
  Future<void> connect({
    required String systemPrompt,
    required String voiceName,
  }) async {
    await disconnect();

    final apiKey = _nextKey;
    final uri = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/'
      'google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent'
      '?key=$apiKey',
    );

    final channel = WebSocketChannel.connect(uri);
    // Ulanish to'liq o'rnatilishini kutamiz — aks holda birinchi (setup)
    // xabar hali tayyor bo'lmagan socket'ga yuborilib, xatolikka olib
    // kelishi mumkin.
    await channel.ready;
    _channel = channel;

    final setupMessage = {
      'setup': {
        'model': 'models/$_model',
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {'voiceName': voiceName}
            }
          },
        },
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
      }
    };

    _subscription = channel.stream.listen(
      _handleServerMessage,
      onError: (Object error) {
        _eventController.add(LiveError(error.toString()));
      },
      onDone: () {
        _channel = null;
      },
    );

    channel.sink.add(jsonEncode(setupMessage));
  }

  void _handleServerMessage(dynamic raw) {
    try {
      final Map<String, dynamic> data =
          raw is String ? jsonDecode(raw) : jsonDecode(utf8.decode(raw as List<int>));

      if (data.containsKey('setupComplete')) {
        _eventController.add(LiveSetupComplete());
        return;
      }

      final serverContent = data['serverContent'] as Map<String, dynamic>?;
      if (serverContent == null) return;

      if (serverContent['interrupted'] == true) {
        _eventController.add(LiveInterrupted());
      }

      final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>?;
      final parts = modelTurn?['parts'] as List<dynamic>?;
      if (parts != null) {
        for (final part in parts) {
          final inlineData = part['inlineData'] as Map<String, dynamic>?;
          final base64Audio = inlineData?['data'] as String?;
          if (base64Audio != null) {
            _eventController.add(LiveAudioChunk(base64Decode(base64Audio)));
          }
        }
      }

      if (serverContent['turnComplete'] == true) {
        _eventController.add(LiveTurnComplete());
      }
    } catch (e) {
      _eventController.add(LiveError('Server xabarini o\'qishda xatolik: $e'));
    }
  }

  /// Mikrofondan olingan 16kHz PCM16 audio bo'lagini serverga yuboradi.
  void sendAudioChunk(Uint8List pcmBytes) {
    final channel = _channel;
    if (channel == null) return;

    final message = {
      'realtimeInput': {
        'audio': {
          'data': base64Encode(pcmBytes),
          'mimeType': 'audio/pcm;rate=16000',
        }
      }
    };
    channel.sink.add(jsonEncode(message));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}

@Riverpod(keepAlive: true)
GeminiLiveRepository geminiLiveRepository(GeminiLiveRepositoryRef ref) {
  final repo = GeminiLiveRepository();
  ref.onDispose(repo.dispose);
  return repo;
}
