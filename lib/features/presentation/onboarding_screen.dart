import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:virtual_hamroh/features/presentation/home_screen.dart';
import 'package:virtual_hamroh/features/providers/companion_state_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _userNameController = TextEditingController();
  final _companionNameController = TextEditingController();

  void _next() {
    if (_step == 0 && _userNameController.text.trim().isEmpty) return;
    if (_step == 2 && _companionNameController.text.trim().isEmpty) return;

    if (_step < 2) {
      setState(() => _step++);
    } else {
      ref.read(companionStateControllerProvider.notifier).setNames(
            userName: _userNameController.text.trim(),
            companionName: _companionNameController.text.trim(),
          );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6C9A0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: (_step + 1) / 3,
                backgroundColor: Colors.white.withOpacity(0.4),
                color: Colors.white,
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
              ),
              const Spacer(),
              if (_step == 0) ...[
                const Text('Salom! Ismingiz nima?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _NameField(controller: _userNameController, hint: 'Ismingiz'),
              ] else if (_step == 1) ...[
                const Text('Hamrohingizni tanlang',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _CompanionCard(emoji: '🐻', label: 'Ayiqcha', selected: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _CompanionCard(emoji: '✨', label: 'Tez orada', selected: false)),
                  ],
                ),
              ] else ...[
                const Text('Hamrohingizga qanday ism beramiz?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _NameField(controller: _companionNameController, hint: 'Masalan: Mimi'),
              ],
              const Spacer(),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Davom etish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({required this.emoji, required this.label, required this.selected});
  final String emoji;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(selected ? 0.7 : 0.3),
        borderRadius: BorderRadius.circular(20),
        border: selected ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
