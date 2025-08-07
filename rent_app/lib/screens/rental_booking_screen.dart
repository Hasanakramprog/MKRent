import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/rental.dart';
import '../services/rental_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class RentalBookingScreen extends StatefulWidget {
  final Product product;

  const RentalBookingScreen({super.key, required this.product});

  @override
  State<RentalBookingScreen> createState() => _RentalBookingScreenState();
}

class _RentalBookingScreenState extends State<RentalBookingScreen> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int _quantity = 1;
  int _days = 1;
  DateTime? _startDate;
  DateTime? _endDate;

  double get _totalPrice {
    return widget.product.price * _quantity * _days;
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFFD700),
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _endDate = picked.add(Duration(days: _days - 1));
      });
    }
  }

  void _updateDays(int days) {
    setState(() {
      _days = days;
      if (_startDate != null) {
        _endDate = _startDate!.add(Duration(days: _days - 1));
      }
    });
  }

  Future<void> _submitRental() async {
    if (_startDate == null || _locationController.text.trim().isEmpty) {
      _showErrorDialog('Please fill in all required fields');
      return;
    }

    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      _showErrorDialog('Please log in to submit a rental request');
      return;
    }

    try {
      final rental = RentalRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: widget.product.id,
        productOwnerId: widget.product.ownerId,
        userId: currentUser.id,
        quantity: _quantity,
        days: _days,
        deliveryLocation: _locationController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        totalPrice: _totalPrice,
        requestDate: DateTime.now(),
      );

      await RentalService.createRentalRequest(rental);

      // Send notification to admin
      try {
        await NotificationService.sendRentalRequestNotification(
          adminId: widget.product.ownerId,
          rental: rental,
          product: widget.product,
        );
      } catch (e) {
        print('Error sending notification: $e');
        // Don't block the user flow if notification fails
      }

      Navigator.pushNamed(
        context,
        '/rental-confirmation',
        arguments: {'rental': rental, 'product': widget.product},
      );
    } catch (e) {
      _showErrorDialog('Error submitting rental request: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Book Rental'),
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.product.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.category,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${widget.product.price.toInt()}/day',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quantity Selection
            _buildSectionTitle('Quantity'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Quantity:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: _quantity > 1
                        ? const Color(0xFFFFD700)
                        : Colors.grey,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _quantity.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFFFFD700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Duration Selection
            _buildSectionTitle('Rental Duration'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Days:',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _days > 1
                            ? () => _updateDays(_days - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: _days > 1
                            ? const Color(0xFFFFD700)
                            : Colors.grey,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _days.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateDays(_days + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFFFFD700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick duration buttons
                  Row(
                    children: [
                      _buildDurationButton('1 Day', 1),
                      const SizedBox(width: 8),
                      _buildDurationButton('3 Days', 3),
                      const SizedBox(width: 8),
                      _buildDurationButton('1 Week', 7),
                      const SizedBox(width: 8),
                      _buildDurationButton('1 Month', 30),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Date Selection
            _buildSectionTitle('Start Date'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: InkWell(
                onTap: _selectStartDate,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFFFD700)),
                    const SizedBox(width: 12),
                    Text(
                      _startDate == null
                          ? 'Select start date'
                          : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                      style: TextStyle(
                        color: _startDate == null
                            ? Colors.grey[500]
                            : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (_endDate != null) ...[
                      const Text(' - ', style: TextStyle(color: Colors.white)),
                      Text(
                        '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Location Input
            _buildSectionTitle('Delivery Location'),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter delivery address',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Color(0xFFFFD700),
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFD700),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notes (Optional)
            _buildSectionTitle('Additional Notes (Optional)'),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special requirements or notes...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFD700),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Price Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Price per day:',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        '\$${widget.product.price.toInt()}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Days:',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        '$_days',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Price:',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '\$${_totalPrice.toInt()}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitRental,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Submit Rental Request',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDurationButton(String label, int days) {
    final isSelected = _days == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => _updateDays(days),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD700) : Colors.grey[600]!,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
