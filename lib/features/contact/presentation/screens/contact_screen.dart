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
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final TextEditingController _message = TextEditingController(); // vacío
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final profile = AppScope.read(context).profile;
    _name = TextEditingController(text: profile.name);
    _phone = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  String? _requiredError(TextEditingController c, String msg) =>
      _showErrors && c.text.trim().isEmpty ? msg : null;

  void _send() {
    setState(() => _showErrors = true);
    if (_name.text.trim().isEmpty || _message.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    final state = AppScope.read(context);
    final chat = state.openChat(widget.apartment);
    if (chat == null) {
      showAppSnackBar(context, 'No puedes iniciar un chat con este rentero',
          icon: Icons.error_outline);
      return;
    }

    // El mensaje del formulario es el primero de la conversación.
    final phone = _phone.text.trim();
    final text = phone.isEmpty
        ? _message.text.trim()
        : '${_message.text.trim()}\n\nMi teléfono: $phone';
    state.sendMessage(chat.id, text);

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
            ),
            if (a.contact.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Contacto directo: ${a.contact}',
                style:
                    const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
            const Divider(height: 36, color: AppColors.divider),
            const SectionLabel('TU NOMBRE'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Nombre completo',
              controller: _name,
              errorText: _requiredError(_name, 'Escribe tu nombre'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            const SectionLabel('TELÉFONO (OPCIONAL)'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Para que el rentero te contacte',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const SectionLabel('MENSAJE'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Cuéntale a ${a.hostName} por qué te interesa rentar...',
              controller: _message,
              maxLines: 6,
              errorText: _requiredError(_message, 'Escribe un mensaje'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 26),
            PrimaryButton(label: 'Enviar e iniciar chat', onPressed: _send),
          ],
        ),
      ),
    );
  }
}
