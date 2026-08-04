import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:virtual_hamroh/features/data/gemini_repository.dart';
import 'package:virtual_hamroh/features/providers/companion_state_controller.dart';

part 'gemini_response_controller.g.dart';

@riverpod
class GeminiResponseController extends _$GeminiResponseController {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  void getResponse(String userMessage) async {
    final geminiRepository = ref.read(geminiRepositoryProvider);
    final companion = ref.read(companionStateControllerProvider);

    state = const AsyncValue.loading();

    final responseValue = await AsyncValue.guard(() async {
      return geminiRepository.sendMessage(
        userMessage,
        userName: companion.userName.isEmpty ? 'do\'stim' : companion.userName,
        companionName: companion.companionName,
        mood: companion.moodMap,
        memories: companion.memories,
      );
    });

    // Har bir suhbat munosabatni sekin rivojlantiradi
    ref.read(companionStateControllerProvider.notifier).chat();

    state = responseValue;
  }
}
