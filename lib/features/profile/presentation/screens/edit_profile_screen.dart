import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final p = AppScope.read(context).profile;
    _name = TextEditingController(text: p.name);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.phone);
    _city = TextEditingController(text: p.city);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  String? _requiredError(TextEditingController c) =>
      _showErrors && c.text.trim().isEmpty ? 'Campo obligatorio' : null;

  void _save() {
    setState(() => _showErrors = true);
    final filled = [_name, _email, _phone, _city]
        .every((c) => c.text.trim().isNotEmpty);
    if (!filled) return;

    final state = AppScope.read(context);
    state.updateProfile(state.profile.copyWith(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
    ));

    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Información actualizada'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Editar información',
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
            const SectionLabel('NOMBRE'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Nombre completo',
              controller: _name,
              errorText: _requiredError(_name),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const SectionLabel('CORREO'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'correo@ejemplo.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              errorText: _requiredError(_email),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const SectionLabel('TELÉFONO'),
            const SizedBox(height: 8),
            AppTextField(
              hint: '+52 55 0000 0000',
              controller: _phone,
              keyboardType: TextInputType.phone,
              errorText: _requiredError(_phone),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const SectionLabel('CIUDAD'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Ciudad de México',
              controller: _city,
              errorText: _requiredError(_city),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 25),
            PrimaryButton(label: 'Guardar cambios', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
