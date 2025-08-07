import 'package:flutter/material.dart';

class BrandSlider extends StatelessWidget {
  const BrandSlider({super.key});

  static const List<Map<String, String>> brands = [
    {'name': 'Aputure', 'logo': 'assets/images/brands/aputure.jpg'},
    {'name': 'ARRI', 'logo': 'assets/images/brands/arri.jpg'},
    {'name': 'Cooke', 'logo': 'assets/images/brands/cooke.jpg'},
    {'name': 'Dedolight', 'logo': 'assets/images/brands/dedo.jpg'},
    {'name': 'Kino Flo', 'logo': 'assets/images/brands/kino.jpg'},
    {'name': 'Osnomer', 'logo': 'assets/images/brands/osnomer.jpg'},
    {'name': 'Sacther', 'logo': 'assets/images/brands/sacther.jpg'},
    {'name': 'SmallHD', 'logo': 'assets/images/brands/smallhd.jpg'},
    {'name': 'Tera', 'logo': 'assets/images/brands/tera.jpg'},
    {'name': 'Tiffen', 'logo': 'assets/images/brands/tiffen.jpg'},
    {'name': 'Tilta', 'logo': 'assets/images/brands/tilta.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          return Container(
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                // Brand Logo Circle
                GestureDetector(
                  onTap: () {
                    // Handle brand filter or navigation
                    _onBrandTapped(context, brand['name']!);
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipOval(
                        child: Image.asset(
                          brand['logo']!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Brand Name
                Text(
                  brand['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onBrandTapped(BuildContext context, String brandName) {
    // Show a snackbar for now - you can implement brand filtering here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtering by $brandName'),
        backgroundColor: const Color(0xFFFFD700),
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: Implement brand filtering logic
    // You could filter products by brand, navigate to brand page, etc.
  }
}

// Alternative compact version for smaller spaces with auto-scroll
class CompactBrandSlider extends StatefulWidget {
  const CompactBrandSlider({super.key});

  @override
  State<CompactBrandSlider> createState() => _CompactBrandSliderState();
}

class _CompactBrandSliderState extends State<CompactBrandSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 20), // Adjust speed here
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    // Start the auto-scroll animation
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _animationController.addListener(() {
      if (_scrollController.hasClients && 
          _scrollController.position.hasContentDimensions &&
          mounted) {
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        if (maxScrollExtent > 0) {
          final currentScrollPosition = maxScrollExtent * _animation.value;
          _scrollController.jumpTo(currentScrollPosition);
        }
      }
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Reset and restart the animation
        _animationController.reset();
        _animationController.forward();
      }
    });

    // Delay the start to ensure the ListView is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: BrandSlider.brands.length * 3, // Triple the items for seamless loop
        itemBuilder: (context, index) {
          final brandIndex = index % BrandSlider.brands.length;
          final brand = BrandSlider.brands[brandIndex];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                // Pause animation on tap
                if (mounted && _animationController.isAnimating) {
                  _animationController.stop();
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected ${brand['name']}'),
                    backgroundColor: const Color(0xFFFFD700),
                    behavior: SnackBarBehavior.fixed,
                    duration: const Duration(seconds: 1),
                  ),
                );
                
                // Resume animation after a delay
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted && !_animationController.isAnimating) {
                    _animationController.forward();
                  }
                });
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: ClipOval(
                    child: Image.asset(
                      brand['logo']!,
                      width: 58,
                      height: 58,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
