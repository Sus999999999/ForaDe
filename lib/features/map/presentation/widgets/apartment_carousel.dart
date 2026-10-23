import 'package:flutter/material.dart';

import '../../../apartments/domain/models/apartment.dart';
import 'apartment_preview_card.dart';

/// Carrusel de tarjetas sincronizado con el pin seleccionado del mapa.
class ApartmentCarousel extends StatefulWidget {
  final List<Apartment> apartments;
  final String? selectedId;
  final ValueChanged<Apartment> onSelected;
  final ValueChanged<Apartment> onTap;

  const ApartmentCarousel({
    super.key,
    required this.apartments,
    required this.selectedId,
    required this.onSelected,
    required this.onTap,
  });

  @override
  State<ApartmentCarousel> createState() => _ApartmentCarouselState();
}

class _ApartmentCarouselState extends State<ApartmentCarousel> {
  late final PageController _controller;

  int _indexOf(String? id) {
    final i = widget.apartments.indexWhere((a) => a.id == id);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.94,
      initialPage: _indexOf(widget.selectedId),
    );
  }

  @override
  void didUpdateWidget(covariant ApartmentCarousel old) {
    super.didUpdateWidget(old);
    // Si se tocó un pin (o cambiaron los resultados), movemos el carrusel.
    // Se hace después del frame para no notificar durante la construcción.
    final target = _indexOf(widget.selectedId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (_controller.position.isScrollingNotifier.value) return;
      final current = _controller.page?.round() ?? target;
      if (current != target && target < widget.apartments.length) {
        _controller.jumpToPage(target);
      }
    });
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
        onPageChanged: (i) {
          if (i < widget.apartments.length) {
            widget.onSelected(widget.apartments[i]);
          }
        },
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
