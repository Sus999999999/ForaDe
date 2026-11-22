import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/routes/slide_left_route.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/presentation/widgets/apartment_filter_sheet.dart';
import '../../../menu/presentation/screens/menu_screen.dart';
import '../widgets/apartment_carousel.dart';
import '../widgets/locate_button.dart';
import '../widgets/map_pin.dart';
import '../widgets/map_top_bar.dart';
import '../widgets/no_results_card.dart';

/// Vista de búsqueda: departamentos como marcadores (ubicación aproximada),
/// con filtros de precio y radio de distancia. Al abrir un marcador ya
/// seleccionado, o su tarjeta, se abre el detalle.
class MapScreen extends StatefulWidget {
  /// Departamento a enfocar al abrir (desde el detalle).
  final String? focusApartmentId;
  const MapScreen({super.key, this.focusApartmentId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final TextEditingController _searchController;
  late final MapController _mapController;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController =
        TextEditingController(text: AppScope.read(context).searchQuery);
    _selectedId = widget.focusApartmentId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(Apartment a) => Navigator.of(context)
      .pushNamed(AppRoutes.apartmentDetail, arguments: a);

  /// Primer toque selecciona (y mueve el carrusel); tocar el ya seleccionado
  /// abre el detalle.
  void _onPin(Apartment a) {
    if (_selectedId == a.id) {
      _openDetail(a);
      return;
    }
    setState(() => _selectedId = a.id);
  }

  void _select(Apartment a) {
    if (_selectedId == a.id) return;
    setState(() => _selectedId = a.id);
    _mapController.move(
      LatLng(a.approxPoint.lat, a.approxPoint.lng),
      14.5,
    );
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

  Future<void> _openFilters() async {
    final state = AppScope.read(context);
    FocusScope.of(context).unfocus();
    final result = await showApartmentFilterSheet(
      context,
      initial: state.mapFilter,
      showZone: false, // la zona se busca con el cuadro de texto
      showRadius: true,
      locationEnabled: state.locationEnabled,
    );
    if (result != null) state.updateMapFilter(result);
  }

  Future<void> _locate() async {
    final state = AppScope.read(context);
    final ok = await state.enableLocation();
    if (!mounted) return;
    if (state.userLocation != null) {
      _mapController.move(
        LatLng(state.userLocation!.lat, state.userLocation!.lng),
        14.5,
      );
    }
    showAppSnackBar(
      context,
      ok ? 'Ubicación centrada' : 'No se pudo obtener tu ubicación',
      icon: ok ? Icons.my_location : Icons.location_off_outlined,
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

    final initialCenter = widget.focusApartmentId != null &&
            results.any((a) => a.id == widget.focusApartmentId)
        ? LatLng(
            results.firstWhere((a) => a.id == widget.focusApartmentId).approxPoint.lat,
            results.firstWhere((a) => a.id == widget.focusApartmentId).approxPoint.lng,
          )
        : (state.userLocation != null
            ? LatLng(state.userLocation!.lat, state.userLocation!.lng)
            : (results.isNotEmpty
                ? LatLng(results.first.approxPoint.lat, results.first.approxPoint.lng)
                : const LatLng(19.4270, -99.1677)));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 13.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.forade.app',
                ),
                MarkerLayer(
                  markers: [
                    if (state.userLocation != null)
                      Marker(
                        point: LatLng(
                          state.userLocation!.lat,
                          state.userLocation!.lng,
                        ),
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F80ED),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    for (final a in results)
                      Marker(
                        point: LatLng(a.approxPoint.lat, a.approxPoint.lng),
                        width: a.id == selectedId ? 48 : 34,
                        height: (a.id == selectedId ? 48 : 34) * 1.25,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onPin(a),
                          child: MapPin(
                            size: a.id == selectedId ? 48 : 34,
                            selected: a.id == selectedId,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
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
                    onFilter: _openFilters,
                    activeFilters: state.mapFilter.advancedCount,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 20, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Mapa',
                        style: TextStyle(
                          fontFamily: AppColors.serif,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const MapNote('Ubicaciones aproximadas'),
                    ],
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: LocateButton(onTap: _locate),
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
                    onTap: _openDetail,
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

/// Aviso corto sobre el mapa (p. ej. "Ubicaciones aproximadas").
class MapNote extends StatelessWidget {
  final String text;
  const MapNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),
    );
  }
}
