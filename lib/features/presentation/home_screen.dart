import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:virtual_hamroh/features/presentation/animation_screen.dart';
import 'package:virtual_hamroh/features/presentation/live_conversation_button.dart';
import 'package:virtual_hamroh/features/providers/companion_state_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companion = ref.watch(companionStateControllerProvider);
    final notifier = ref.read(companionStateControllerProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          // Kun vaqtiga mos fon gradienti
          Positioned.fill(child: _RoomBackground()),

          AnimationScreen(),

          // Yuqori: kayfiyat/energiya/qiziqish/uyqu — glass status panel
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: _StatusPanel(companion: companion),
          ),

          // Pastki: harakatlar paneli
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _ActionBar(
              onFeed: notifier.feed,
              onPlay: notifier.play,
            ),
          ),

          // Ovoz bilan gaplashish tugmasi (Live API)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(child: LiveConversationButton()),
          ),
        ],
      ),
    );
  }
}

class _RoomBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final isEvening = hour < 6 || hour >= 18;
    final colors = isEvening
        ? [const Color(0xFF3B2E58), const Color(0xFF6B4E8E)]
        : [const Color(0xFFFCE7D9), const Color(0xFFF6C9A0)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.companion});
  final CompanionState companion;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    companion.companionName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${companion.relationship.emoji} ${companion.relationship.label}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MoodBar('Kayfiyat', companion.kayfiyat, Colors.pinkAccent),
              _MoodBar('Energiya', companion.energiya, Colors.amberAccent),
              _MoodBar('Qiziqish', companion.qiziqish, Colors.lightBlueAccent),
              _MoodBar('Uyqu', companion.uyqu, Colors.purpleAccent),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodBar extends StatelessWidget {
  const _MoodBar(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onFeed, required this.onPlay});
  final VoidCallback onFeed;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(emoji: '🍎', label: 'Ovqatlantirish', onTap: onFeed),
              _ActionButton(emoji: '🎮', label: 'O\'ynash', onTap: onPlay),
              _ActionButton(emoji: '🎁', label: 'Sovg\'a', onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.emoji, required this.label, required this.onTap});
  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
