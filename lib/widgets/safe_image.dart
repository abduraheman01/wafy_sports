import 'package:flutter/material.dart';
import 'package:sports_app/config/app_config.dart';

class SafeImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final Widget? fallbackWidget;

  const SafeImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);

    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        if (fallbackWidget != null) {
          return fallbackWidget!;
        }

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: (width ?? height ?? 40) * 0.4,
                color: Colors.grey[400],
              ),
              if (isWeb && (width ?? 0) > 40) ...[
                const SizedBox(height: 4),
                Text(
                  'No Image',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class TeamLogo extends StatelessWidget {
  final String logoFileName;
  final double? size;
  final Color? color;

  const TeamLogo({
    super.key,
    required this.logoFileName,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final actualSize = size ?? 40.0;

    return SafeImage(
      imagePath: logoFileName,
      width: actualSize,
      height: actualSize,
      color: color,
      fallbackWidget: Container(
        width: actualSize,
        height: actualSize,
        decoration: BoxDecoration(
          color: AppConfig.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppConfig.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.shield,
          size: actualSize * 0.6,
          color: color ?? AppConfig.primaryColor,
        ),
      ),
    );
  }
}