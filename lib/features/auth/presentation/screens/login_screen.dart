import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../domain/models/user_role.dart';
import '../widgets/role_badge.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  bool _showErrors = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  String? get _nameError =>
      _showErrors && _name.text.trim().isEmpty ? 'Escribe tu nombre' : null;

  String? get _emailError {
    if (!_showErrors) return null;
    final v = _email.text.trim();
    if (v.isEmpty) return 'Escribe tu correo';
    if (!v.contains('@') || !v.contains('.')) return 'Correo no válido';
    return null;
  }

  void _submit() {
    setState(() => _showErrors = true);
    if (_nameError != null || _emailError != null) return;

    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    AppScope.read(context).login(
      role: widget.role,
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      city: _city.text,
    );
    navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleAppBar(title: 'Iniciar sesión'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inicia sesión',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Entrar como',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                const SizedBox(width: 8),
                RoleBadge(role: widget.role),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Por ahora solo guardamos tus datos mientras la app esté abierta. No necesitas contraseña.',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 22),
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
            const SectionLabel('TELÉFONO (OPCIONAL)'),
            const SizedBox(height: 8),
            AppTextField(
              hint: '+52 55 0000 0000',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            const SectionLabel('CIUDAD (OPCIONAL)'),
            const SizedBox(height: 8),
            AppTextField(hint: 'Ciudad de México', controller: _city),
            const SizedBox(height: 25),
            PrimaryButton(label: 'Continuar', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
