import 'package:flutter/material.dart';
import 'package:open_station/theme/app_theme.dart';

class StationArtwork extends StatelessWidget {
  final String? faviconUrl;
  final double size;
  final BorderRadius borderRadius;

  const StationArtwork({
    super.key,
    this.faviconUrl,
    this.size = 48,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context) {
    final validUrl = faviconUrl != null && faviconUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size,
        height: size,
        color: AppColors.raisedSlate,
        child: validUrl
            ? Image.network(
                faviconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder(isLoading: true);
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Container(
      color: AppColors.raisedSlate,
      alignment: Alignment.center,
      child: isLoading
          ? SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.signalBlue,
              ),
            )
          : Icon(
              Icons.radio,
              size: size * 0.5,
              color: AppColors.mutedText,
            ),
    );
  }
}
