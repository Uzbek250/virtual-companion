import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:virtual_hamroh/features/providers/live_conversation_controller.dart';

/// Mimi bilan uzluksiz ovozli suhbatni boshlash/to'xtatish tugmasi.
/// Bosilganda mikrofon ochiladi va Gemini Live API bilan bevosita
/// audio-audio suhbat boshlanadi — matnli chat yo'q.
class LiveConversationButton extends ConsumerWidget {
  const LiveConversationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveConversationControllerProvider);
    final notifier = ref.read(liveConversationControllerProvider.notifier);

    final isActive = state.status == LiveConversationStatus.listening ||
        state.status == LiveConversationStatus.speaking ||
        state.status == LiveConversationStatus.connecting;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (isActive) {
            notifier.stopConversation();
          } else {
            notifier.startConversation();
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Semantics(
          label: _semanticLabel(state.status),
          button: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFor(state.status),
                color: _colorFor(state.status),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _displayText(state.status),
                style: TextStyle(
                  color: _colorFor(state.status),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(LiveConversationStatus status) {
    switch (status) {
      case LiveConversationStatus.idle:
        return Icons.mic_off;
      case LiveConversationStatus.connecting:
        return Icons.hourglass_empty;
      case LiveConversationStatus.listening:
        return Icons.mic;
      case LiveConversationStatus.speaking:
        return Icons.volume_up;
      case LiveConversationStatus.error:
        return Icons.warning;
    }
  }

  Color _colorFor(LiveConversationStatus status) {
    switch (status) {
      case LiveConversationStatus.idle:
        return Colors.grey[600]!;
      case LiveConversationStatus.connecting:
        return Colors.orange;
      case LiveConversationStatus.listening:
        return Colors.red;
      case LiveConversationStatus.speaking:
        return Colors.deepPurple;
      case LiveConversationStatus.error:
        return Colors.red;
    }
  }

  String _displayText(LiveConversationStatus status) {
    switch (status) {
      case LiveConversationStatus.idle:
        return 'SUHBATNI BOSHLASH';
      case LiveConversationStatus.connecting:
        return 'ULANMOQDA...';
      case LiveConversationStatus.listening:
        return 'ESHITYAPTI...';
      case LiveConversationStatus.speaking:
        return 'GAPIRYAPTI...';
      case LiveConversationStatus.error:
        return 'XATOLIK, QAYTA URINING';
    }
  }

  String _semanticLabel(LiveConversationStatus status) {
    switch (status) {
      case LiveConversationStatus.idle:
        return 'Ovozli suhbatni boshlash uchun bosing';
      case LiveConversationStatus.connecting:
        return 'Ulanmoqda, kuting';
      case LiveConversationStatus.listening:
        return 'Hozir eshitmoqda, to\'xtatish uchun bosing';
      case LiveConversationStatus.speaking:
        return 'Hamroh gapirmoqda';
      case LiveConversationStatus.error:
        return 'Xatolik yuz berdi, qayta urinish uchun bosing';
    }
  }
}
