import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/role_selection_screen.dart';

/// Pantalla de inicio: cabecera azul redondeada (igual que la pantalla de
/// selección de rol), logo PNG, nombre y un indicador de carga.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Tiempo que se muestra el splash antes de pasar a la app.
  static const duration = Duration(milliseconds: 2800);

  /// Tamaño del espacio reservado para tu imagen PNG.
  static const double logoSize = 110;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
    );

    // Aquí puedes cargar datos reales (sesión, preferencias, etc.)
    // antes de navegar. Por ahora solo espera un tiempo fijo.
    _timer = Timer(SplashScreen.duration, _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: AppRoutes.roleSelection),
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Cabecera azul marino plana
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: AppColors.navy,
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LogoSlot(),
                          SizedBox(height: 18),
                          Text(
                            'Forade',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Encuentra y publica departamentos',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Zona blanca con el indicador de carga
          Expanded(
            flex: 1,
            child: FadeTransition(
              opacity: _fade,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          color: AppColors.orange,
                          backgroundColor: AppColors.divider,
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Cargando...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Espacio para el logo PNG: círculo con contorno blanco, igual que el
/// avatar de las pantallas del diseño. Si el archivo todavía no existe,
/// muestra un ícono en su lugar.
class _LogoSlot extends StatelessWidget {
  const _LogoSlot();

  @override
  Widget build(BuildContext context) {
    const size = SplashScreen.logoSize;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white70, width: 1.5),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            AppAssets.splashLogo,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.image_outlined,
              color: Colors.white54,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
