import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
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
  bool _showErrors = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _location.dispose();
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
        _location.text.trim().isNotEmpty;

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
    );

    _title.clear();
    _description.clear();
    _price.clear();
    _location.clear();
    setState(() => _showErrors = false);

    showAppSnackBar(
      context,
      'Departamento agregado exitosamente',
      icon: Icons.check_circle,
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
          'Agregar departamento',
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
            const ImageUploadBox(), // sin función por ahora
            const SizedBox(height: 20),
            const SectionLabel('INFORMACIÓN'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Título del departamento',
              controller: _title,
              errorText: _requiredError(_title),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const SectionLabel('DESCRIPCIÓN'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Describe el espacio, ambiente y alrededores...',
              maxLines: 3,
              controller: _description,
              errorText: _requiredError(_description),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
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
            const SizedBox(height: 15),
            const SectionLabel('UBICACIÓN'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Ej. Col. Roma Norte, CDMX',
              controller: _location,
              suffixIcon: const Icon(Icons.map_outlined),
              errorText: _requiredError(_location),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 25),
            PrimaryButton(label: 'Publicar departamento', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
