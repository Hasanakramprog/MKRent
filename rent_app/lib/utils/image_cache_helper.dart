import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageCacheHelper {
  /// Clear all cached images
  static Future<void> clearAllImageCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      // Also clear the CachedNetworkImage cache
      await CachedNetworkImage.evictFromCache('');
      print('✅ Image cache cleared successfully');
    } catch (e) {
      print('❌ Error clearing image cache: $e');
    }
  }

  /// Clear cache for a specific image URL
  static Future<void> clearImageCache(String imageUrl) async {
    try {
      await DefaultCacheManager().removeFile(imageUrl);
      await CachedNetworkImage.evictFromCache(imageUrl);
      print('✅ Cache cleared for image: $imageUrl');
    } catch (e) {
      print('❌ Error clearing cache for image: $e');
    }
  }

  /// Get cache info
  static Future<void> getCacheInfo() async {
    try {
      final cacheManager = DefaultCacheManager();
      final cacheFiles = await cacheManager.getFileFromCache('');
      print('📊 Cache info: ${cacheFiles?.validTill}');
    } catch (e) {
      print('❌ Error getting cache info: $e');
    }
  }
}
