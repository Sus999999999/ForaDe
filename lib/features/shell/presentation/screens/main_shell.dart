import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/shell_tabs.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = shellTabsFor(AppScope.of(context).role);
    final index = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: index,
        children: [for (final t in tabs) t.page],
      ),
      bottomNavigationBar: AppBottomNav(
        items: [for (final t in tabs) t.item],
        currentIndex: index,
        onTap: (i) {
          FocusScope.of(context).unfocus();
          setState(() => _index = i);
        },
      ),
    );
  }
}
