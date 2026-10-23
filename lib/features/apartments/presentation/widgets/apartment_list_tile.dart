import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/apartment.dart';
import 'apartment_image.dart';

/// Fila compacta (listas de gestión: Mis departamentos, Administración).
class ApartmentListTile extends StatelessWidget {
  final Apartment apartment;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? extraLine;
  const ApartmentListTile({
    super.key,
    required this.apartment,
    required this.onTap,
    this.trailing,
    this.extraLine,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ApartmentImage(
                seed: apartment.id,
                iconSize: 28,
                radius: 4,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apartment.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    apartment.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatPrice(apartment.price)} / mes',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  if (extraLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      extraLine!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
