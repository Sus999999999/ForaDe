import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/rounded_icon_button.dart';
import '../widgets/apartment_carousel.dart';
import '../widgets/locate_button.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/no_results_card.dart';
import '../widgets/search_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: AppScope.read(context).searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final results = state.searchResults;

    return Scaffold(
      backgroundColor: AppColors.mapBg,
      body: Stack(
        children: [
          const Positioned.fill(child: MapPlaceholder()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RoundedIconButton(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          Navigator.of(context).pushNamed(AppRoutes.menu);
                        },
                        child: const Icon(Icons.menu, color: AppColors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SearchField(
                          controller: _searchController,
                          onChanged: state.setSearchQuery,
                          onClear: () {
                            _searchController.clear();
                            state.setSearchQuery('');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Forade',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 165,
            child: LocateButton(
              onTap: () => showAppSnackBar(
                context,
                'Ubicación actual centrada',
                icon: Icons.my_location,
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 12,
            child: results.isEmpty
                ? const NoResultsCard()
                : ApartmentCarousel(
                    apartments: results,
                    onTap: (a) {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context)
                          .pushNamed(AppRoutes.apartmentDetail, arguments: a);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
