import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../domain/models/chat_models.dart';
import '../widgets/message_bubble.dart';

enum _ChatAction { acceptRent, cancelRent, endChat }

/// Conversación temporal entre rentero y rentador.
/// Al finalizarla se elimina para ambos.
class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  Stream<List<ChatMessage>>? _messageStream;

  @override
  void initState() {
    super.initState();
    _initStream(widget.chatId);
  }

  void _initStream(String chatId) {
    if (SupabaseService.instance.isUuid(chatId)) {
      _messageStream = SupabaseService.instance.streamMessages(chatId);
    } else {
      _messageStream = null;
    }
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      _initStream(widget.chatId);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    AppScope.read(context).sendMessage(widget.chatId, text);
    _input.clear();
    setState(() {});
  }

  Future<void> _endChat() async {
    final state = AppScope.read(context);
    final ok = await confirmDialog(
      context,
      title: 'Finalizar conversación',
      message:
          'La conversación y todos sus mensajes se eliminarán para ambas personas. Esta acción no se puede deshacer.',
      confirmLabel: 'Finalizar',
    );
    if (!ok || !mounted) return;
    popAndShowSnackBar(context, 'Conversación finalizada y eliminada',
        icon: Icons.delete_outline);
    state.endChat(widget.chatId);
  }

  Future<void> _acceptRent(String targetName) async {
    final state = AppScope.read(context);
    final chat = state.chatById(widget.chatId);
    final apt = chat == null ? null : state.apartmentById(chat.apartmentId);
    if (chat == null || apt == null) return;

    final ok = await confirmDialog(
      context,
      title: 'Aceptar renta',
      message:
          '¿Deseas aceptar la renta de "${apt.title}" a $targetName?\n\nRecuerda cambiar el estado del departamento a "Ocupado" si este ya se llenó.',
      confirmLabel: 'Aceptar renta',
    );
    if (!ok || !mounted) return;
    final done = state.registerStay(
      apartment: apt,
      renterId: chat.renterId,
      renterName: chat.renterName,
    );
    showAppSnackBar(
      context,
      done
          ? 'Renta aceptada. Recuerda cambiar el estado del departamento si ya se llenó.'
          : 'No se pudo aceptar la renta',
      icon: done ? Icons.check_circle : Icons.error_outline,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> _cancelRent(String targetName) async {
    final state = AppScope.read(context);
    final chat = state.chatById(widget.chatId);
    final apt = chat == null ? null : state.apartmentById(chat.apartmentId);
    if (chat == null) return;

    final ok = await confirmDialog(
      context,
      title: 'Cancelar renta',
      message:
          '¿Estás seguro de que deseas cancelar la renta de "${apt?.title ?? 'este departamento'}"? Se finalizará la estancia.',
      confirmLabel: 'Cancelar renta',
    );
    if (!ok || !mounted) return;
    final done = state.endStay(chat.apartmentId, renterId: chat.renterId);
    showAppSnackBar(
      context,
      done ? 'Renta cancelada' : 'No se pudo cancelar la renta',
      icon: done ? Icons.check_circle : Icons.error_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final chat = state.chatById(widget.chatId);

    if (chat == null || !chat.hasParticipant(state.profile.id)) {
      return const Scaffold(
        appBar: TitleAppBar(title: 'Conversación'),
        body: EmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Conversación finalizada',
          message: 'Esta conversación ya no existe.',
        ),
      );
    }

    final me = state.profile;
    final other = state.userById(chat.otherParticipantId(me.id));
    final otherName = chat.otherParticipantName(me.id).isNotEmpty
        ? chat.otherParticipantName(me.id)
        : (other?.name ?? 'Usuario');

    final apt = state.apartmentById(chat.apartmentId);
    final isOwner = me.id == chat.ownerId;
    final isRentActive =
        state.hasActiveStay(apartmentId: chat.apartmentId, renterId: chat.renterId);
    final canAccept =
        isOwner && !isRentActive && (apt == null || !apt.isInactive);

    return Scaffold(
      appBar: TitleAppBar(
        title: otherName,
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                otherName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: AppColors.serif,
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isRentActive)
              InkWell(
                onTap: () => _cancelRent(otherName),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel_outlined,
                          size: 13, color: Color(0xFFDC2626)),
                      SizedBox(width: 4),
                      Text(
                        'Cancelar renta',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (canAccept)
              InkWell(
                onTap: () => _acceptRent(otherName),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Aceptar renta',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<_ChatAction>(
            tooltip: 'Opciones',
            icon: const Icon(Icons.more_vert, color: AppColors.navy),
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            onSelected: (a) {
              switch (a) {
                case _ChatAction.acceptRent:
                  _acceptRent(otherName);
                case _ChatAction.cancelRent:
                  _cancelRent(otherName);
                case _ChatAction.endChat:
                  _endChat();
              }
            },
            itemBuilder: (_) => [
              if (isRentActive)
                const PopupMenuItem(
                  value: _ChatAction.cancelRent,
                  child: Text(
                    'Cancelar renta',
                    style: TextStyle(color: Color(0xFFDC2626)),
                  ),
                )
              else if (canAccept)
                const PopupMenuItem(
                  value: _ChatAction.acceptRent,
                  child: Text('Aceptar renta'),
                ),
              const PopupMenuItem(
                value: _ChatAction.endChat,
                child: Text('Finalizar conversación',
                    style: TextStyle(color: AppColors.orange)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          InkWell(
            onTap: apt == null
                ? null
                : () => Navigator.of(context)
                    .pushNamed(AppRoutes.apartmentDetail, arguments: apt),
            child: Container(
              width: double.infinity,
              color: AppColors.surfaceSoft,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.apartmentTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Chat temporal: al finalizarlo se elimina para ambos.',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (apt != null)
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_messageStream == null && SupabaseService.instance.isUuid(chat.id)) {
                  _initStream(chat.id);
                }

                return StreamBuilder<List<ChatMessage>>(
                  stream: _messageStream,
                  builder: (context, snapshot) {
                    final List<ChatMessage> displayMessages;
                    if (snapshot.hasData && snapshot.data != null) {
                      final remoteMessages = snapshot.data!;
                      // Combinar mensajes remotos con mensajes locales optimistas
                      final combined = <ChatMessage>[...remoteMessages];
                      for (final local in chat.messages) {
                        final exists = combined.any((m) =>
                            m.id == local.id ||
                            (m.text == local.text &&
                                m.senderId == local.senderId &&
                                m.sentAt.difference(local.sentAt).abs().inSeconds < 5));
                        if (!exists) {
                          combined.add(local);
                        }
                      }
                      combined.sort((a, b) => a.sentAt.compareTo(b.sentAt));
                      displayMessages = combined;
                    } else {
                      displayMessages = chat.messages;
                    }

                    final reversed = displayMessages.reversed.toList();

                    if (reversed.isEmpty) {
                      return const Center(
                        child: Text(
                          'Escribe el primer mensaje',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: reversed.length,
                      itemBuilder: (_, i) => MessageBubble(
                        message: reversed[i],
                        mine: reversed[i].senderId == me.id,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: AppColors.navy,
                    style: const TextStyle(fontSize: 15, color: AppColors.text),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle:
                          TextStyle(color: Color(0xFFA3ABB8), fontSize: 15),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.orange,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSend,
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.send_rounded,
                        color: Colors.white, size: 21),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
