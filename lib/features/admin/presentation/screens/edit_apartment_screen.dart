import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../../apartments/domain/models/apartment.dart';

class EditApartmentScreen extends StatefulWidget {
  final Apartment apartment;
  const EditApartmentScreen({super.key, required this.apartment});

  @override
  State<EditApartmentScreen> createState() => _EditApartmentScreenState();
}

class _EditApartmentScreenState extends State<EditApartmentScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _location;
  late bool _available;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final a = widget.apartment;
    _title = TextEditingController(text: a.title);
    _description = TextEditingController(text: a.description);
    _price = TextEditingController(text: a.price.toString());
    _location = TextEditingController(text: a.location);
    _available = a.isAvailable;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _location.dispose();
    super.dispose();
  }

  String? _required(TextEditingController c) =>
      _showErrors && c.text.trim().isEmpty ? 'Campo obligatorio' : null;

  void _save() {
    setState(() => _showErrors = true);
    final price = int.tryParse(_price.text.trim());
    final valid = _title.text.trim().isNotEmpty &&
        _description.text.trim().isNotEmpty &&
        _location.text.trim().isNotEmpty &&
        price != null &&
        price > 0;
    if (!valid) return;

    AppScope.read(context).updateApartment(
      widget.apartment.copyWith(
        title: _title.text.trim(),
        description: _description.text.trim(),
        price: price,
        location: _location.text.trim(),
        isAvailable: _available,
      ),
    );
    FocusScope.of(context).unfocus();
    popAndShowSnackBar(context, 'Departamento actualizado',
        icon: Icons.check_circle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleAppBar(title: 'Editar departamento'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('TÍTULO'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Título del departamento',
              controller: _title,
              errorText: _required(_title),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const SectionLabel('DESCRIPCIÓN'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Descripción',
              maxLines: 4,
              controller: _description,
              errorText: _required(_description),
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
              errorText: _required(_price),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const SectionLabel('UBICACIÓN'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Ubicación',
              controller: _location,
              errorText: _required(_location),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disponible'),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
            const SizedBox(height: 15),
            PrimaryButton(label: 'Guardar cambios', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
