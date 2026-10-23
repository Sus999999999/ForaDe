import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../widgets/admin_apartments_tab.dart';
import '../widgets/admin_users_tab.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TitleAppBar(
          title: 'Administración',
          bottom: TabBar(
            labelColor: AppColors.text,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.orange,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: AppColors.divider,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(text: 'Departamentos (${state.apartments.length})'),
              Tab(text: 'Usuarios (${state.users.length})'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminApartmentsTab(),
            AdminUsersTab(),
          ],
        ),
      ),
    );
  }
}
