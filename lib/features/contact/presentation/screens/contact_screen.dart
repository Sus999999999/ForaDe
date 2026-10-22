import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/host_info.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../apartments/domain/models/apartment.dart';

class ContactScreen extends StatefulWidget {
  final Apartment apartment;
  const ContactScreen({super.key, required this.apartment});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _message;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final profile = AppScope.read(context).profile;
    final a = widget.apartment;
    _name = TextEditingController(text: profile.name);
    _phone = TextEditingController(text: profile.phone);
    _message = TextEditingController(
      text:
          'Hola ${a.hostName}, me interesa rentar "${a.title}". ¿Sigue disponible? Me gustaría recibir más información y agendar una visita. ¡Gracias!',
    );
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
    final messenger = ScaffoldMessenger.of(context);
    final host = widget.apartment.hostName;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Mensaje enviado a $host')),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.apartment;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Contactar',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${a.location} • ${formatPrice(a.price)} /mes',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  HostInfo(
                    name: a.hostName,
                    subtitle: a.hostSubtitle,
                    prefix: 'Para ',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionLabel('TU NOMBRE'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Nombre completo',
              controller: _name,
              errorText: _requiredError(_name, 'Escribe tu nombre'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const SectionLabel('TELÉFONO (OPCIONAL)'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Para que el rentador te contacte',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            const SectionLabel('MENSAJE'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Cuéntale al rentador sobre tu interés...',
              controller: _message,
              maxLines: 6,
              errorText: _requiredError(_message, 'Escribe un mensaje'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 25),
            PrimaryButton(label: 'Enviar mensaje', onPressed: _send),
          ],
        ),
      ),
    );
  }
}
