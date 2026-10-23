import 'package:flutter/material.dart';

import '../../../../shared/widgets/section_title.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/presentation/widgets/apartment_card.dart';

/// Título + carrusel horizontal de tarjetas.
class ApartmentSection extends StatelessWidget {
  final String title;
  final List<Apartment> apartments;
  final ValueChanged<Apartment> onTap;

  const ApartmentSection({
    super.key,
    required this.title,
    required this.apartments,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(title),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final a in apartments)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: ApartmentCard(
                    apartment: a,
                    width: 250,
                    onTap: () => onTap(a),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
