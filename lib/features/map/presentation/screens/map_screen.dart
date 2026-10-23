import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/routes/slide_left_route.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../menu/presentation/screens/menu_screen.dart';
import '../widgets/apartment_carousel.dart';
import '../widgets/locate_button.dart';
import '../widgets/map_pins_layer.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/map_top_bar.dart';
import '../widgets/no_results_card.dart';

/// Pantalla principal: mapa con botón de menú, buscador, pines y la tarjeta
/// del departamento seleccionado.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final TextEditingController _searchController;
  String? _selectedId;

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

  void _select(Apartment a) {
    if (_selectedId == a.id) return;
    setState(() => _selectedId = a.id);
  }

  void _openMenu() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      slideLeftRoute<void>(
        const MenuScreen(),
        const RouteSettings(name: '/menu'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final results = state.searchResults;

    // Si el seleccionado ya no está en los resultados, usamos el primero.
    final selectedId = results.any((a) => a.id == _selectedId)
        ? _selectedId
        : (results.isEmpty ? null : results.first.id);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Positioned.fill(child: MapPlaceholder()),
          Positioned.fill(
            child: MapPinsLayer(
              visible: results,
              selectedId: selectedId,
              onPinTap: _select,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: MapTopBar(
                    controller: _searchController,
                    onChanged: state.setSearchQuery,
                    onClear: () {
                      _searchController.clear();
                      state.setSearchQuery('');
                    },
                    onMenu: _openMenu,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 14, 20, 0),
                  child: Text(
                    'Forade',
                    style: TextStyle(
                      fontFamily: AppColors.serif,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: LocateButton(
                      onTap: () => showAppSnackBar(
                        context,
                        'Ubicación actual centrada',
                        icon: Icons.my_location,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: NoResultsCard(),
                  )
                else
                  ApartmentCarousel(
                    apartments: results,
                    selectedId: selectedId,
                    onSelected: _select,
                    onTap: (a) => Navigator.of(context)
                        .pushNamed(AppRoutes.apartmentDetail, arguments: a),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
