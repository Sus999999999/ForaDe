import 'package:flutter/material.dart';

import '../../../apartments/domain/models/apartment.dart';
import 'apartment_preview_card.dart';

class ApartmentCarousel extends StatefulWidget {
  final List<Apartment> apartments;
  final ValueChanged<Apartment> onTap;
  const ApartmentCarousel({
    super.key,
    required this.apartments,
    required this.onTap,
  });

  @override
  State<ApartmentCarousel> createState() => _ApartmentCarouselState();
}

class _ApartmentCarouselState extends State<ApartmentCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.94);

  @override
  void didUpdateWidget(covariant ApartmentCarousel old) {
    super.didUpdateWidget(old);
    // Si cambió el conjunto de resultados, volvemos a la primera tarjeta.
    final oldIds = old.apartments.map((a) => a.id).join(',');
    final newIds = widget.apartments.map((a) => a.id).join(',');
    if (oldIds != newIds && _controller.hasClients) {
      _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _controller,
        clipBehavior: Clip.none,
        itemCount: widget.apartments.length,
        itemBuilder: (_, i) {
          final a = widget.apartments[i];
          return Align(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ApartmentPreviewCard(
                apartment: a,
                onTap: () => widget.onTap(a),
              ),
            ),
          );
        },
      ),
    );
  }
}
