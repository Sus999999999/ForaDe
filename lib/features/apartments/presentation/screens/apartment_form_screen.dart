import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/outlined_action_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../../add_apartment/presentation/widgets/image_upload_box.dart';
import '../../domain/models/apartment.dart';
import '../../domain/models/apartment_status.dart';
import '../widgets/location_picker.dart';
import '../widgets/status_chip.dart';

/// Formulario de departamento: publicar uno nuevo o editar uno propio.
/// Solo quien publicó el departamento puede editarlo o desactivarlo.
class ApartmentFormScreen extends StatefulWidget {
  /// null = publicar uno nuevo.
  final Apartment? apartment;
  const ApartmentFormScreen({super.key, this.apartment});

  @override
  State<ApartmentFormScreen> createState() => _ApartmentFormScreenState();
}

class _ApartmentFormScreenState extends State<ApartmentFormScreen> {
  static const _editableStatuses = [
    ApartmentStatus.disponible,
    ApartmentStatus.ocupado,
    ApartmentStatus.noDisponible,
  ];

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _zone;
  late final TextEditingController _address;
  GeoPoint? _point;
  late ApartmentStatus _status;
  List<Uint8List> _selectedImages = [];
  bool _showErrors = false;
  bool _saving = false;

  bool get _editing => widget.apartment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.apartment;
    _title = TextEditingController(text: a?.title ?? '');
    _description = TextEditingController(text: a?.description ?? '');
    _price = TextEditingController(text: a?.price.plain ?? '');
    _zone = TextEditingController(text: a?.location ?? '');
    _address = TextEditingController(text: a?.address ?? '');
    _point = a?.point;
    _status = a?.status ?? ApartmentStatus.disponible;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _zone.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _required(TextEditingController c) =>
      _showErrors && c.text.trim().isEmpty ? 'Campo obligatorio' : null;

  Money? get _priceValue => Money.tryParse(_price.text);

  String? get _priceError {
    if (!_showErrors) return null;
    if (_price.text.trim().isEmpty) return 'Campo obligatorio';
    final v = _priceValue;
    if (v == null) return 'Importe no válido (máximo 2 decimales)';
    if (!v.isPositive) return 'Debe ser mayor a cero';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _showErrors = true);

    final price = _priceValue;
    final valid = _title.text.trim().isNotEmpty &&
        _description.text.trim().isNotEmpty &&
        _zone.text.trim().isNotEmpty &&
        _address.text.trim().isNotEmpty &&
        _point != null &&
        price != null &&
        price.isPositive;
    if (!valid || price == null) {
      showAppSnackBar(context, 'Completa todos los campos para continuar',
          icon: Icons.info_outline);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final state = AppScope.read(context);
    final current = widget.apartment;

    final String? error;
    if (current == null) {
      error = await state.addApartment(
        title: _title.text,
        description: _description.text,
        price: price,
        location: _zone.text,
        address: _address.text,
        point: _point!,
        status: _status,
        imageBytes: _selectedImages,
      );
    } else {
      final fresh = state.apartmentById(current.id) ?? current;
      error = state.updateApartment(fresh.copyWith(
        title: _title.text,
        description: _description.text,
        price: price,
        location: _zone.text,
        address: _address.text,
        point: _point,
        status: _status,
      ));
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      showAppSnackBar(context, error, icon: Icons.error_outline);
      return;
    }
    popAndShowSnackBar(
      context,
      current == null
          ? 'Departamento publicado'
          : 'Cambios guardados',
      icon: Icons.check_circle,
    );
  }

  Future<void> _deactivate(Apartment a) async {
    final state = AppScope.read(context);
    final ok = await confirmDialog(
      context,
      title: 'Desactivar departamento',
      message:
          '"${a.title}" dejará de aparecer en las búsquedas. Los contactos y favoritos asociados se conservan y puedes reactivarlo cuando quieras.',
      confirmLabel: 'Desactivar',
    );
    if (!ok || !mounted) return;
    final error = state.deactivateApartment(a.id);
    if (error != null) {
      showAppSnackBar(context, error, icon: Icons.error_outline);
      return;
    }
    popAndShowSnackBar(context, 'Departamento desactivado',
        icon: Icons.check_circle);
  }

  void _reactivate(Apartment a) {
    final error = AppScope.read(context).reactivateApartment(a.id);
    showAppSnackBar(
      context,
      error ?? 'Departamento reactivado',
      icon: error == null ? Icons.check_circle : Icons.error_outline,
    );
    if (error == null) setState(() => _status = ApartmentStatus.disponible);
  }

  Widget _statusSection(Apartment? current, bool hasActiveStay) {
    if (current != null && current.isInactive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(status: ApartmentStatus.inactivo),
          const SizedBox(height: 8),
          const Text(
            'No aparece en las búsquedas. Sus contactos y favoritos se conservan.',
            style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          OutlinedActionButton(
            label: 'Reactivar departamento',
            height: 48,
            onPressed: () => _reactivate(current),
          ),
        ],
      );
    }

    final locked = hasActiveStay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _editableStatuses)
              ChoiceChip(
                label: Text(s.label),
                selected: (locked ? ApartmentStatus.ocupado : _status) == s,
                onSelected:
                    locked ? null : (_) => setState(() => _status = s),
                showCheckmark: false,
                backgroundColor: Colors.white,
                selectedColor:
                    StatusChip.colorOf(s).withValues(alpha: 0.14),
                side: BorderSide(
                  color: (locked ? ApartmentStatus.ocupado : _status) == s
                      ? StatusChip.colorOf(s)
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: (locked ? ApartmentStatus.ocupado : _status) == s
                      ? StatusChip.colorOf(s)
                      : AppColors.text,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          locked
              ? 'Tiene una renta en curso. Finalízala desde el chat para cambiar el estado.'
              : 'Solo los departamentos Disponibles aparecen en las búsquedas.',
          style: const TextStyle(
              fontSize: 12.5, height: 1.4, color: AppColors.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final original = widget.apartment;
    final current =
        original == null ? null : (state.apartmentById(original.id) ?? original);

    // Solo el publicador puede editar su departamento.
    if (current != null && current.ownerId != state.profile.id) {
      return const Scaffold(
        appBar: TitleAppBar(title: 'Editar departamento'),
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Sin permiso',
          message: 'Solo quien publicó el departamento puede editarlo.',
        ),
      );
    }

    final hasActiveStay =
        current != null && state.activeStayOf(current.id) != null;

    return Scaffold(
      appBar: TitleAppBar(
        title: _editing ? 'Editar departamento' : 'Publicar departamento',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ImageUploadBox(
                    images: _selectedImages,
                    onImagesChanged: (imgs) =>
                        setState(() => _selectedImages = imgs),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('TÍTULO'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Título del departamento',
                    controller: _title,
                    errorText: _required(_title),
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
                    errorText: _required(_description),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('PRECIO MENSUAL (MXN)'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: '\$ 0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    controller: _price,
                    errorText: _priceError,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('ZONA (VISIBLE PARA TODOS)'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Colonia y ciudad, ej. Col. Roma Norte, CDMX',
                    controller: _zone,
                    errorText: _required(_zone),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('DIRECCIÓN EXACTA (PRIVADA)'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Calle, número y colonia',
                    controller: _address,
                    errorText: _required(_address),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Solo la ves tú y las personas con las que ya estás en contacto. En las búsquedas se muestra una ubicación aproximada.',
                    style: TextStyle(
                        fontSize: 12, height: 1.4, color: AppColors.muted),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('UBICACIÓN EN EL MAPA'),
                  const SizedBox(height: 8),
                  LocationPicker(
                    value: _point,
                    errorText: _showErrors && _point == null
                        ? 'Toca el mapa para colocar el pin'
                        : null,
                    onChanged: (p) => setState(() => _point = p),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('ESTADO'),
                  const SizedBox(height: 8),
                  _statusSection(current, hasActiveStay),
                  if (current != null && !current.isInactive) ...[
                    const SizedBox(height: 28),
                    OutlinedActionButton(
                      label: 'Desactivar departamento',
                      height: 50,
                      onPressed: () => _deactivate(current),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: PrimaryButton(
                label: _saving
                    ? (_editing ? 'Guardando...' : 'Subiendo departamento y fotos...')
                    : (_editing ? 'Guardar cambios' : 'Publicar departamento'),
                onPressed: _saving ? null : _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
