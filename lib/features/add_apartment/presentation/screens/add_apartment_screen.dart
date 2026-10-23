import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../../../core/utils/snackbar.dart';
import '../widgets/image_upload_box.dart';

class AddApartmentScreen extends StatefulWidget {
  const AddApartmentScreen({super.key});

  @override
  State<AddApartmentScreen> createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _location = TextEditingController();
  final _contact = TextEditingController();
  bool _showErrors = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _location.dispose();
    _contact.dispose();
    super.dispose();
  }

  String? _requiredError(TextEditingController c) =>
      _showErrors && c.text.trim().isEmpty ? 'Campo obligatorio' : null;

  void _submit() {
    setState(() => _showErrors = true);

    final price = int.tryParse(_price.text.trim());
    final allFilled = _title.text.trim().isNotEmpty &&
        _description.text.trim().isNotEmpty &&
        _price.text.trim().isNotEmpty &&
        _location.text.trim().isNotEmpty &&
        _contact.text.trim().isNotEmpty;

    if (!allFilled || price == null || price <= 0) {
      showAppSnackBar(
        context,
        'Completa todas las casillas para continuar',
        icon: Icons.info_outline,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    AppScope.read(context).addApartment(
      title: _title.text.trim(),
      description: _description.text.trim(),
      price: price,
      location: _location.text.trim(),
      contact: _contact.text.trim(),
    );

    // Publicar → Mapa: volvemos a la pantalla principal y avisamos allí.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.popUntil((route) => route.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Departamento agregado exitosamente')),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleAppBar(title: 'Agregar departamento'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ImageUploadBox(), // sin función por ahora
                  const SizedBox(height: 24),
                  const SectionLabel('INFORMACIÓN'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Título del departamento',
                    controller: _title,
                    errorText: _requiredError(_title),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('DESCRIPCIÓN'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Describe el espacio, ambiente y alrededores...',
                    minLines: 2,
                    maxLines: 4,
                    controller: _description,
                    errorText: _requiredError(_description),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('PRECIO'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: '\$ Precio mensual',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: _price,
                    errorText: _requiredError(_price),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('UBICACIÓN'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Selecciona en el mapa',
                    controller: _location,
                    errorText: _requiredError(_location),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('CONTACTO'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Teléfono o correo de contacto',
                    keyboardType: TextInputType.emailAddress,
                    controller: _contact,
                    errorText: _requiredError(_contact),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          // Botón fijo abajo, siempre visible.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: PrimaryButton(
                label: 'Publicar departamento',
                onPressed: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
