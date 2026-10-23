import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/presentation/widgets/apartment_card.dart';
import '../widgets/apartment_section.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/search_field.dart';
import '../widgets/welcome_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: AppScope.read(context).searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(Apartment a) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed(AppRoutes.apartmentDetail, arguments: a);
  }

  WelcomeBanner _banner(AppState state) {
    final first = state.profile.name.trim().split(' ').first;
    final greeting = first.isEmpty ? 'Hola' : 'Hola, $first';

    if (state.canPublish) {
      return WelcomeBanner(
        title: greeting,
        subtitle: 'Publica un nuevo departamento y llega a más personas.',
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.addApartment),
      );
    }
    if (state.isAdmin) {
      return WelcomeBanner(
        title: greeting,
        subtitle:
            'Hay ${state.apartments.length} departamentos y ${state.users.length} usuarios en la plataforma.',
      );
    }
    return WelcomeBanner(
      title: greeting,
      subtitle: 'Encuentra tu próximo hogar en tu zona favorita.',
    );
  }

  Widget _content(AppState state, List<Apartment> results) {
    if (state.isFiltering) {
      if (results.isEmpty) {
        return const EmptyState(
          icon: Icons.search_off,
          title: 'Sin resultados',
          message: 'Prueba con otra zona o cambia el filtro.',
        );
      }
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text(
            '${results.length} ${results.length == 1 ? 'resultado' : 'resultados'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          for (final a in results)
            Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: ApartmentCard(
                apartment: a,
                aspectRatio: 16 / 10,
                onTap: () => _open(a),
              ),
            ),
        ],
      );
    }

    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.apartment_outlined,
        title: 'No hay departamentos para mostrar',
        message: 'Cuando haya departamentos publicados aparecerán aquí.',
      );
    }

    final nearby = results.where((a) => a.distanceLabel != null).toList();
    final topRated = results.where((a) => a.rating > 0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final recent = results.where((a) => a.distanceLabel == null).toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 20, bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _banner(state),
        ),
        const SizedBox(height: 28),
        if (nearby.isNotEmpty) ...[
          ApartmentSection(
              title: 'Cerca de ti', apartments: nearby, onTap: _open),
          const SizedBox(height: 28),
        ],
        if (topRated.length > 1) ...[
          ApartmentSection(
            title: 'Mejor calificados',
            apartments: topRated.take(6).toList(),
            onTap: _open,
          ),
          const SizedBox(height: 28),
        ],
        if (recent.isNotEmpty)
          ApartmentSection(
              title: 'Recién publicados', apartments: recent, onTap: _open),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final results = state.searchResults;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: SearchField(
              controller: _searchController,
              onChanged: state.setSearchQuery,
              onClear: () {
                _searchController.clear();
                state.setSearchQuery('');
              },
            ),
          ),
          FilterTabs(
            selected: state.homeFilter,
            onSelected: state.setHomeFilter,
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(child: _content(state, results)),
        ],
      ),
    );
  }
}
