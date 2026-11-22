import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../map/presentation/widgets/map_pin.dart';

/// Mapa interactivo donde el rentero toca para colocar el pin de su departamento.
class LocationPicker extends StatefulWidget {
  final GeoPoint? value;
  final ValueChanged<GeoPoint> onChanged;
  final String? errorText;

  const LocationPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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
          height: 220,
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
                    initialZoom: 14.0,
                    onTap: (_, latLng) {
                      widget.onChanged(
                        GeoPoint(latLng.latitude, latLng.longitude),
                      );
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
                          ? 'Toca el mapa para colocar el pin'
                          : 'Toca en cualquier punto para mover el pin',
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
