import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../widgets/message_bubble.dart';

/// Lista de conversaciones temporales del usuario.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final chats = state.myChats;
    final me = state.profile;

    return Scaffold(
      appBar: const TitleAppBar(title: 'Mensajes'),
      body: chats.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No tienes conversaciones',
              message:
                  'Contacta a un rentero desde un departamento para iniciar un chat. Los chats se eliminan al finalizarlos.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: chats.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: AppColors.divider),
              itemBuilder: (_, i) {
                final c = chats[i];
                final other = state.userById(c.otherParticipantId(me.id));
                final name = other?.name ?? 'Usuario';
                final last = c.lastMessage;
                final preview = last == null
                    ? 'Sin mensajes'
                    : '${last.senderId == me.id ? 'Tú: ' : ''}${last.text}';

                return InkWell(
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.chat, arguments: c.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.uploadFill,
                          child: Text(
                            name.isEmpty ? '?' : name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
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
                                          fontSize: 11.5,
                                          color: AppColors.muted),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.apartmentTitle,
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
              },
            ),
    );
  }
}
