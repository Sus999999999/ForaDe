import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../../auth/domain/models/user_role.dart';
import '../widgets/message_bubble.dart';

enum _ChatAction { registerStay, endStay, endChat }

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

  Future<void> _registerStay(String renterName) async {
    final state = AppScope.read(context);
    final chat = state.chatById(widget.chatId);
    final apt = chat == null ? null : state.apartmentById(chat.apartmentId);
    if (chat == null || apt == null) return;

    final ok = await confirmDialog(
      context,
      title: 'Registrar renta',
      message:
          '¿Registrar que $renterName rentó "${apt.title}" a partir de hoy? El departamento pasará a "No disponible" y la renta aparecerá en su historial.',
      confirmLabel: 'Registrar',
    );
    if (!ok || !mounted) return;
    final done = state.registerStay(apartment: apt, renterId: chat.renterId);
    showAppSnackBar(
      context,
      done ? 'Renta registrada' : 'No se pudo registrar la renta',
      icon: done ? Icons.check_circle : Icons.error_outline,
    );
  }

  Future<void> _endStay(String renterName) async {
    final state = AppScope.read(context);
    final chat = state.chatById(widget.chatId);
    if (chat == null) return;

    final ok = await confirmDialog(
      context,
      title: 'Finalizar renta',
      message:
          '¿Dar por terminada la estancia de $renterName? Se guardará en su historial con el tiempo hospedado y el departamento volverá a estar disponible.',
      confirmLabel: 'Finalizar',
    );
    if (!ok || !mounted) return;
    final done = state.endStay(chat.apartmentId);
    showAppSnackBar(
      context,
      done ? 'Renta finalizada' : 'No se pudo finalizar la renta',
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
    final otherName = other?.name ?? 'Usuario';

    // Acciones de renta: solo para el rentero dueño del departamento.
    final apt = state.apartmentById(chat.apartmentId);
    final isOwner = me.id == chat.ownerId && apt != null;
    final activeStay = apt == null ? null : state.activeStayOf(apt.id);
    final canRegister = isOwner &&
        other?.role == UserRole.rentador &&
        activeStay == null;
    final canEndStay =
        isOwner && activeStay != null && activeStay.renterId == chat.renterId;

    final reversed = chat.messages.reversed.toList();

    return Scaffold(
      appBar: TitleAppBar(
        title: otherName,
        actions: [
          PopupMenuButton<_ChatAction>(
            tooltip: 'Opciones',
            icon: const Icon(Icons.more_vert, color: AppColors.navy),
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            onSelected: (a) {
              switch (a) {
                case _ChatAction.registerStay:
                  _registerStay(otherName);
                case _ChatAction.endStay:
                  _endStay(otherName);
                case _ChatAction.endChat:
                  _endChat();
              }
            },
            itemBuilder: (_) => [
              if (canRegister)
                const PopupMenuItem(
                  value: _ChatAction.registerStay,
                  child: Text('Registrar renta'),
                ),
              if (canEndStay)
                const PopupMenuItem(
                  value: _ChatAction.endStay,
                  child: Text('Finalizar renta'),
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
          Container(
            width: double.infinity,
            color: AppColors.surfaceSoft,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Expanded(
            child: reversed.isEmpty
                ? const Center(
                    child: Text(
                      'Escribe el primer mensaje',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: reversed.length,
                    itemBuilder: (_, i) => MessageBubble(
                      message: reversed[i],
                      mine: reversed[i].senderId == me.id,
                    ),
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
