import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/widgets/role_badge.dart';
import '../../../profile/domain/models/user_profile.dart';

/// Pestaña de administración de usuarios:
/// Muestra los 15 más recientes al entrar (incluyendo el perfil simulado de administrador),
/// permite buscar con una barra de búsqueda, y permite editar o eliminar cuentas.
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(BuildContext context, UserProfile user) async {
    final state = AppScope.read(context);

    if (user.id == state.profile.id || user.id == 'u-admin') {
      showAppSnackBar(
        context,
        'No puedes eliminar la cuenta de administrador',
        icon: Icons.info_outline,
      );
      return;
    }

    final count = state.apartmentCountOf(user.id);
    final extra = count > 0
        ? ' Sus $count departamento${count == 1 ? '' : 's'} pasarán a Inactivo (se conservan sus contactos y favoritos).'
        : '';
    final ok = await confirmDialog(
      context,
      title: 'Eliminar usuario',
      message: '¿Seguro que quieres eliminar a "${user.name}"?$extra',
      confirmLabel: 'Eliminar',
    );
    if (!ok || !context.mounted) return;

    final success = await state.deleteUser(user.id);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      success ? 'Usuario eliminado' : 'No se pudo eliminar el usuario',
      icon: success ? Icons.check_circle : Icons.error_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = state.users;
    final myId = state.profile.id;

    final List<UserProfile> displayed;
    if (_query.trim().isEmpty) {
      displayed = all.take(15).toList();
    } else {
      final q = _query.trim().toLowerCase();
      displayed = all.where((u) {
        return u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phone.toLowerCase().contains(q) ||
            u.city.toLowerCase().contains(q) ||
            u.role.label.toLowerCase().contains(q);
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
                  hintText: 'Buscar por nombre, correo, ciudad...',
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
                          ? 'Mostrando los 15 usuarios más recientes (de ${all.length})'
                          : '${all.length} usuario${all.length == 1 ? '' : 's'} registrado${all.length == 1 ? '' : 's'}')
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
                      icon: Icons.people_outline,
                      title: 'No hay usuarios',
                      message: 'Los usuarios registrados aparecerán aquí.',
                    )
                  : EmptyState(
                      icon: Icons.search_off,
                      title: 'Sin resultados',
                      message:
                          'No se encontraron usuarios con "$_query".',
                    ))
              : ListView.separated(
                  itemCount: displayed.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final u = displayed[i];
                    final isSelf = u.id == myId || u.id == 'u-admin';
                    final initial = u.name.isEmpty ? '?' : u.name[0].toUpperCase();

                    return ListTile(
                      isThreeLine: true,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surfaceSoft,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        (u.id == myId) ? '${u.name} (tú)' : u.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.email.isEmpty ? '(Sin correo registrado)' : u.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RoleBadge(role: u.role),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.blue),
                            onPressed: () => Navigator.of(context).pushNamed(
                              AppRoutes.adminEditUser,
                              arguments: u,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: Icon(
                              Icons.delete_outline,
                              color: isSelf
                                  ? AppColors.muted.withValues(alpha: 0.3)
                                  : AppColors.muted,
                            ),
                            onPressed: isSelf ? null : () => _delete(context, u),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
