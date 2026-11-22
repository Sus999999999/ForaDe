import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/host_info.dart';
import '../../../../shared/widgets/outlined_action_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/domain/models/apartment_status.dart';
import '../../../apartments/presentation/widgets/rating_stars.dart';
import '../../../map/presentation/widgets/map_pin.dart';
import '../../../apartments/presentation/widgets/status_chip.dart';
import '../widgets/photo_grid.dart';

class ApartmentDetailScreen extends StatelessWidget {
  final Apartment apartment;
  const ApartmentDetailScreen({super.key, required this.apartment});

  Widget _action(BuildContext context, AppState state, Apartment a) {
    // El administrador gestiona cuentas: aquí solo consulta.
    if (state.isAdmin) {
      return _InfoBox(
          label: 'Vista de administrador · ${a.status.label}');
    }
    // Solo quien publicó puede editar.
    if (a.ownerId == state.profile.id) {
      return PrimaryButton(
        label: 'Editar departamento',
        onPressed: () => Navigator.of(context)
            .pushNamed(AppRoutes.apartmentForm, arguments: a),
      );
    }
    // Si ya hay una conversación con este rentero, se abre directamente.
    final chat = state.chatFor(a);
    if (chat != null) {
      return PrimaryButton(
        label: 'Abrir chat',
        onPressed: () => Navigator.of(context)
            .pushNamed(AppRoutes.chat, arguments: chat.id),
      );
    }
    if (!a.isAvailable) {
      return _InfoBox(label: 'Este departamento no está disponible');
    }
    return PrimaryButton(
      label: 'Contactar',
      onPressed: () => Navigator.of(context)
          .pushNamed(AppRoutes.contact, arguments: a),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    // Siempre mostramos la versión más reciente (por si el admin la editó).
    final a = state.apartmentById(apartment.id) ?? apartment;
    final isFav = state.isFavorite(a.id);
    final exact = state.canSeeExactLocation(a);
    final distance = state.distanceLabel(a);
    final top = MediaQuery.of(context).padding.top + 8;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto a todo el ancho con los botones encima.
            Stack(
              children: [
                PhotoGrid(seed: a.id),
                Positioned(
                  top: top,
                  left: 20,
                  child: _OverlayButton(
                    tooltip: 'Regresar',
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.chevron_left,
                        size: 26, color: AppColors.navy),
                  ),
                ),
                if (state.canFavorite)
                  Positioned(
                    top: top,
                    right: 20,
                    child: _OverlayButton(
                      tooltip:
                          isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
                      onTap: () {
                        final added = state.toggleFavorite(a.id);
                        showAppSnackBar(
                          context,
                          added ? 'Agregado a favoritos' : 'Eliminado de favoritos',
                          icon: added
                              ? Icons.favorite
                              : Icons.heart_broken_outlined,
                        );
                      },
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 22,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: const TextStyle(
                      fontFamily: AppColors.serif,
                      fontSize: 28,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (a.rating > 0) ...[
                        RatingStars(rating: a.rating, size: 14),
                        const SizedBox(width: 10),
                        Text(
                          '${a.rating}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                      ] else
                        const Text(
                          'Nuevo',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.orange,
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 34, color: AppColors.divider),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        formatPrice(a.price),
                        style: const TextStyle(
                          fontFamily: AppColors.serif,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const Text(
                        ' / mes',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                      const Spacer(),
                      StatusChip(status: a.status, large: true),
                    ],
                  ),
                  const Divider(height: 34, color: AppColors.divider),
                  HostInfo(name: a.hostName, subtitle: a.hostSubtitle),
                  const SizedBox(height: 26),
                  const SectionLabel('Descripción'),
                  const SizedBox(height: 10),
                  Text(
                    a.description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const Divider(height: 34, color: AppColors.divider),
                  const SectionLabel('Ubicación'),
                  const SizedBox(height: 6),
                  Text(
                    distance == null ? a.location : '${a.location} · $distance',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  if (exact) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 18, color: AppColors.navy),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            a.address,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            a.approxPoint.lat,
                            a.approxPoint.lng,
                          ),
                          initialZoom: 14.5,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.forade.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  a.approxPoint.lat,
                                  a.approxPoint.lng,
                                ),
                                width: 36,
                                height: 36 * 1.25,
                                alignment: Alignment.topCenter,
                                child: const MapPin(size: 36, selected: true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exact
                        ? 'Ubicación exacta.'
                        : 'Ubicación aproximada. La dirección exacta se comparte cuando el publicador responde a tu mensaje.',
                    style: const TextStyle(
                        fontSize: 12, height: 1.4, color: AppColors.muted),
                  ),
                  if (a.isAvailable) ...[
                    const SizedBox(height: 14),
                    OutlinedActionButton(
                      label: 'Ver en el mapa',
                      height: 50,
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.map, arguments: a.id),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        action: _action(context, state, a),
      ),
    );
  }
}

/// Botón cuadrado semitransparente que se coloca sobre la foto.
class _OverlayButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  const _OverlayButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xE6FFF7F1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Center(child: child)),
        ),
      ),
    );
  }
}

/// Recuadro gris con un mensaje en lugar del botón principal.
class _InfoBox extends StatelessWidget {
  final String label;
  const _InfoBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          fontSize: 14,
        ),
      ),
    );
  }
}
