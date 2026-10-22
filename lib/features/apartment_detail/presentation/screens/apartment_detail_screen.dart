import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/host_info.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../widgets/availability_chip.dart';

class ApartmentDetailScreen extends StatelessWidget {
  final Apartment apartment;
  const ApartmentDetailScreen({super.key, required this.apartment});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isFav = state.isFavorite(apartment.id);

    final subtitle = apartment.rating > 0
        ? '${apartment.location} • ${apartment.rating} ★'
        : '${apartment.location} • Nuevo';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: AppColors.orange,
            ),
            onPressed: () {
              final added = state.toggleFavorite(apartment.id);
              showAppSnackBar(
                context,
                added ? 'Agregado a favoritos' : 'Eliminado de favoritos',
                icon: added ? Icons.favorite : Icons.heart_broken_outlined,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              color: AppColors.surfaceSoft,
              child: const Center(
                child: Icon(Icons.image, size: 80, color: AppColors.muted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apartment.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${formatPrice(apartment.price)} / mes',
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue,
                        ),
                      ),
                      AvailabilityChip(
                        label: apartment.isAvailable
                            ? 'Disponible ahora'
                            : 'No disponible',
                        active: apartment.isAvailable,
                      ),
                    ],
                  ),
                  const Divider(height: 30, color: AppColors.divider),
                  HostInfo(
                    name: apartment.hostName,
                    subtitle: apartment.hostSubtitle,
                  ),
                  const SizedBox(height: 20),
                  const SectionLabel('DESCRIPCIÓN', fontSize: 14),
                  const SizedBox(height: 8),
                  Text(
                    apartment.description,
                    style:
                        const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 30),
                  PrimaryButton(
                    label: 'Contactar',
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.contact,
                      arguments: apartment,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
