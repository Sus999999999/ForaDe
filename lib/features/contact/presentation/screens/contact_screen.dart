import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/host_info.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/presentation/widgets/apartment_image.dart';

class ContactScreen extends StatefulWidget {
  final Apartment apartment;
  const ContactScreen({super.key, required this.apartment});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _message = TextEditingController();
  bool _sharePhone = false;
  bool _showErrors = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _showErrors = true);
    if (_message.text.trim().isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();
    final state = AppScope.read(context);
    final chat = await state.openChat(widget.apartment);
    if (chat == null || !mounted) {
      if (mounted) setState(() => _isSubmitting = false);
      showAppSnackBar(
          context, 'No puedes contactar al publicador de este departamento',
          icon: Icons.error_outline);
      return;
    }

    // El remitente y la fecha se asignan solos (usuario actual y hora de envío).
    // El teléfono solo se comparte si la persona lo decide.
    final phone = state.profile.phone.trim();
    final text = _sharePhone && phone.isNotEmpty
        ? '${_message.text.trim()}\n\nMi teléfono: $phone'
        : _message.text.trim();
    await state.sendMessage(chat.id, text);

    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(AppRoutes.chat, arguments: chat.id);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.apartment;
    return Scaffold(
      appBar: const TitleAppBar(title: 'Contactar'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: ApartmentImage(
                        seed: a.id, iconSize: 28, radius: 4),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.location,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatPrice(a.price)} / mes',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            HostInfo(
              name: a.hostName,
              subtitle: a.hostSubtitle,
              prefix: 'Para ',
              avatarUrl: a.hostAvatarUrl,
            ),
            const Divider(height: 36, color: AppColors.divider),
            const SectionLabel('MENSAJE'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Cuéntale a ${a.hostName} por qué te interesa rentar...',
              controller: _message,
              maxLines: 6,
              errorText: _showErrors && _message.text.trim().isEmpty
                  ? 'Escribe un mensaje'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            if (AppScope.of(context).profile.phone.trim().isNotEmpty)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Compartir mi teléfono',
                    style: TextStyle(fontSize: 14.5)),
                subtitle: const Text(
                  'Por defecto tu teléfono y correo no se muestran.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _sharePhone,
                onChanged: (v) => setState(() => _sharePhone = v),
              ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isSubmitting ? 'Enviando...' : 'Enviar mensaje',
              onPressed: _isSubmitting ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
