import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../widgets/admin_apartments_tab.dart';
import '../widgets/admin_users_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.read(context).refreshAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TitleAppBar(
          title: 'Administración',
          actions: [
            IconButton(
              tooltip: 'Actualizar datos',
              icon: const Icon(Icons.refresh, color: AppColors.navy),
              onPressed: () => AppScope.read(context).refreshAdminData(),
            ),
          ],
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
