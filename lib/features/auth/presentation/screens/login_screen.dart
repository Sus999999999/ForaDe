import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/outlined_action_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../widgets/auth_header.dart';
import '../widgets/password_field.dart';

/// Inicio de sesión con correo y contraseña.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showErrors = false;
  bool _busy = false;
  String? _formError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _emailError => _showErrors ? Validators.email(_email.text) : null;

  String? get _passwordError =>
      _showErrors && _password.text.isEmpty ? 'Escribe tu contraseña' : null;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _showErrors = true;
      _formError = null;
    });
    if (Validators.email(_email.text) != null || _password.text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    // Deja que se pinte el indicador antes del cálculo del hash.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final error = await AppScope.read(context).login(
      email: _email.text,
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
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          const AuthHeader(),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inicia sesión',
                    style: TextStyle(
                      fontFamily: AppColors.serif,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('CORREO'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'correo@ejemplo.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    onChanged: (_) => setState(() => _formError = null),
                  ),
                  const SizedBox(height: 15),
                  const SectionLabel('CONTRASEÑA'),
                  const SizedBox(height: 8),
                  PasswordField(
                    controller: _password,
                    errorText: _passwordError,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) => setState(() => _formError = null),
                  ),
                  if (_formError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _formError!,
                      style:
                          TextStyle(fontSize: 13, color: Colors.red.shade600),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context)
                              .pushNamed(AppRoutes.recoverAccess),
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: _busy ? 'Verificando...' : 'Iniciar sesión',
                    onPressed: _busy ? null : _submit,
                  ),
                  const SizedBox(height: 14),
                  OutlinedActionButton(
                    label: 'Crear cuenta',
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context)
                            .pushNamed(AppRoutes.register),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
