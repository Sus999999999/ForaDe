import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../widgets/password_field.dart';

/// Recuperar acceso en dos pasos: 1) pedir un código con el correo,
/// 2) escribir el código y elegir una contraseña nueva.
class RecoverAccessScreen extends StatefulWidget {
  const RecoverAccessScreen({super.key});

  @override
  State<RecoverAccessScreen> createState() => _RecoverAccessScreenState();
}

class _RecoverAccessScreenState extends State<RecoverAccessScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _codeSent = false;
  bool _showErrors = false;
  bool _busy = false;
  String? _demoCode; // solo existe si la cuenta existe (modo demostración)
  String? _formError;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _requestCode() {
    setState(() => _showErrors = true);
    if (Validators.email(_email.text) != null) return;

    FocusScope.of(context).unfocus();
    final code = AppScope.read(context).requestRecoveryCode(_email.text);
    setState(() {
      _codeSent = true;
      _showErrors = false;
      _demoCode = code;
      _formError = null;
    });
  }

  Future<void> _reset() async {
    if (_busy) return;
    setState(() {
      _showErrors = true;
      _formError = null;
    });
    final valid = _code.text.trim().length == 6 &&
        Validators.password(_password.text) == null &&
        Validators.confirmPassword(_confirm.text, _password.text) == null;
    if (!valid) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final error = AppScope.read(context).resetPassword(
      email: _email.text,
      code: _code.text,
      newPassword: _password.text,
    );
    if (error != null) {
      setState(() {
        _busy = false;
        _formError = error;
      });
      return;
    }
    popAndShowSnackBar(
      context,
      'Contraseña actualizada. Ya puedes iniciar sesión.',
      icon: Icons.check_circle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleAppBar(title: 'Recuperar acceso'),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _codeSent
                  ? 'Si el correo está registrado, te enviamos un código de 6 dígitos. Vence en 10 minutos.'
                  : 'Escribe el correo de tu cuenta y te enviaremos un código para elegir una contraseña nueva.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('CORREO'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'correo@ejemplo.com',
              controller: _email,
              enabled: !_codeSent,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_codeSent) _requestCode();
              },
              errorText: _showErrors && !_codeSent
                  ? Validators.email(_email.text)
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            if (!_codeSent) ...[
              const SizedBox(height: 24),
              PrimaryButton(label: 'Enviar código', onPressed: _requestCode),
            ] else ...[
              if (_demoCode != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.uploadFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Modo demostración: tu código es $_demoCode. '
                    'En la versión final llegará solo por correo.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const SectionLabel('CÓDIGO'),
              const SizedBox(height: 8),
              AppTextField(
                hint: '6 dígitos',
                controller: _code,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                errorText: _showErrors && _code.text.trim().length != 6
                    ? 'Escribe el código de 6 dígitos'
                    : null,
                onChanged: (_) => setState(() => _formError = null),
              ),
              const SizedBox(height: 15),
              const SectionLabel('NUEVA CONTRASEÑA'),
              const SizedBox(height: 8),
              PasswordField(
                controller: _password,
                hint: 'Mínimo 8 caracteres, letras y números',
                textInputAction: TextInputAction.next,
                errorText:
                    _showErrors ? Validators.password(_password.text) : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 15),
              const SectionLabel('CONFIRMAR CONTRASEÑA'),
              const SizedBox(height: 8),
              PasswordField(
                controller: _confirm,
                hint: 'Repite la contraseña',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _reset(),
                errorText: _showErrors
                    ? Validators.confirmPassword(
                        _confirm.text, _password.text)
                    : null,
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
                label: _busy ? 'Guardando...' : 'Restablecer contraseña',
                onPressed: _busy ? null : _reset,
              ),
              TextButton(
                onPressed: () => setState(() {
                  _codeSent = false;
                  _demoCode = null;
                  _code.clear();
                  _formError = null;
                }),
                child: const Text('Usar otro correo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
