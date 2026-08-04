// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(
      varName: 'GEMINI_API_KEY', obfuscate: true) // Gemini AI Brain — 1-kalit
  static final String geminiApiKey1 = _Env.geminiApiKey1;

  @EnviedField(
      varName: 'GEMINI_API_KEY_2',
      obfuscate: true) // Gemini AI Brain — 2-kalit (limitni almashtirish uchun)
  static final String geminiApiKey2 = _Env.geminiApiKey2;

  /// Ikkala Gemini kaliti orasida almashtirish uchun ro'yxat.
  static List<String> get geminiApiKeys => [geminiApiKey1, geminiApiKey2];
}
