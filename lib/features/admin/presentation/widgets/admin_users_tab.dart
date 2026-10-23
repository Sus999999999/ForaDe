import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/widgets/role_badge.dart';
import '../../../profile/domain/models/user_profile.dart';

class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  Future<void> _delete(BuildContext context, UserProfile user) async {
    final state = AppScope.read(context);

    if (user.id == state.profile.id) {
      showAppSnackBar(context, 'No puedes eliminar tu propia cuenta',
          icon: Icons.info_outline);
      return;
    }

    final count = state.apartmentCountOf(user.id);
    final extra = count > 0
        ? ' También se eliminarán sus $count departamento${count == 1 ? '' : 's'}.'
        : '';
    final ok = await confirmDialog(
      context,
      title: 'Eliminar usuario',
      message: '¿Seguro que quieres eliminar a "${user.name}"?$extra',
      confirmLabel: 'Eliminar',
    );
    if (!ok || !context.mounted) return;

    state.deleteUser(user.id);
    showAppSnackBar(context, 'Usuario eliminado');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final users = state.users;
    final myId = state.profile.id;

    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (_, i) {
        final u = users[i];
        final isSelf = u.id == myId;
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
            isSelf ? '${u.name} (tú)' : u.name,
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
                u.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
                icon: const Icon(Icons.edit_outlined, color: AppColors.blue),
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.adminEditUser, arguments: u),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: Icon(
                  Icons.delete_outline,
                  color: isSelf
                      ? AppColors.muted.withValues(alpha: 0.4)
                      : AppColors.muted,
                ),
                onPressed: () => _delete(context, u),
              ),
            ],
          ),
        );
      },
    );
  }
}
