import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/snackbar.dart';

/// Abre un selector para tomar una foto o elegirla de la galería y subirla a Supabase.
Future<void> pickAndUploadAvatar(BuildContext context) async {
  final picker = ImagePicker();
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Foto de perfil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: AppColors.navy),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: AppColors.navy),
              title: const Text('Tomar foto con la cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null || !context.mounted) return;

  final file =
      await picker.pickImage(source: source, imageQuality: 85, maxWidth: 600);
  if (file == null || !context.mounted) return;

  showAppSnackBar(context, 'Subiendo foto de perfil...',
      icon: Icons.cloud_upload_outlined);
  final bytes = await file.readAsBytes();
  final url = await AppScope.read(context).uploadProfileAvatar(bytes);

  if (!context.mounted) return;
  if (url != null) {
    showAppSnackBar(context, 'Foto de perfil actualizada',
        icon: Icons.check_circle);
  } else {
    showAppSnackBar(context, 'No se pudo subir la foto de perfil',
        icon: Icons.error_outline);
  }
}

/// Avatar circular del usuario con soporte para imagen remota (caché),
/// iniciales de respaldo y badge opcional para cambiar foto.
class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.size = 70,
    this.onTap,
    this.showEditBadge = false,
  });

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed.substring(0, 1).toUpperCase();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceSoft,
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (avatarUrl.isNotEmpty) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildPlaceholder(),
          errorWidget: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    } else {
      avatar = _buildPlaceholder();
    }

    if (!showEditBadge && onTap == null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: avatar,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: avatar,
          ),
          if (showEditBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
