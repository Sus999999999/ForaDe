import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/outlined_action_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../domain/models/apartment_filter.dart';
import '../../domain/models/apartment_status.dart';

/// Hoja inferior para ajustar los filtros. Devuelve el filtro nuevo, o null
/// si se cierra sin aplicar. Se conserva el texto de búsqueda de [initial].
///
/// - [showStatus]: filtrar por estado (quien publica / administrador).
/// - [showZone]: filtrar por zona o ciudad.
/// - [showRadius]: radio de distancia (mapa). Requiere [locationEnabled].
Future<ApartmentFilter?> showApartmentFilterSheet(
  BuildContext context, {
  required ApartmentFilter initial,
  bool showStatus = false,
  bool showZone = true,
  bool showRadius = false,
  bool locationEnabled = false,
}) {
  return showModalBottomSheet<ApartmentFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _FilterSheet(
      initial: initial,
      showStatus: showStatus,
      showZone: showZone,
      showRadius: showRadius,
      locationEnabled: locationEnabled,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final ApartmentFilter initial;
  final bool showStatus;
  final bool showZone;
  final bool showRadius;
  final bool locationEnabled;

  const _FilterSheet({
    required this.initial,
    required this.showStatus,
    required this.showZone,
    required this.showRadius,
    required this.locationEnabled,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const _radii = <double?>[null, 1, 3, 5, 10, 25];

  late final TextEditingController _min;
  late final TextEditingController _max;
  late final TextEditingController _zone;
  ApartmentStatus? _status;
  double? _radius;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _min = TextEditingController(text: f.minPrice?.plain ?? '');
    _max = TextEditingController(text: f.maxPrice?.plain ?? '');
    _zone = TextEditingController(text: f.zone);
    _status = f.status;
    _radius = f.radiusKm;
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _zone.dispose();
    super.dispose();
  }

  Money? _parse(TextEditingController c) => Money.tryParse(c.text);

  String? _priceError(TextEditingController c) {
    if (!_showErrors || c.text.trim().isEmpty) return null;
    return _parse(c) == null ? 'Importe no válido' : null;
  }

  String? get _rangeError {
    final lo = _parse(_min);
    final hi = _parse(_max);
    if (_showErrors && lo != null && hi != null && lo > hi) {
      return 'El mínimo no puede ser mayor que el máximo';
    }
    return null;
  }

  void _apply() {
    setState(() => _showErrors = true);
    final minOk = _min.text.trim().isEmpty || _parse(_min) != null;
    final maxOk = _max.text.trim().isEmpty || _parse(_max) != null;
    if (!minOk || !maxOk || _rangeError != null) return;

    Navigator.of(context).pop(
      widget.initial.copy()
        ..minPrice = _parse(_min)
        ..maxPrice = _parse(_max)
        ..zone = widget.showZone ? _zone.text.trim() : widget.initial.zone
        ..status = widget.showStatus ? _status : widget.initial.status
        ..radiusKm = widget.showRadius ? _radius : widget.initial.radiusKm,
    );
  }

  void _clear() {
    Navigator.of(context).pop(
      widget.initial.copy()
        ..minPrice = null
        ..maxPrice = null
        ..zone = ''
        ..status = null
        ..radiusKm = null,
    );
  }

  Widget _chip(String label, bool selected, VoidCallback? onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap(),
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: AppColors.orange.withValues(alpha: 0.14),
      side: BorderSide(color: selected ? AppColors.orange : AppColors.border),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.orange : AppColors.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontFamily: AppColors.serif,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 18),
            const SectionLabel('PRECIO MENSUAL'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    hint: 'Mínimo',
                    controller: _min,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: decimal,
                    errorText: _priceError(_min),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    hint: 'Máximo',
                    controller: _max,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: decimal,
                    errorText: _priceError(_max),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (_rangeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Text(
                  _rangeError!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                ),
              ),
            if (widget.showZone) ...[
              const SizedBox(height: 18),
              const SectionLabel('UBICACIÓN (ZONA O CIUDAD)'),
              const SizedBox(height: 8),
              AppTextField(hint: 'Ej. Roma Norte', controller: _zone),
            ],
            if (widget.showStatus) ...[
              const SizedBox(height: 18),
              const SectionLabel('ESTADO'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Todos', _status == null,
                      () => setState(() => _status = null)),
                  for (final s in ApartmentStatus.values)
                    _chip(s.label, _status == s,
                        () => setState(() => _status = s)),
                ],
              ),
            ],
            if (widget.showRadius) ...[
              const SizedBox(height: 18),
              const SectionLabel('RADIO DE DISTANCIA'),
              const SizedBox(height: 8),
              if (!widget.locationEnabled)
                const Text(
                  'Activa tu ubicación (botón de GPS del mapa) para filtrar por distancia.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in _radii)
                      _chip(
                        r == null ? 'Sin límite' : '${r.round()} km',
                        _radius == r,
                        () => setState(() => _radius = r),
                      ),
                  ],
                ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedActionButton(
                    label: 'Limpiar',
                    height: 52,
                    onPressed: _clear,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Aplicar',
                    height: 52,
                    onPressed: _apply,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
