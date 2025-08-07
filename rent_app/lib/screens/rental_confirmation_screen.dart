import 'package:flutter/material.dart';
import '../models/rental.dart';
import '../models/product.dart';

class RentalConfirmationScreen extends StatelessWidget {
  final RentalRequest rental;
  final Product product;

  const RentalConfirmationScreen({
    super.key,
    required this.rental,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Rental Confirmation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFFD700),
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Center(
              child: Text(
                'Request Submitted!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            const Center(
              child: Text(
                'Your rental request has been sent to the store for review.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),

            // Rental Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rental Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailRow('Request ID', rental.id),
                  _buildDetailRow('Product', product.name),
                  _buildDetailRow('Quantity', '${rental.quantity}'),
                  _buildDetailRow('Duration', '${rental.days} days'),
                  _buildDetailRow('Start Date', _formatDate(rental.startDate)),
                  _buildDetailRow('End Date', _formatDate(rental.endDate)),
                  _buildDetailRow('Location', rental.deliveryLocation),
                  _buildDetailRow(
                    'Total Price',
                    '\$${rental.totalPrice.toStringAsFixed(2)}',
                  ),
                  _buildDetailRow('Status', _getStatusText(rental.status)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFFFFD700),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will receive a notification once the store reviews your request. This usually takes 1-2 business days.',
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/rental-requests');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View My Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusText(RentalStatus status) {
    switch (status) {
      case RentalStatus.pending:
        return 'Pending Review';
      case RentalStatus.approved:
        return 'Approved';
      case RentalStatus.rejected:
        return 'Rejected';
      case RentalStatus.active:
        return 'Active';
      case RentalStatus.completed:
        return 'Completed';
      case RentalStatus.cancelled:
        return 'Cancelled';
    }
  }
}
