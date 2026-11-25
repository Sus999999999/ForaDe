import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/presentation/widgets/apartment_image.dart';

class ApartmentPreviewCard extends StatelessWidget {
  final Apartment apartment;
  final VoidCallback? onTap;
  const ApartmentPreviewCard({super.key, required this.apartment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final distanceLabel = AppScope.of(context).distanceLabel(apartment);
    final subtitle = distanceLabel == null
        ? apartment.location
        : '${apartment.location}, $distanceLabel';
    final stars = apartment.rating.round();

    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: ApartmentImage(
                  seed: apartment.id,
                  imageUrl: apartment.images.isNotEmpty
                      ? apartment.images.first
                      : null,
                  radius: 12,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      apartment.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatPrice(apartment.price),
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          '/mes',
                          style:
                              TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                        const Spacer(),
                        if (apartment.rating > 0)
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < stars
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 13,
                              color: AppColors.orange,
                            ),
                          )
                        else
                          const Text(
                            'Nuevo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orange,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
