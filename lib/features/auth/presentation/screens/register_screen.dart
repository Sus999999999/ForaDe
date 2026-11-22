import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../domain/models/user_role.dart';
import '../widgets/password_field.dart';
import '../widgets/role_option_button.dart';

/// Registro: nombre, correo, teléfono, tipo de usuario y contraseña.
/// El administrador no se puede elegir aquí.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _roles = [UserRole.rentador, UserRole.rentero];

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole _role = UserRole.rentador;
  bool _showErrors = false;
  bool _busy = false;
  String? _formError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _err(String? Function() validate) => _showErrors ? validate() : null;

  bool get _valid =>
      Validators.name(_name.text) == null &&
      Validators.email(_email.text) == null &&
      Validators.phone(_phone.text) == null &&
      Validators.password(_password.text) == null &&
      Validators.confirmPassword(_confirm.text, _password.text) == null;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _showErrors = true;
      _formError = null;
    });
    if (!_valid) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final error = await AppScope.read(context).register(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      role: _role,
      password: _password.text,
    );
    if (error != null) {
      setState(() {
        _busy = false;
        _formError = error;
      });
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleAppBar(title: 'Crear cuenta'),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('NOMBRE'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Nombre completo',
              controller: _name,
              textInputAction: TextInputAction.next,
              errorText: _err(() => Validators.name(_name.text)),
              onChanged: (_) => setState(() => _formError = null),
            ),
            const SizedBox(height: 15),
            const SectionLabel('CORREO'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'correo@ejemplo.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _err(() => Validators.email(_email.text)),
              onChanged: (_) => setState(() => _formError = null),
            ),
            const SizedBox(height: 15),
            const SectionLabel('TELÉFONO'),
            const SizedBox(height: 8),
            AppTextField(
              hint: '+52 55 0000 0000',
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              errorText: _err(() => Validators.phone(_phone.text)),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tu correo y teléfono no se muestran públicamente.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            const SectionLabel('TIPO DE USUARIO'),
            const SizedBox(height: 8),
            for (final r in _roles)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RoleOptionButton(
                  role: r,
                  selected: _role == r,
                  onTap: () => setState(() => _role = r),
                ),
              ),
            const SizedBox(height: 8),
            const SectionLabel('CONTRASEÑA'),
            const SizedBox(height: 8),
            PasswordField(
              controller: _password,
              hint: 'Mínimo 8 caracteres, letras y números',
              textInputAction: TextInputAction.next,
              errorText: _err(() => Validators.password(_password.text)),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const SectionLabel('CONFIRMAR CONTRASEÑA'),
            const SizedBox(height: 8),
            PasswordField(
              controller: _confirm,
              hint: 'Repite la contraseña',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              errorText: _err(
                  () => Validators.confirmPassword(_confirm.text, _password.text)),
              onChanged: (_) => setState(() {}),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 12),
              Text(
                _formError!,
                style: TextStyle(fontSize: 13, color: Colors.red.shade600),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: _busy ? 'Creando cuenta...' : 'Crear cuenta',
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
