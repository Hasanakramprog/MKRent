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
    // Clean the image URL to remove any authentication parameters that might cause issues
    String cleanImageUrl = imageUrl;
    if (imageUrl.contains('firebasestorage.googleapis.com')) {
      // For Firebase Storage URLs, ensure we use the public access format
      final uri = Uri.parse(imageUrl);
      if (!uri.queryParameters.containsKey('alt') || uri.queryParameters['alt'] != 'media') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 4 && pathSegments[0] == 'v0' && pathSegments[1] == 'b' && pathSegments[3] == 'o') {
          // Reconstruct URL with proper alt=media parameter for public access
          final bucket = pathSegments[2];
          final filePath = pathSegments.skip(4).join('/');
          cleanImageUrl = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(filePath)}?alt=media';
          debugPrint('🔧 Cleaned Firebase Storage URL: $cleanImageUrl');
        }
      }
    }

    Widget cachedImage = CachedNetworkImage(
      imageUrl: cleanImageUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: const {
        // Don't send any authentication headers for public images
        'Cache-Control': 'max-age=3600',
      },
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

  static Future<void> clearFirebaseStorageCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      // Also evict all CachedNetworkImage cache
      await CachedNetworkImage.evictFromCache('');
      debugPrint('🗑️ Firebase Storage image cache cleared completely');
    } catch (e) {
      debugPrint('❌ Error clearing Firebase Storage cache: $e');
    }
  }

  static Future<void> clearCacheForUrl(String url) async {
    try {
      await DefaultCacheManager().removeFile(url);
      await CachedNetworkImage.evictFromCache(url);
      debugPrint('🗑️ Cache cleared for: ${url.substring(url.lastIndexOf('/') + 1)}');
    } catch (e) {
      debugPrint('❌ Error clearing cache for URL: $e');
    }
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
    try {
      final size = await getCacheSize();
      if (size > 1024 * 1024) {
        return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else if (size > 1024) {
        return '${(size / 1024).toStringAsFixed(1)} KB';
      } else {
        return '$size bytes';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  static Future<void> testCachingBehavior(String testUrl) async {
    debugPrint('🧪 Testing caching behavior for: $testUrl');
    
    // Clear cache for test URL first
    await clearCacheForUrl(testUrl);
    
    // Test if URL is accessible
    try {
      final cached = await isImageCached(testUrl);
      debugPrint('🧪 Initial cache state: ${cached ? 'CACHED' : 'NOT CACHED'}');
    } catch (e) {
      debugPrint('🧪 Cache test error: $e');
    }
  }
}
