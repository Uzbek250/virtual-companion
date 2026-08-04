import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'companion_state_controller.g.dart';

/// Munosabat darajasi — suhbatlar va vaqtga qarab o'sadi.
enum RelationshipLevel {
  yangiTanish('Yangi tanish', '🌱'),
  dost('Do\'st', '🙂'),
  yaqinDost('Yaqin do\'st', '🤝'),
  engYaqinHamroh('Eng yaqin hamroh', '💙');

  const RelationshipLevel(this.label, this.emoji);
  final String label;
  final String emoji;
}

class CompanionState {
  const CompanionState({
    this.userName = '',
    this.companionName = 'Mimi',
    this.kayfiyat = 70,
    this.energiya = 80,
    this.qiziqish = 60,
    this.uyqu = 90,
    this.relationship = RelationshipLevel.yangiTanish,
    this.totalInteractions = 0,
    this.memories = const [],
  });

  final String userName;
  final String companionName;
  final int kayfiyat;
  final int energiya;
  final int qiziqish;
  final int uyqu;
  final RelationshipLevel relationship;
  final int totalInteractions;
  final List<String> memories;

  Map<String, int> get moodMap => {
        'kayfiyat': kayfiyat,
        'energiya': energiya,
        'qiziqish': qiziqish,
        'uyqu': uyqu,
      };

  CompanionState copyWith({
    String? userName,
    String? companionName,
    int? kayfiyat,
    int? energiya,
    int? qiziqish,
    int? uyqu,
    RelationshipLevel? relationship,
    int? totalInteractions,
    List<String>? memories,
  }) {
    return CompanionState(
      userName: userName ?? this.userName,
      companionName: companionName ?? this.companionName,
      kayfiyat: (kayfiyat ?? this.kayfiyat).clamp(0, 100),
      energiya: (energiya ?? this.energiya).clamp(0, 100),
      qiziqish: (qiziqish ?? this.qiziqish).clamp(0, 100),
      uyqu: (uyqu ?? this.uyqu).clamp(0, 100),
      relationship: relationship ?? this.relationship,
      totalInteractions: totalInteractions ?? this.totalInteractions,
      memories: memories ?? this.memories,
    );
  }
}

// NOTE: Hozircha holat faqat xotirada (in-memory) saqlanadi va ilova
// qayta ochilganda tiklanmaydi. Backend ulanganda bu qism Supabase/API
// bilan almashtiriladi — shu sabab CompanionState immutable va aniq
// tuzilgan qilib yozilgan, keyin osongina serialize/deserialize qilinadi.
@riverpod
class CompanionStateController extends _$CompanionStateController {
  @override
  CompanionState build() => const CompanionState();

  void setNames({required String userName, required String companionName}) {
    state = state.copyWith(userName: userName, companionName: companionName);
  }

  void feed() {
    state = state.copyWith(
      energiya: state.energiya + 20,
      kayfiyat: state.kayfiyat + 5,
    );
    _afterInteraction();
  }

  void play() {
    state = state.copyWith(
      qiziqish: state.qiziqish + 20,
      energiya: state.energiya - 10,
      kayfiyat: state.kayfiyat + 10,
    );
    _afterInteraction();
  }

  void chat() {
    state = state.copyWith(kayfiyat: state.kayfiyat + 3);
    _afterInteraction();
  }

  void addMemory(String fact) {
    if (state.memories.contains(fact)) return;
    state = state.copyWith(memories: [...state.memories, fact]);
  }

  void _afterInteraction() {
    final count = state.totalInteractions + 1;
    RelationshipLevel level = state.relationship;
    if (count >= 100) {
      level = RelationshipLevel.engYaqinHamroh;
    } else if (count >= 40) {
      level = RelationshipLevel.yaqinDost;
    } else if (count >= 10) {
      level = RelationshipLevel.dost;
    }
    state = state.copyWith(totalInteractions: count, relationship: level);
  }
}
