import 'package:flutter/material.dart';
import '../models/rental.dart';
import '../models/product.dart';
import '../widgets/cached_image_widget.dart';

class RentalDetailsScreen extends StatefulWidget {
  final RentalRequest rental;
  final Product? product;

  const RentalDetailsScreen({
    super.key, 
    required this.rental,
    this.product,
  });

  @override
  State<RentalDetailsScreen> createState() => _RentalDetailsScreenState();
}

class _RentalDetailsScreenState extends State<RentalDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Rental Details'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildRentalDetails(),
    );
  }

  Widget _buildRentalDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildProductCard(),
          const SizedBox(height: 16),
          _buildRentalInfoCard(),
          const SizedBox(height: 16),
          _buildTimelineCard(),
          const SizedBox(height: 16),
          _buildPricingCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.rental.status.statusColor.withOpacity(0.2),
            widget.rental.status.statusColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.rental.status.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(widget.rental.status),
            size: 48,
            color: widget.rental.status.statusColor,
          ),
          const SizedBox(height: 12),
          Text(
            widget.rental.status.displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.rental.status.statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rental Request #${widget.rental.id.substring(0, 8)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    if (widget.product == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'Product information not available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
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
            'Product Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedImageWidget(
                  imageUrl: widget.product!.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product!.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${widget.product!.price.toStringAsFixed(2)}/day',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.product!.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.product!.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRentalInfoCard() {
    return Container(
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
            'Rental Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Quantity', '${widget.rental.quantity} ${widget.rental.quantity == 1 ? 'item' : 'items'}'),
          _buildInfoRow('Duration', '${widget.rental.days} ${widget.rental.days == 1 ? 'day' : 'days'}'),
          _buildInfoRow('Start Date', _formatDate(widget.rental.startDate)),
          _buildInfoRow('End Date', _formatDate(widget.rental.endDate)),
          _buildInfoRow('Delivery Location', widget.rental.deliveryLocation),
          if (widget.rental.storeResponse != null) 
            _buildInfoRow('Store Response', widget.rental.storeResponse!),
          if (widget.rental.rejectionReason != null)
            _buildInfoRow('Rejection Reason', widget.rental.rejectionReason!),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
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
            'Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Request Submitted',
            _formatDateTime(widget.rental.requestDate),
            Icons.send,
            Colors.blue,
            isCompleted: true,
          ),
          if (widget.rental.status != RentalStatus.pending)
            _buildTimelineItem(
              widget.rental.status == RentalStatus.approved ? 'Request Approved' : 'Request Rejected',
              widget.rental.updatedAt != null ? _formatDateTime(widget.rental.updatedAt!) : 'N/A',
              widget.rental.status == RentalStatus.approved ? Icons.check_circle : Icons.cancel,
              widget.rental.status == RentalStatus.approved ? Colors.green : Colors.red,
              isCompleted: true,
            ),
          if (widget.rental.status == RentalStatus.active)
            _buildTimelineItem(
              'Rental Started',
              _formatDate(widget.rental.startDate),
              Icons.play_arrow,
              Colors.green,
              isCompleted: DateTime.now().isAfter(widget.rental.startDate),
            ),
          _buildTimelineItem(
            'Rental Ends',
            _formatDate(widget.rental.endDate),
            Icons.flag,
            Colors.orange,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
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
            'Pricing Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.product != null) ...[
            _buildPriceRow('Price per day', '\$${widget.product!.price.toStringAsFixed(2)}'),
            _buildPriceRow('Quantity', '× ${widget.rental.quantity}'),
            _buildPriceRow('Duration', '× ${widget.rental.days} days'),
            const Divider(color: Colors.grey),
          ],
          _buildPriceRow(
            'Total Amount',
            '\$${widget.rental.totalPrice.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, IconData icon, Color color, {required bool isCompleted}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? color : color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.white : Colors.grey[400],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFFFFD700) : Colors.grey[400],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFFFFD700) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(RentalStatus status) {
    switch (status) {
      case RentalStatus.pending:
        return Icons.hourglass_empty;
      case RentalStatus.approved:
        return Icons.check_circle;
      case RentalStatus.rejected:
        return Icons.cancel;
      case RentalStatus.active:
        return Icons.play_arrow;
      case RentalStatus.completed:
        return Icons.done_all;
      case RentalStatus.cancelled:
        return Icons.block;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
