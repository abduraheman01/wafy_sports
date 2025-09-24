import 'package:flutter/material.dart';
import 'package:sports_app/config/app_config.dart';

class FirebaseErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const FirebaseErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 48.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: isWeb ? 80 : 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: isWeb ? 24 : 16),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: isWeb ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: isWeb ? 16 : 12),
            Text(
              'Unable to load data. Please check your internet connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                color: Colors.grey[600],
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: isWeb ? 24 : 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 24 : 20,
                    vertical: isWeb ? 16 : 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyDataWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyDataWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.sports_soccer,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 48.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isWeb ? 80 : 64,
              color: Colors.grey[300],
            ),
            SizedBox(height: isWeb ? 24 : 16),
            Text(
              title,
              style: TextStyle(
                fontSize: isWeb ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isWeb ? 16 : 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = AppConfig.isWeb(screenWidth);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 48.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: isWeb ? 48 : 36,
              height: isWeb ? 48 : 36,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppConfig.primaryColor),
              ),
            ),
            if (message != null) ...[
              SizedBox(height: isWeb ? 24 : 16),
              Text(
                message!,
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final String fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    required this.fallbackAsset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      color: color,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
          color: color,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image_not_supported,
                size: (width ?? 40) * 0.6,
                color: Colors.grey[400],
              ),
            );
          },
        );
      },
    );
  }
}