import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Acceso rápido: icono + texto dentro de una tarjeta.
class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const QuickAction(this.icon, this.label, this.onTap);
}

class QuickActionsRow extends StatelessWidget {
  final List<QuickAction> actions;
  const QuickActionsRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _ActionTile(action: actions[i])),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final QuickAction action;
  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.divider),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: action.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(action.icon, color: AppColors.orange, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de sección con enlace opcional "Ver todos".
class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const DashboardSectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: AppColors.serif,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mensaje cuando una sección no tiene contenido, con acción opcional.
class DashboardHint extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const DashboardHint({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: AppColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              PrimaryButton(
                label: actionLabel!,
                expand: false,
                height: 42,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Recuadro con un número y su etiqueta (resúmenes).
class StatBox extends StatelessWidget {
  final String value;
  final String label;
  const StatBox({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppColors.serif,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  final List<StatBox> boxes;
  const StatRow({super.key, required this.boxes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < boxes.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: boxes[i]),
          ],
        ],
      ),
    );
  }
}
