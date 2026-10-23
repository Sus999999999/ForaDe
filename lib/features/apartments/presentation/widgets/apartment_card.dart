import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar.dart';
import '../../domain/models/apartment.dart';
import 'apartment_image.dart';

/// Tarjeta vertical estilo Airbnb: imagen grande, corazón y datos debajo.
class ApartmentCard extends StatelessWidget {
  final Apartment apartment;
  final double? width;
  final double aspectRatio;
  final VoidCallback onTap;

  const ApartmentCard({
    super.key,
    required this.apartment,
    required this.onTap,
    this.width,
    this.aspectRatio = 4 / 3,
  });

  String? get _tag {
    if (!apartment.isAvailable) return 'No disponible';
    if (apartment.rating == 0) return 'Nuevo';
    if (apartment.rating >= 4.8) return 'Popular';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final a = apartment;
    final isFav = state.isFavorite(a.id);
    final tag = _tag;
    final subtitle =
        a.distanceLabel == null ? a.location : '${a.location} · ${a.distanceLabel}';

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: ApartmentImage(
              seed: a.id,
              child: Stack(
                children: [
                  if (tag != null)
                    Positioned(left: 10, top: 10, child: _Tag(label: tag)),
                  if (state.canFavorite)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _HeartButton(
                        isFavorite: isFav,
                        onTap: () {
                          final added = state.toggleFavorite(a.id);
                          showAppSnackBar(
                            context,
                            added
                                ? 'Agregado a favoritos'
                                : 'Eliminado de favoritos',
                            icon: added
                                ? Icons.favorite
                                : Icons.heart_broken_outlined,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  a.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (a.rating > 0) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star_rounded, size: 15, color: AppColors.text),
                const SizedBox(width: 2),
                Text(
                  '${a.rating}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatPrice(a.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const TextSpan(
                  text: ' / mes',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  const _HeartButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: isFavorite ? AppColors.orange : AppColors.text,
          ),
        ),
      ),
    );
  }
}
