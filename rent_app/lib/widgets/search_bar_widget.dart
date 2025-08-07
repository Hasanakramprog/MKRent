import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String) onChanged;
  final VoidCallback onFilterTap;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search Field
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A), // Dark gray
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search cameras & equipment...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(0xFFFFD700), // Yellow icon
                  size: 24,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Filter Button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700), // Yellow background
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onFilterTap,
            icon: const Icon(
              Icons.tune,
              color: Colors.black,
              size: 24,
            ), // Black icon
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
