import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/presentation/widgets/apartment_list_tile.dart';
import '../../../apartments/presentation/widgets/status_chip.dart';

/// Pestaña de administración de departamentos:
/// Muestra los 15 más recientes al entrar, permite buscar con una barra de búsqueda,
/// y da control al administrador para editar o eliminar cualquier departamento.
class AdminApartmentsTab extends StatefulWidget {
  const AdminApartmentsTab({super.key});

  @override
  State<AdminApartmentsTab> createState() => _AdminApartmentsTabState();
}

class _AdminApartmentsTabState extends State<AdminApartmentsTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(BuildContext context, Apartment a) async {
    final ok = await confirmDialog(
      context,
      title: 'Eliminar departamento',
      message:
          '¿Seguro que deseas eliminar "${a.title}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!ok || !context.mounted) return;

    final err = await AppScope.read(context).deleteApartment(a.id);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      err ?? 'Departamento eliminado',
      icon: err == null ? Icons.check_circle : Icons.error_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = state.apartments;

    final List<Apartment> displayed;
    if (_query.trim().isEmpty) {
      displayed = all.take(15).toList();
    } else {
      final q = _query.trim().toLowerCase();
      displayed = all.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.location.toLowerCase().contains(q) ||
            a.address.toLowerCase().contains(q) ||
            a.hostName.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q);
      }).toList();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Buscar por título, zona, rentero...',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: AppColors.muted),
                  prefixIcon: const Icon(Icons.search,
                      size: 20, color: AppColors.navy),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 18, color: AppColors.muted),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceSoft,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _query.trim().isEmpty
                      ? (all.length > 15
                          ? 'Mostrando los 15 departamentos más recientes (de ${all.length})'
                          : '${all.length} departamento${all.length == 1 ? '' : 's'} registrado${all.length == 1 ? '' : 's'}')
                      : '${displayed.length} resultado${displayed.length == 1 ? '' : 's'} encontrado${displayed.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: displayed.isEmpty
              ? (all.isEmpty
                  ? const EmptyState(
                      icon: Icons.apartment_outlined,
                      title: 'No hay departamentos',
                      message: 'Cuando los renteros publiquen, aparecerán aquí.',
                    )
                  : EmptyState(
                      icon: Icons.search_off,
                      title: 'Sin resultados',
                      message:
                          'No se encontraron departamentos con "$_query".',
                    ))
              : ListView.separated(
                  itemCount: displayed.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final a = displayed[i];
                    return ApartmentListTile(
                      apartment: a,
                      badge: StatusChip(status: a.status),
                      extraLine: 'Publicado por ${a.hostName}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.blue),
                            onPressed: () => Navigator.of(context).pushNamed(
                              AppRoutes.apartmentForm,
                              arguments: a,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.muted),
                            onPressed: () => _delete(context, a),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.apartmentDetail,
                        arguments: a,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
