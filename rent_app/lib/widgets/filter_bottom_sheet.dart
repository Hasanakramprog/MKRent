import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final Function(double, double, double) onApplyFilters;

  const FilterBottomSheet({
    super.key,
    required this.minPrice,
    required this.maxPrice,
    required this.minRating,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late double _minPrice;
  late double _maxPrice;
  late double _minRating;

  @override
  void initState() {
    super.initState();
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _minRating = widget.minRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A), // Dark background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = 0;
                      _maxPrice = 1000;
                      _minRating = 0;
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Color(0xFFFFD700), // Yellow
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range
                  const Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '\$${_minPrice.round()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${_maxPrice.round()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 150,
                    divisions: 30,
                    activeColor: const Color(0xFFFFD700), // Yellow
                    inactiveColor: Colors.grey[600],
                    onChanged: (RangeValues values) {
                      setState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  // Rating
                  const Text(
                    'Minimum Rating',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('0'),
                      Expanded(
                        child: Slider(
                          value: _minRating,
                          min: 0,
                          max: 5,
                          divisions: 50,
                          activeColor: const Color(0xFF6366F1),
                          inactiveColor: Colors.grey[300],
                          onChanged: (double value) {
                            setState(() {
                              _minRating = value;
                            });
                          },
                        ),
                      ),
                      const Text('5'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _minRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(' and above'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_minPrice, _maxPrice, _minRating);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700), // Yellow
                  foregroundColor: Colors.black, // Black text
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
