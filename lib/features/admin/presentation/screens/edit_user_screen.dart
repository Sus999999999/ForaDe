import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../profile/domain/models/user_profile.dart';

class EditUserScreen extends StatefulWidget {
  final UserProfile user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late UserRole _role;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u.name);
    _email = TextEditingController(text: u.email);
    _phone = TextEditingController(text: u.phone);
    _city = TextEditingController(text: u.city);
    _role = u.role;
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

    AppScope.read(context).updateUser(widget.user.copyWith(
      role: _role,
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
    ));
    FocusScope.of(context).unfocus();
    popAndShowSnackBar(context, 'Usuario actualizado',
        icon: Icons.check_circle);
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = AppScope.of(context).profile.id == widget.user.id;

    return Scaffold(
      appBar: const TitleAppBar(title: 'Editar usuario'),
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
            const SizedBox(height: 15),
            const SectionLabel('TIPO DE USUARIO'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<UserRole>(
                showSelectedIcon: false,
                segments: [
                  for (final r in UserRole.values)
                    ButtonSegment<UserRole>(
                      value: r,
                      label: Text(r.label, style: const TextStyle(fontSize: 12)),
                    ),
                ],
                selected: {_role},
                // null = deshabilitado (no puedes quitarte el rol de admin)
                onSelectionChanged:
                    isSelf ? null : (s) => setState(() => _role = s.first),
              ),
            ),
            if (isSelf)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'No puedes cambiar tu propio tipo de usuario.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            const SizedBox(height: 25),
            PrimaryButton(label: 'Guardar cambios', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
