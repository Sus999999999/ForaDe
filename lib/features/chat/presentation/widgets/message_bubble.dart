import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/chat_models.dart';

/// Hora si es de hoy; "5 mar · 14:05" si es de otro día.
String chatTimeLabel(DateTime t) {
  final now = DateTime.now();
  final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
  if (sameDay) return formatTime(t);
  return '${t.day} ${formatDate(t).split(' ')[1]} · ${formatTime(t)}';
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  const MessageBubble({super.key, required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy : AppColors.surfaceSoft,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: mine ? Colors.white : AppColors.text,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              chatTimeLabel(message.sentAt),
              style: TextStyle(
                fontSize: 10.5,
                color: mine ? const Color(0xFFC7D2E5) : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
