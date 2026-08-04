// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(
      varName: 'GEMINI_API_KEY', obfuscate: true) // Gemini AI Brain uchun
  static final String geminiApiKey = _Env.geminiApiKey;

  @EnviedField(
      varName: 'GOOGLE_CLOUD_API_KEY', obfuscate: true) // Text-to-Speech uchun
  static final String googleCloudKey = _Env.googleCloudKey;
}
