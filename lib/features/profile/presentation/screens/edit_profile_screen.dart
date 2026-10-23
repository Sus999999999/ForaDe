import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/title_app_bar.dart';

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

  String? get _nameError =>
      _showErrors && _name.text.trim().isEmpty ? 'Campo obligatorio' : null;

  String? get _emailError {
    if (!_showErrors) return null;
    final v = _email.text.trim();
    if (v.isEmpty) return 'Campo obligatorio';
    if (!v.contains('@') || !v.contains('.')) return 'Correo no válido';
    return null;
  }

  void _save() {
    setState(() => _showErrors = true);
    if (_nameError != null || _emailError != null) return;

    final state = AppScope.read(context);
    state.updateUser(state.profile.copyWith(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
    ));

    FocusScope.of(context).unfocus();
    popAndShowSnackBar(context, 'Información actualizada',
        icon: Icons.check_circle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleAppBar(title: 'Editar información'),
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
              errorText: _nameError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const SectionLabel('CORREO'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'correo@ejemplo.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const SectionLabel('TELÉFONO'),
            const SizedBox(height: 8),
            AppTextField(
              hint: '+52 55 0000 0000',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            const SectionLabel('CIUDAD'),
            const SizedBox(height: 8),
            AppTextField(hint: 'Ciudad de México', controller: _city),
            const SizedBox(height: 25),
            PrimaryButton(label: 'Guardar cambios', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
