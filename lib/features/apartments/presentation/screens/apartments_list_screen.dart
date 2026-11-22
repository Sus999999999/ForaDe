import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/outlined_action_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../domain/models/apartment.dart';
import '../../domain/models/apartment_filter.dart';
import '../../domain/models/apartment_status.dart';
import '../widgets/apartment_filter_sheet.dart';
import '../widgets/apartment_list_tile.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/status_chip.dart';

enum _Action { edit, available, occupied, unavailable, deactivate, reactivate }

/// Lista de departamentos con búsqueda y filtros por precio, estado y zona.
/// - Quien busca: solo departamentos disponibles.
/// - Quien publica: los suyos, en cualquier estado, con acciones de gestión.
/// - Administrador: todos, solo de consulta.
class ApartmentsListScreen extends StatefulWidget {
  const ApartmentsListScreen({super.key});

  @override
  State<ApartmentsListScreen> createState() => _ApartmentsListScreenState();
}

class _ApartmentsListScreenState extends State<ApartmentsListScreen> {
  final _search = TextEditingController();
  ApartmentFilter _filter = ApartmentFilter();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Apartment a) =>
      Navigator.of(context).pushNamed(AppRoutes.apartmentDetail, arguments: a);

  Future<void> _openFilters(AppState state) async {
    final result = await showApartmentFilterSheet(
      context,
      initial: _filter,
      // Quien busca solo ve disponibles: no tiene sentido filtrar por estado.
      showStatus: state.canPublish || state.isAdmin,
    );
    if (result != null) setState(() => _filter = result);
  }

  void _clearFilters() {
    _search.clear();
    setState(() => _filter = ApartmentFilter());
  }

  void _report(String? error, String okMessage) {
    showAppSnackBar(
      context,
      error ?? okMessage,
      icon: error == null ? Icons.check_circle : Icons.error_outline,
    );
  }

  Future<void> _onAction(_Action action, Apartment a) async {
    final state = AppScope.read(context);
    switch (action) {
      case _Action.edit:
        Navigator.of(context)
            .pushNamed(AppRoutes.apartmentForm, arguments: a);
      case _Action.available:
        _report(state.setApartmentStatus(a.id, ApartmentStatus.disponible),
            'Marcado como disponible');
      case _Action.occupied:
        _report(state.setApartmentStatus(a.id, ApartmentStatus.ocupado),
            'Marcado como ocupado');
      case _Action.unavailable:
        _report(state.setApartmentStatus(a.id, ApartmentStatus.noDisponible),
            'Marcado como no disponible');
      case _Action.reactivate:
        _report(state.reactivateApartment(a.id), 'Departamento reactivado');
      case _Action.deactivate:
        final ok = await confirmDialog(
          context,
          title: 'Desactivar departamento',
          message:
              '"${a.title}" dejará de aparecer en las búsquedas. Los contactos y favoritos asociados se conservan y puedes reactivarlo cuando quieras.',
          confirmLabel: 'Desactivar',
        );
        if (!ok || !mounted) return;
        _report(state.deactivateApartment(a.id), 'Departamento desactivado');
    }
  }

  Widget _trailing(AppState state, Apartment a) {
    if (state.canPublish) {
      return PopupMenuButton<_Action>(
        tooltip: 'Opciones',
        icon: const Icon(Icons.more_vert, color: AppColors.navy),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        onSelected: (act) => _onAction(act, a),
        itemBuilder: (_) => [
          const PopupMenuItem(value: _Action.edit, child: Text('Editar')),
          if (!a.isInactive) ...[
            if (a.status != ApartmentStatus.disponible)
              const PopupMenuItem(
                  value: _Action.available,
                  child: Text('Marcar como disponible')),
            if (a.status != ApartmentStatus.ocupado)
              const PopupMenuItem(
                  value: _Action.occupied, child: Text('Marcar como ocupado')),
            if (a.status != ApartmentStatus.noDisponible)
              const PopupMenuItem(
                  value: _Action.unavailable,
                  child: Text('Marcar como no disponible')),
            const PopupMenuItem(
              value: _Action.deactivate,
              child: Text('Desactivar',
                  style: TextStyle(color: AppColors.orange)),
            ),
          ] else
            const PopupMenuItem(
                value: _Action.reactivate, child: Text('Reactivar')),
        ],
      );
    }
    if (state.canFavorite) {
      final fav = state.isFavorite(a.id);
      return IconButton(
        tooltip: fav ? 'Quitar de favoritos' : 'Guardar en favoritos',
        icon: Icon(
          fav ? Icons.favorite : Icons.favorite_border,
          color: fav ? AppColors.orange : AppColors.muted,
        ),
        onPressed: () {
          final added = state.toggleFavorite(a.id);
          showAppSnackBar(
            context,
            added ? 'Agregado a favoritos' : 'Eliminado de favoritos',
            icon: added ? Icons.favorite : Icons.heart_broken_outlined,
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final base = state.listableApartments;
    final results = base.where((a) => _filter.matches(a)).toList();

    final title = state.canPublish ? 'Mis departamentos' : 'Departamentos';
    final filtering = !_filter.isEmpty;

    Widget body;
    if (base.isEmpty) {
      body = EmptyState(
        icon: Icons.apartment_outlined,
        title: state.canPublish
            ? 'No has publicado departamentos'
            : 'No hay departamentos disponibles',
        message: state.canPublish
            ? 'Publica el primero y aparecerá aquí.'
            : 'Cuando haya departamentos disponibles aparecerán aquí.',
        action: state.canPublish
            ? PrimaryButton(
                label: 'Publicar departamento',
                expand: false,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.apartmentForm),
              )
            : null,
      );
    } else if (results.isEmpty) {
      body = EmptyState(
        icon: Icons.search_off,
        title: 'Sin resultados',
        message: 'Prueba con otra búsqueda o cambia los filtros.',
        action: OutlinedActionButton(
          label: 'Limpiar filtros',
          expand: false,
          height: 46,
          onPressed: _clearFilters,
        ),
      );
    } else {
      body = ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: results.length + 1,
        separatorBuilder: (_, i) => i == 0
            ? const SizedBox.shrink()
            : const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: AppColors.divider),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                '${results.length} ${results.length == 1 ? 'departamento' : 'departamentos'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            );
          }
          final a = results[i - 1];
          final distance = state.distanceLabel(a);
          return ApartmentListTile(
            apartment: a,
            badge: StatusChip(status: a.status),
            extraLine: state.isAdmin
                ? 'Publicado por ${a.hostName}'
                : distance,
            onTap: () => _open(a),
            trailing: _trailing(state, a),
          );
        },
      );
    }

    return Scaffold(
      appBar: TitleAppBar(
        title: title,
        actions: [
          if (state.canPublish)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: PrimaryButton(
                  label: '+ Agregar',
                  expand: false,
                  height: 40,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.apartmentForm),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: SearchFilterBar(
              controller: _search,
              activeFilters: _filter.advancedCount,
              onChanged: (v) => setState(() => _filter.query = v),
              onClear: () {
                _search.clear();
                setState(() => _filter.query = '');
              },
              onFilter: () => _openFilters(state),
            ),
          ),
          if (filtering)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Quitar búsqueda y filtros',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
