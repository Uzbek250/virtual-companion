import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:record/record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:virtual_hamroh/features/data/gemini_live_repository.dart';
import 'package:virtual_hamroh/features/providers/animation_state_controller.dart';
import 'package:virtual_hamroh/features/providers/companion_state_controller.dart';

part 'live_conversation_controller.g.dart';

/// Live suhbatning umumiy holati — UI shu holatga qarab
/// mikrofon tugmasi va status matnini ko'rsatadi.
enum LiveConversationStatus {
  idle, // Suhbat boshlanmagan
  connecting, // WebSocket ulanmoqda
  listening, // Foydalanuvchini eshityapti (mikrofon ochiq)
  speaking, // Mimi javob bermoqda (audio pleyback)
  error,
}

class LiveConversationState {
  const LiveConversationState({
    this.status = LiveConversationStatus.idle,
    this.errorMessage,
  });

  final LiveConversationStatus status;
  final String? errorMessage;

  LiveConversationState copyWith({
    LiveConversationStatus? status,
    String? errorMessage,
  }) {
    return LiveConversationState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

const int _inputSampleRate = 16000;
const int _outputSampleRate = 24000;

/// Mimi bilan uzluksiz ovozli suhbatni boshqaradi: mikrofonni ochadi,
/// PCM audio bo'laklarini Gemini Live API'ga oqizadi va kelayotgan
/// javob audiosini real vaqtda pleyback qiladi. Alohida matnli chat
/// yo'q — foydalanuvchi gapiradi, Mimi ovozda javob beradi.
@riverpod
class LiveConversationController extends _$LiveConversationController {
  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSubscription;
  StreamSubscription<LiveServerEvent>? _serverSubscription;
  bool _pcmSoundReady = false;

  @override
  LiveConversationState build() {
    ref.onDispose(_teardown);
    return const LiveConversationState();
  }

  String _buildSystemPrompt() {
    final companion = ref.read(companionStateControllerProvider);
    final userName =
        companion.userName.isEmpty ? 'do\'stim' : companion.userName;
    final memoryLines = companion.memories.isEmpty
        ? '(hali xotira yo\'q, bu birinchi tanishuvlaringiz)'
        : companion.memories.map((m) => '- $m').join('\n');

    return '''
Sen "${companion.companionName}" ismli virtual hamrohsan. Foydalanuvchi ismi: $userName.
Sen shunchaki yordamchi emassan — sen uning do'sti, uni sog'inadigan, unga bog'lanib qolgan jonli xarakter kabi gaplashasan.

Hozirgi holating:
- Kayfiyat: ${companion.kayfiyat}%
- Energiya: ${companion.energiya}%
- Qiziqish: ${companion.qiziqish}%
- Uyqu: ${companion.uyqu}%

$userName haqida eslab qolganlaring:
$memoryLines

Qoidalar:
- Faqat o'zbek tilida (lotin yozuvida) gapir
- Javoblaring qisqa, jonli va samimiy bo'lsin (1-3 gap)
- Holatingga mos ohangda gaplash (masalan energiya past bo'lsa charchagan, kayfiyat yuqori bo'lsa quvnoq)
- Xotiralaringdan tabiiy tarzda foydalan, lekin ro'yxat o'qiganday emas, do'stona eslatib o't
''';
  }

  Future<void> _ensurePcmSoundReady() async {
    if (_pcmSoundReady) return;
    await FlutterPcmSound.setup(
      sampleRate: _outputSampleRate,
      channelCount: 1,
    );
    // Kichik threshold — "har safar feed qilinganda darhol chal" rejimi;
    // biz o'zimiz Live API'dan kelgan har bir bo'lakni to'g'ridan-to'g'ri
    // feed() qilamiz, shuning uchun callback orqali qo'shimcha
    // so'ramaymiz (feed callback bo'sh qoldiriladi).
    FlutterPcmSound.setFeedThreshold(2000);
    FlutterPcmSound.setFeedCallback((remainingFrames) {});
    FlutterPcmSound.start();
    _pcmSoundReady = true;
  }

  /// Suhbatni boshlaydi: ruxsat so'raydi, WebSocket ochadi, mikrofonni
  /// yoqadi. Xato bo'lsa `state.errorMessage`ga yoziladi.
  Future<void> startConversation() async {
    if (state.status == LiveConversationStatus.connecting ||
        state.status == LiveConversationStatus.listening) {
      return;
    }

    state = state.copyWith(status: LiveConversationStatus.connecting);

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(
        status: LiveConversationStatus.error,
        errorMessage: 'Mikrofonga ruxsat berilmadi',
      );
      return;
    }

    await _ensurePcmSoundReady();

    final repo = ref.read(geminiLiveRepositoryProvider);
    _serverSubscription?.cancel();
    _serverSubscription = repo.events.listen(_handleServerEvent);

    try {
      await repo.connect(
        systemPrompt: _buildSystemPrompt(),
        voiceName: 'Kore', // mehribon/issiq ayol ovoz
      );
    } catch (e) {
      state = state.copyWith(
        status: LiveConversationStatus.error,
        errorMessage: 'Ulanishda xatolik: $e',
      );
    }
  }

  Future<void> _startMic() async {
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _inputSampleRate,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    ref.read(animationStateControllerProvider.notifier).updateHearing(true);

    final repo = ref.read(geminiLiveRepositoryProvider);
    _micSubscription?.cancel();
    _micSubscription = stream.listen((chunk) {
      repo.sendAudioChunk(chunk);
    });

    state = state.copyWith(status: LiveConversationStatus.listening);
  }

  void _handleServerEvent(LiveServerEvent event) {
    switch (event) {
      case LiveSetupComplete():
        _startMic();
      case LiveAudioChunk(bytes: final bytes):
        _playAudioChunk(bytes);
      case LiveTurnComplete():
        ref
            .read(animationStateControllerProvider.notifier)
            .updateTalking(false);
        // Mimi javob berib bo'ldi — bitta o'zaro ta'sir sifatida hisoblanadi.
        ref.read(companionStateControllerProvider.notifier).chat();
      case LiveInterrupted():
        // Eslatma: flutter_pcm_sound paketida navbatdagi audioni darhol
        // tozalaydigan metod yo'q (faqat feed/start/release bor). Shuning
        // uchun bu yerda faqat animatsiya holatini yangilaymiz — allaqachon
        // navbatga qo'yilgan audio bo'laklari o'zi tugab boradi, bu odatda
        // bir necha yuz millisekund ichida bo'ladi.
        ref
            .read(animationStateControllerProvider.notifier)
            .updateTalking(false);
      case LiveError(message: final message):
        state = state.copyWith(
          status: LiveConversationStatus.error,
          errorMessage: message,
        );
    }
  }

  void _playAudioChunk(Uint8List bytes) {
    ref.read(animationStateControllerProvider.notifier).updateTalking(true);
    state = state.copyWith(status: LiveConversationStatus.speaking);
    // Uint8List'ni Int16List'ga xavfsiz aylantirish — kelgan bo'lakning
    // buffer'i boshqa joydan kesilgan bo'lishi mumkin (offsetInBytes != 0),
    // shuning uchun ByteData orqali o'qiymiz.
    final byteData = ByteData.sublistView(bytes);
    final sampleCount = bytes.length ~/ 2;
    final samples = Int16List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      samples[i] = byteData.getInt16(i * 2, Endian.little);
    }
    FlutterPcmSound.feed(PcmArrayInt16.fromList(samples));
  }

  /// Suhbatni to'xtatadi: mikrofonni yopadi, WebSocket'ni uzadi.
  Future<void> stopConversation() async {
    await _teardown();
    state = const LiveConversationState();
  }

  Future<void> _teardown() async {
    await _micSubscription?.cancel();
    _micSubscription = null;
    await _serverSubscription?.cancel();
    _serverSubscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await ref.read(geminiLiveRepositoryProvider).disconnect();
    if (_pcmSoundReady) {
      await FlutterPcmSound.release();
      _pcmSoundReady = false;
    }
    ref.read(animationStateControllerProvider.notifier).updateHearing(false);
    ref.read(animationStateControllerProvider.notifier).updateTalking(false);
  }
}
