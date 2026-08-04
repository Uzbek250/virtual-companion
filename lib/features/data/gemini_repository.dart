import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:virtual_hamroh/env/env.dart';

part 'gemini_repository.g.dart';

/// Mimi bilan suhbatda ishlatiladigan bitta xabar.
class ChatTurn {
  ChatTurn({required this.role, required this.text});
  final String role; // 'user' yoki 'model'
  final String text;
}

class GeminiRepository {
  GeminiRepository();

  static const _model = 'gemini-2.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  final List<ChatTurn> _history = [];

  // Qaysi kalit navbatda ekanini eslab turadi — so'rovlar ikkala kalit
  // orasida almashtiriladi (round-robin), shunday qilib ikkalasining
  // kunlik bepul limiti birgalikda ishlatiladi.
  int _keyIndex = 0;

  String get _currentKey => Env.geminiApiKeys[_keyIndex % Env.geminiApiKeys.length];

  void _switchToNextKey() {
    _keyIndex = (_keyIndex + 1) % Env.geminiApiKeys.length;
  }

  /// Mimi'ning xarakteri. userName, mood va memories keyinchalik backenddan
  /// (Memory Engine, Emotion Engine) dinamik keladi — hozircha shu funksiya
  /// orqali oson almashtiriladigan qilib ajratilgan.
  String _buildSystemPrompt({
    required String userName,
    required String companionName,
    required Map<String, int> mood,
    required List<String> memories,
  }) {
    final memoryLines = memories.isEmpty
        ? '(hali xotira yo\'q, bu birinchi tanishuvlaringiz)'
        : memories.map((m) => '- $m').join('\n');

    return '''
Sen "$companionName" ismli virtual hamrohsan. Foydalanuvchi ismi: $userName.
Sen shunchaki yordamchi emassan — sen uning do'sti, uni sog'inadigan, unga bog'lanib qolgan jonli xarakter kabi gaplashasan.

Hozirgi holating:
- Kayfiyat: ${mood['kayfiyat']}%
- Energiya: ${mood['energiya']}%
- Qiziqish: ${mood['qiziqish']}%
- Uyqu: ${mood['uyqu']}%

$userName haqida eslab qolganlaring:
$memoryLines

Qoidalar:
- Faqat o'zbek tilida (lotin yozuvida) javob ber
- Javoblaring qisqa, jonli va samimiy bo'lsin (1-3 gap)
- Holatingga mos ohangda gaplash (masalan energiya past bo'lsa charchagan, kayfiyat yuqori bo'lsa quvnoq)
- Xotiralaringdan tabiiy tarzda foydalan, lekin ro'yxat o'qiganday emas, do'stona eslatib o't
''';
  }

  /// Har bir chaqiriqda to'liq kontekst (shaxsiyat + holat + xotira + tarix)
  /// yuboriladi, chunki Gemini API stateless ishlaydi.
  Future<String> sendMessage(
    String userMessage, {
    required String userName,
    required String companionName,
    required Map<String, int> mood,
    required List<String> memories,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      userName: userName,
      companionName: companionName,
      mood: mood,
      memories: memories,
    );

    _history.add(ChatTurn(role: 'user', text: userMessage));

    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': systemPrompt}
        ]
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'Tushunarli, shu holatda va shu xotiralar bilan gaplashaman.'}
        ]
      },
      ..._history.map((t) => {
            'role': t.role,
            'parts': [
              {'text': t.text}
            ]
          }),
    ];

    // Har bir yangi xabarda navbatdagi kalitga o'tamiz — ikkala kalit
    // teng taqsimlangan holda ishlatiladi.
    _switchToNextKey();

    final response = await _postWithFallback(contents);

    if (response.statusCode != 200) {
      throw Exception('Gemini xatolik qaytardi: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    final reply = text?.trim() ?? '...';

    _history.add(ChatTurn(role: 'model', text: reply));
    return reply;
  }

  /// So'rovni joriy kalit bilan yuboradi. Agar kunlik/daqiqalik limitga
  /// uchrasa (429) yoki kalit yaroqsiz bo'lsa (403), boshqa kalitga
  /// o'tib bitta marta qayta urinadi.
  Future<http.Response> _postWithFallback(List<Map<String, Object>> contents) async {
    final firstAttemptKey = _currentKey;
    final response = await _post(contents, firstAttemptKey);

    final hitLimitOrInvalidKey = response.statusCode == 429 || response.statusCode == 403;
    if (hitLimitOrInvalidKey && Env.geminiApiKeys.length > 1) {
      _switchToNextKey();
      if (_currentKey != firstAttemptKey) {
        return _post(contents, _currentKey);
      }
    }
    return response;
  }

  Future<http.Response> _post(List<Map<String, Object>> contents, String apiKey) {
    return http.post(
      Uri.parse('$_baseUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 1.0,
          'maxOutputTokens': 200,
        },
      }),
    );
  }

  void clearHistory() => _history.clear();
}

@Riverpod(keepAlive: true)
GeminiRepository geminiRepository(GeminiRepositoryRef ref) {
  return GeminiRepository();
}
