import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';

class AddApartmentScreen extends StatefulWidget {
  const AddApartmentScreen({super.key});

  @override
  State<AddApartmentScreen> createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  @override
  void initState() {
    super.initState();
    // Esta pantalla ha sido reemplazada por ApartmentFormScreen.
    // Redirigimos al formulario moderno al iniciar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.apartmentForm);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
