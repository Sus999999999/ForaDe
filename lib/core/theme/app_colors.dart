import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Paleta del diseño: azul marino + naranja, fondos blancos y planos.
  static const navy = Color(0xFF0F2E5C);
  static const blue = Color(0xFF1B4E8F);
  static const orange = Color(0xFFF05A28);
  static const mapBg = Color(0xFFE5EDF9);
  static const mapBlock = Color(0xFFD2E0F2);
  static const mapBlockBorder = Color(0xFFC1D4EC);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);

  /// Líneas y bordes (azul muy claro, como en el diseño).
  static const divider = Color(0xFFD9E5F4);
  static const border = Color(0xFFD9E5F4);
  static const surfaceSoft = Color(0xFFF3F4F6);

  /// Relleno de la caja de imagen del formulario.
  static const uploadFill = Color(0xFFE7EFFA);

  /// Fondo de la franja derecha del menú lateral.
  static const menuStrip = Color(0xFF0C1F3A);

  /// Color de la opción activa del menú ("Inicio").
  static const menuActive = Color(0xFF3F72AC);

  /// Parte baja del degradado de la foto en el detalle.
  static const photoShade = Color(0xFFA3A7AD);

  /// Familia tipográfica para títulos (serif, como en el diseño).
  static const serif = 'serif';

  /// El diseño es plano (sin degradados): se conservan los nombres para no
  /// romper el código existente, pero ambos colores son iguales.
  static const brandGradient = LinearGradient(
    colors: [orange, orange],
  );

  static const blueGradient = LinearGradient(
    colors: [navy, navy],
  );

  static const softShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
}
