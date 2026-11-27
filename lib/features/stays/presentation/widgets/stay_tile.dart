import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../apartments/presentation/widgets/apartment_image.dart';
import '../../domain/models/stay.dart';

/// Tarjeta de una estancia: departamento, fechas y tiempo hospedado.
class StayTile extends StatelessWidget {
  final Stay stay;
  final bool isOwnerView;
  final VoidCallback? onTap;
  const StayTile({
    super.key,
    required this.stay,
    this.isOwnerView = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final length = stay.lengthAt(DateTime.now());
    final range = stay.isActive
        ? 'Desde el ${formatDate(stay.startDate)}'
        : '${formatDate(stay.startDate)} – ${formatDate(stay.endDate!)}';

    final displayName =
        stay.renterName.isNotEmpty ? stay.renterName : 'Usuario';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ApartmentImage(
                  seed: stay.apartmentId, iconSize: 28, radius: 4),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isOwnerView ? displayName : stay.apartmentTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (stay.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Actual',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (isOwnerView) ...[
                    Row(
                      children: [
                        const Icon(Icons.home_work_outlined,
                            size: 14, color: AppColors.navy),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Rentó: ${stay.apartmentTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    stay.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    range,
                    style:
                        const TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 15, color: AppColors.blue),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          isOwnerView
                              ? (stay.isActive
                                  ? 'Tiempo rentado: ${length.label}'
                                  : 'Rentado durante: ${length.label}')
                              : (stay.isActive
                                  ? 'Hospedado: ${length.label}'
                                  : 'Se hospedó: ${length.label}'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isOwnerView
                        ? '${formatPrice(stay.monthlyPrice)} / mes'
                        : '${formatPrice(stay.monthlyPrice)} / mes · ${stay.hostName}',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
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
