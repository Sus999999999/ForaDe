import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/routes/slide_left_route.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/domain/models/apartment_status.dart';
import '../../../apartments/presentation/widgets/apartment_list_tile.dart';
import '../../../apartments/presentation/widgets/status_chip.dart';
import '../../../chat/domain/models/chat_models.dart';
import '../../../chat/presentation/widgets/conversation_tile.dart';
import '../../../home/presentation/widgets/apartment_section.dart';
import '../../../home/presentation/widgets/welcome_banner.dart';
import '../../../menu/presentation/screens/menu_screen.dart';
import '../widgets/dashboard_widgets.dart';

/// Pantalla de entrada tras iniciar sesión. Cambia según el tipo de usuario:
/// quien busca, quien publica o el administrador.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _openMenu(BuildContext context) {
    Navigator.of(context).push(
      slideLeftRoute<void>(
        const MenuScreen(),
        const RouteSettings(name: '/menu'),
      ),
    );
  }

  void _go(BuildContext context, String route, [Object? args]) =>
      Navigator.of(context).pushNamed(route, arguments: args);

  void _openDetail(BuildContext context, Apartment a) =>
      _go(context, AppRoutes.apartmentDetail, a);

  Future<void> _enableLocation(BuildContext context) async {
    final state = AppScope.read(context);
    final ok = await state.enableLocation();
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      ok ? 'Ubicación activada' : 'No se pudo obtener tu ubicación',
      icon: ok ? Icons.my_location : Icons.location_off_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final first = state.profile.name.trim().split(' ').first;
    final greeting = first.isEmpty ? 'Hola' : 'Hola, $first';

    final List<Widget> content;
    final List<QuickAction> actions;
    final String subtitle;

    if (state.isAdmin) {
      subtitle =
          'Hay ${state.apartments.length} departamentos y ${state.users.length} usuarios en la plataforma.';
      actions = [
        QuickAction(Icons.manage_accounts_outlined, 'Usuarios',
            () => _go(context, AppRoutes.admin)),
        QuickAction(Icons.apartment, 'Departamentos',
            () => _go(context, AppRoutes.apartments)),
        QuickAction(
            Icons.map_outlined, 'Mapa', () => _go(context, AppRoutes.map)),
      ];
      content = _adminSections(context, state);
    } else if (state.canPublish) {
      subtitle = 'Publica un nuevo departamento y llega a más personas.';
      actions = [
        QuickAction(Icons.add_home_work_outlined, 'Publicar',
            () => _go(context, AppRoutes.apartmentForm)),
        QuickAction(Icons.apartment, 'Anuncios',
            () => _go(context, AppRoutes.apartments)),
        QuickAction(Icons.chat_bubble_outline, 'Mensajes',
            () => _go(context, AppRoutes.chats)),
      ];
      content = _publisherSections(context, state);
    } else {
      subtitle = 'Encuentra tu próximo hogar en tu zona favorita.';
      actions = [
        QuickAction(Icons.search_rounded, 'Buscar',
            () => _go(context, AppRoutes.apartments)),
        QuickAction(
            Icons.map_outlined, 'Mapa', () => _go(context, AppRoutes.map)),
        QuickAction(Icons.favorite_border, 'Favoritos',
            () => _go(context, AppRoutes.favorites)),
      ];
      content = _searcherSections(context, state);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openMenu(context),
                      child: Ink(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.menu,
                            size: 24, color: AppColors.navy),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontFamily: AppColors.serif,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: WelcomeBanner(title: greeting, subtitle: subtitle),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: QuickActionsRow(actions: actions),
            ),
            const SizedBox(height: 28),
            ...content,
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Quien busca
  // ------------------------------------------------------------------
  List<Widget> _searcherSections(BuildContext context, AppState state) {
    final nearby = state.nearbyApartments();
    final favorites = state.recentFavorites(limit: 5);
    final sent = state.sentChats.take(3).toList();

    return [
      if (!state.locationEnabled) ...[
        const DashboardSectionHeader('Cerca de ti'),
        DashboardHint(
          icon: Icons.location_on_outlined,
          message:
              'Activa tu ubicación para ver los departamentos disponibles más cercanos.',
          actionLabel: 'Activar ubicación',
          onAction: () => _enableLocation(context),
        ),
      ] else if (nearby.isEmpty) ...[
        const DashboardSectionHeader('Cerca de ti'),
        const DashboardHint(
          icon: Icons.search_off,
          message: 'No hay departamentos disponibles cerca de ti por ahora.',
        ),
      ] else
        ApartmentSection(
          title: 'Cerca de ti',
          apartments: nearby,
          onTap: (a) => _openDetail(context, a),
        ),
      const SizedBox(height: 28),
      if (favorites.isEmpty) ...[
        const DashboardSectionHeader('Favoritos recientes'),
        DashboardHint(
          icon: Icons.favorite_border,
          message: 'Toca el corazón de un departamento para guardarlo aquí.',
          actionLabel: 'Buscar departamentos',
          onAction: () => _go(context, AppRoutes.apartments),
        ),
      ] else
        ApartmentSection(
          title: 'Favoritos recientes',
          apartments: favorites,
          onTap: (a) => _openDetail(context, a),
        ),
      const SizedBox(height: 28),
      DashboardSectionHeader(
        'Mensajes enviados',
        actionLabel: sent.isEmpty ? null : 'Ver todos',
        onAction: () => _go(context, AppRoutes.chats),
      ),
      if (sent.isEmpty)
        const DashboardHint(
          icon: Icons.chat_bubble_outline,
          message:
              'Aún no has contactado a ningún publicador. Abre un departamento y toca "Contactar".',
        )
      else
        ..._conversations(context, sent),
    ];
  }

  // ------------------------------------------------------------------
  // Quien publica
  // ------------------------------------------------------------------
  List<Widget> _publisherSections(BuildContext context, AppState state) {
    final mine = state.myApartments;
    int count(ApartmentStatus s) => mine.where((a) => a.status == s).length;
    final others = count(ApartmentStatus.noDisponible) +
        count(ApartmentStatus.inactivo);
    final received = state.receivedChats.take(3).toList();

    return [
      StatRow(boxes: [
        StatBox(
            value: '${count(ApartmentStatus.disponible)}',
            label: 'Disponibles'),
        StatBox(
            value: '${count(ApartmentStatus.ocupado)}', label: 'Ocupados'),
        StatBox(value: '$others', label: 'Otros'),
      ]),
      const SizedBox(height: 28),
      DashboardSectionHeader(
        'Mis departamentos',
        actionLabel: mine.isEmpty ? null : 'Administrar',
        onAction: () => _go(context, AppRoutes.apartments),
      ),
      if (mine.isEmpty)
        DashboardHint(
          icon: Icons.apartment_outlined,
          message: 'Todavía no has publicado departamentos.',
          actionLabel: 'Publicar departamento',
          onAction: () => _go(context, AppRoutes.apartmentForm),
        )
      else
        for (final a in mine.take(4))
          ApartmentListTile(
            apartment: a,
            badge: StatusChip(status: a.status),
            onTap: () => _openDetail(context, a),
          ),
      const SizedBox(height: 28),
      DashboardSectionHeader(
        'Contactos recibidos',
        actionLabel: received.isEmpty ? null : 'Ver todos',
        onAction: () => _go(context, AppRoutes.chats),
      ),
      if (received.isEmpty)
        const DashboardHint(
          icon: Icons.mark_email_unread_outlined,
          message: 'Cuando alguien te contacte por un departamento aparecerá aquí.',
        )
      else
        ..._conversations(context, received),
    ];
  }

  // ------------------------------------------------------------------
  // Administrador
  // ------------------------------------------------------------------
  List<Widget> _adminSections(BuildContext context, AppState state) {
    int count(ApartmentStatus s) =>
        state.apartments.where((a) => a.status == s).length;
    return [
      StatRow(boxes: [
        StatBox(value: '${state.users.length}', label: 'Usuarios'),
        StatBox(value: '${state.apartments.length}', label: 'Departamentos'),
      ]),
      const SizedBox(height: 14),
      StatRow(boxes: [
        StatBox(
            value: '${count(ApartmentStatus.disponible)}',
            label: 'Disponibles'),
        StatBox(
            value: '${count(ApartmentStatus.ocupado)}', label: 'Ocupados'),
        StatBox(
            value: '${count(ApartmentStatus.noDisponible) + count(ApartmentStatus.inactivo)}',
            label: 'Otros'),
      ]),
    ];
  }

  List<Widget> _conversations(
      BuildContext context, List<ChatConversation> chats) {
    return [
      for (final c in chats)
        ConversationTile(
          chat: c,
          onTap: () => _go(context, AppRoutes.chat, c.id),
        ),
    ];
  }
}
