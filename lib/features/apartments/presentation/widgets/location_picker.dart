import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../../core/geo/osm_geocoding_service.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../map/presentation/widgets/map_pin.dart';

/// Mapa interactivo donde el rentero coloca o afina el pin exacto de su departamento,
/// con soporte de GPS satelital nativo, zoom de alta resolución y geocodificación inversa.
class LocationPicker extends StatefulWidget {
  final GeoPoint? value;
  final ValueChanged<GeoPoint> onChanged;
  final ValueChanged<LocationSuggestion>? onAddressResolved;
  final String? errorText;

  const LocationPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.onAddressResolved,
    this.errorText,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final MapController _mapController;
  late final OsmGeocodingService _geoService;
  bool _locating = false;
  Timer? _reverseDebounce;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _geoService = OsmGeocodingService();
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _geoService.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final val = widget.value;
    if (val != null &&
        (oldWidget.value == null ||
            val.lat != oldWidget.value!.lat ||
            val.lng != oldWidget.value!.lng)) {
      try {
        _mapController.move(
          LatLng(val.lat, val.lng),
          _mapController.camera.zoom < 15 ? 16.5 : _mapController.camera.zoom,
        );
      } catch (_) {}
    }
  }

  void _triggerReverseGeocode(GeoPoint point) {
    if (widget.onAddressResolved == null) return;
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 500), () async {
      final suggestion = await _geoService.reverseGeocode(point);
      if (mounted && suggestion != null) {
        widget.onAddressResolved!(suggestion);
      }
    });
  }

  Future<void> _locateCurrentPosition() async {
    if (_locating) return;
    setState(() => _locating = true);

    try {
      final state = AppScope.read(context);
      final ok = await state.enableLocation();
      final point = state.userLocation;

      if (!mounted) return;

      if (ok && point != null) {
        widget.onChanged(point);
        _mapController.move(LatLng(point.lat, point.lng), 17.5);
        _triggerReverseGeocode(point);

        showAppSnackBar(
          context,
          'Ubicación GPS obtenida con alta precisión',
          icon: Icons.my_location,
        );
      } else {
        showAppSnackBar(
          context,
          'No se pudo obtener el GPS. Verifica que los permisos de ubicación estén activos.',
          icon: Icons.location_off,
        );
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Error al consultar el sensor GPS del dispositivo.',
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const pinSize = 38.0;
    final value = widget.value;
    final hasError = widget.errorText != null;

    final start = widget.value ??
        AppScope.read(context).userLocation ??
        GeoPoint.defaultCenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? Colors.red.shade400 : AppColors.border,
              width: hasError ? 1.6 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(start.lat, start.lng),
                    initialZoom: 14.5,
                    maxZoom: 18.5,
                    minZoom: 4.0,
                    onTap: (_, latLng) {
                      final point =
                          GeoPoint(latLng.latitude, latLng.longitude);
                      widget.onChanged(point);
                      _triggerReverseGeocode(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.forade.app',
                    ),
                    if (value != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(value.lat, value.lng),
                            width: pinSize,
                            height: pinSize * 1.25,
                            alignment: Alignment.topCenter,
                            child: const MapPin(size: pinSize, selected: true),
                          ),
                        ],
                      ),
                  ],
                ),

                // Botón GPS: Mi ubicación actual
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _locating ? null : _locateCurrentPosition,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_locating)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.orange,
                                ),
                              )
                            else
                              const Icon(
                                Icons.my_location,
                                size: 16,
                                color: AppColors.orange,
                              ),
                            const SizedBox(width: 6),
                            const Text(
                              'Mi ubicación GPS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Controles de zoom (+ / -) para acercarse al techo o predio exacto
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MapControlButton(
                        icon: Icons.add,
                        tooltip: 'Acercar',
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          final nextZoom = (currentZoom + 1).clamp(4.0, 18.5);
                          _mapController.move(
                              _mapController.camera.center, nextZoom);
                        },
                      ),
                      const SizedBox(height: 5),
                      _MapControlButton(
                        icon: Icons.remove,
                        tooltip: 'Alejar',
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          final nextZoom = (currentZoom - 1).clamp(4.0, 18.5);
                          _mapController.move(
                              _mapController.camera.center, nextZoom);
                        },
                      ),
                    ],
                  ),
                ),

                // Etiqueta informativa inferior
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      value == null
                          ? 'Toca el mapa o usa GPS para colocar el pin'
                          : 'Toca en el techo/predio para afinar',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              widget.errorText!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade600),
            ),
          ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 20, color: AppColors.navy),
        ),
      ),
    );
  }
}
