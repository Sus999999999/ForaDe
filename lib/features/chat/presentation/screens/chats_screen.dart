import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../domain/models/chat_models.dart';
import '../widgets/conversation_tile.dart';

enum _Box { all, sent, received }

/// Contactos: mensajes enviados y recibidos, cada uno asociado a un
/// departamento. Al abrir uno se ve la conversación y desde ahí el detalle
/// del departamento.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  _Box _box = _Box.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppScope.read(context).refreshChats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final List<ChatConversation> chats = switch (_box) {
      _Box.all => state.myChats,
      _Box.sent => state.sentChats,
      _Box.received => state.receivedChats,
    };

    return Scaffold(
      appBar: const TitleAppBar(title: 'Mensajes'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final b in _Box.values)
                  ChoiceChip(
                    label: Text(switch (b) {
                      _Box.all => 'Todos',
                      _Box.sent => 'Enviados',
                      _Box.received => 'Recibidos',
                    }),
                    selected: _box == b,
                    onSelected: (_) => setState(() => _box = b),
                    showCheckmark: false,
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.orange.withValues(alpha: 0.14),
                    side: BorderSide(
                      color:
                          _box == b ? AppColors.orange : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _box == b ? AppColors.orange : AppColors.text,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.orange,
              onRefresh: () => AppScope.read(context).refreshChats(),
              child: chats.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: 'No tienes conversaciones',
                          message:
                              'Contacta a un publicador desde un departamento para iniciar una conversación. Las conversaciones se sincronizan en tiempo real.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: AppColors.divider),
                      itemBuilder: (_, i) => ConversationTile(
                        chat: chats[i],
                        onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.chat,
                            arguments: chats[i].id),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
