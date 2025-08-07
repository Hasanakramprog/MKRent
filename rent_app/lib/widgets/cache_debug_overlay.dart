import 'package:flutter/material.dart';
import 'cached_image_widget.dart';

class CacheDebugOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const CacheDebugOverlay({
    super.key,
    required this.child,
    this.enabled = false, // Only enable in debug mode
  });

  @override
  State<CacheDebugOverlay> createState() => _CacheDebugOverlayState();
}

class _CacheDebugOverlayState extends State<CacheDebugOverlay> {
  bool _showDebugInfo = false;
  String _cacheInfo = 'Tap to check cache';

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 100,
          right: 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
              });
              if (_showDebugInfo) {
                _updateCacheInfo();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'CACHE DEBUG',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_showDebugInfo) ...[
                    const SizedBox(height: 4),
                    Text(
                      _cacheInfo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• Green badge = Cached\n'
                      '• Orange badge = Downloading\n'
                      '• Check console for logs',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateCacheInfo() async {
    try {
      final size = await ImageCacheManager.getCacheSizeFormatted();
      setState(() {
        _cacheInfo = 'Cache: $size';
      });
    } catch (e) {
      setState(() {
        _cacheInfo = 'Cache: Error';
      });
    }
  }
}

// Extension to easily check if we're in debug mode
extension DebugMode on Widget {
  Widget withCacheDebug({bool enabled = false}) {
    return CacheDebugOverlay(
      enabled: enabled,
      child: this,
    );
  }
}
