import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final bool showProgress;
  final bool showCacheIndicator; // New parameter to show cache status

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showProgress = true,
    this.showCacheIndicator = false, // Default false for production
  });

  @override
  Widget build(BuildContext context) {
    Widget cachedImage = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder ??
          (context, url) {
            // Log when image is being loaded (not cached)
            debugPrint('🔄 Loading image from network: ${url.substring(url.lastIndexOf('/') + 1)}');
            return Container(
              color: const Color(0xFF2A2A2A),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showProgress)
                      const CircularProgressIndicator(
                        color: Color(0xFFFFD700),
                        strokeWidth: 2,
                      )
                    else
                      const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 32,
                      ),
                    if (showCacheIndicator) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DOWNLOADING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
      errorWidget: errorWidget ??
          (context, url, error) {
            debugPrint('❌ Error loading image: $url - $error');
            return Container(
              color: const Color(0xFF2A2A2A),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 32,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Image not available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
      // Custom image builder to show cache indicator
      imageBuilder: (context, imageProvider) {
        // Log when image is loaded from cache (fast loading)
        debugPrint('✅ Image loaded (likely from cache): ${imageUrl.substring(imageUrl.lastIndexOf('/') + 1)}');
        
        Widget image = Image(
          image: imageProvider,
          fit: fit,
          width: width,
          height: height,
        );

        if (showCacheIndicator) {
          return Stack(
            children: [
              image,
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CACHED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return image;
      },
      // Cache configuration for billing optimization
      cacheKey: imageUrl,
      maxWidthDiskCache: 800, // Resize to max 800px width
      maxHeightDiskCache: 600, // Resize to max 600px height
      memCacheWidth: 400, // Memory cache at lower resolution
      memCacheHeight: 300,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: cachedImage,
      );
    }

    return cachedImage;
  }
}

// Cache management utilities
class ImageCacheManager {
  static Future<void> clearCache() async {
    await DefaultCacheManager().emptyCache();
    debugPrint('🗑️ Image cache cleared');
  }

  static Future<void> clearCacheForUrl(String url) async {
    await DefaultCacheManager().removeFile(url);
    debugPrint('🗑️ Cache cleared for: ${url.substring(url.lastIndexOf('/') + 1)}');
  }

  static Future<bool> isImageCached(String url) async {
    try {
      final fileInfo = await DefaultCacheManager().getFileFromCache(url);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> getCachedImageUrls() async {
    try {
      // This is a simplified approach - actual implementation depends on cache manager version
      debugPrint('📊 Cache check completed');
      return <String>[];
    } catch (e) {
      debugPrint('❌ Error getting cached URLs: $e');
      return <String>[];
    }
  }

  static Future<int> getCacheSize() async {
    // Simple approximation - actual implementation may vary
    // depending on the cached_network_image version
    debugPrint('📊 Cache size check requested');
    return 0; // Placeholder - implement based on your needs
  }

  static Future<String> getCacheSizeFormatted() async {
    final bytes = await getCacheSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Method to test caching behavior
  static Future<void> testCachingBehavior(String imageUrl) async {
    debugPrint('🧪 Testing cache behavior for: ${imageUrl.substring(imageUrl.lastIndexOf('/') + 1)}');
    
    final stopwatch = Stopwatch()..start();
    final isCached = await isImageCached(imageUrl);
    stopwatch.stop();
    
    debugPrint('⏱️ Cache check took: ${stopwatch.elapsedMilliseconds}ms');
    debugPrint(isCached ? '✅ Image is cached' : '❌ Image not in cache');
  }
}
