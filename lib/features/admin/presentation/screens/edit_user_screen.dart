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
    // El correo puede estar vacío si el perfil remoto no lo tiene aún;
    // en ese caso lo permitimos para no bloquear la edición.
    if (v.isEmpty) return null;
    if (!v.contains('@') || !v.contains('.')) return 'Correo no válido';
    return null;
  }

  void _save() {
    setState(() => _showErrors = true);
    if (_nameError != null || _emailError != null) return;

    // Solo conservar administrador si el usuario ya lo era;
    // nunca permitir otorgar el rol de administrador desde la interfaz.
    final targetRole = widget.user.role == UserRole.administrador
        ? UserRole.administrador
        : (_role == UserRole.administrador ? widget.user.role : _role);

    final error = AppScope.read(context).updateUser(widget.user.copyWith(
      role: targetRole,
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
    ));
    if (error != null) {
      showAppSnackBar(context, error, icon: Icons.error_outline);
      return;
    }
    FocusScope.of(context).unfocus();
    popAndShowSnackBar(context, 'Usuario actualizado',
        icon: Icons.check_circle);
  }

  @override
  Widget build(BuildContext context) {
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
            if (widget.user.role == UserRole.administrador) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.blue, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Administrador',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'El rol de administrador no se puede otorgar ni modificar desde aquí.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<UserRole>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<UserRole>(
                      value: UserRole.rentero,
                      label: Text('Rentero', style: TextStyle(fontSize: 13)),
                    ),
                    ButtonSegment<UserRole>(
                      value: UserRole.rentador,
                      label: Text('Rentador', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  selected: {
                    _role == UserRole.administrador ? UserRole.rentero : _role
                  },
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
              ),
            ],
            const SizedBox(height: 25),
            PrimaryButton(label: 'Guardar cambios', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
