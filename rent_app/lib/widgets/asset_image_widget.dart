import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AssetImageWidget extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final String? semanticLabel;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AssetImageWidget({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.semanticLabel,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the asset is an SVG file
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        colorFilter: color != null 
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        semanticsLabel: semanticLabel,
        placeholderBuilder: placeholder != null 
            ? (context) => placeholder!
            : null,
      );
    } else {
      // Handle regular images (PNG, JPEG, etc.)
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        color: color,
        semanticLabel: semanticLabel,
        errorBuilder: errorWidget != null 
            ? (context, error, stackTrace) => errorWidget!
            : null,
        frameBuilder: placeholder != null
            ? (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                }
                return placeholder!;
              }
            : null,
      );
    }
  }
}

// Specialized widgets for common use cases
class AppLogo extends StatelessWidget {
  final double? size;
  final Color? color;

  const AppLogo({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AssetImageWidget(
      assetPath: 'assets/images/logos/logo.svg',
      width: size,
      height: size,
      color: color,
      semanticLabel: 'RentApp Logo',
    );
  }
}

class AppIcon extends StatelessWidget {
  final String iconName;
  final double? size;
  final Color? color;

  const AppIcon({
    super.key,
    required this.iconName,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AssetImageWidget(
      assetPath: 'assets/images/icons/${iconName}_icon.svg',
      width: size,
      height: size,
      color: color ?? const Color(0xFFFFD700),
      semanticLabel: '$iconName icon',
    );
  }
}

class ProductPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProductPlaceholder({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return AssetImageWidget(
      assetPath: 'assets/images/placeholders/product_placeholder.svg',
      width: width,
      height: height,
      fit: fit,
      semanticLabel: 'Product placeholder',
    );
  }
}

class UserAvatar extends StatelessWidget {
  final double? size;
  final String? imageUrl;

  const UserAvatar({
    super.key,
    this.size = 40,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }
    
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return ClipOval(
      child: AssetImageWidget(
        assetPath: 'assets/images/placeholders/user_placeholder.svg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'User avatar',
      ),
    );
  }
}
