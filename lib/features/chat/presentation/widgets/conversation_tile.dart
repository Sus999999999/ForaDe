import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/models/chat_models.dart';
import 'message_bubble.dart';

/// Fila de un contacto (conversación): persona, departamento asociado,
/// último mensaje y si fue enviado o recibido.
class ConversationTile extends StatelessWidget {
  final ChatConversation chat;
  final VoidCallback onTap;
  const ConversationTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final me = state.profile;
    final other = state.userById(chat.otherParticipantId(me.id));
    final name = chat.otherParticipantName(me.id).isNotEmpty
        ? chat.otherParticipantName(me.id)
        : (other?.name ?? 'Usuario');
    final avatarUrl = chat.otherParticipantAvatar(me.id).isNotEmpty
        ? chat.otherParticipantAvatar(me.id)
        : (other?.avatarUrl ?? '');
    final last = chat.lastMessage;
    final sent = chat.renterId == me.id;
    final preview = last == null
        ? 'Sin mensajes'
        : '${last.senderId == me.id ? 'Tú: ' : ''}${last.text}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            UserAvatar(
              avatarUrl: avatarUrl,
              name: name,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (last != null)
                        Text(
                          chatTimeLabel(last.sentAt),
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.muted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sent ? 'Enviado' : 'Recibido'} · ${chat.apartmentTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
