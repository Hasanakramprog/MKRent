import 'package:flutter/material.dart';
import '../models/rental.dart';
import '../models/product.dart';
import '../services/rental_service.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';

class RentalRequestsScreen extends StatefulWidget {
  const RentalRequestsScreen({super.key});

  @override
  State<RentalRequestsScreen> createState() => _RentalRequestsScreenState();
}

class _RentalRequestsScreenState extends State<RentalRequestsScreen> {
  List<RentalRequest> rentalRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRentalRequests();
  }

  Future<void> _loadRentalRequests() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        final requests = await RentalService.getUserRentals(currentUser.id);
        setState(() {
          rentalRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rental requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'My Rental Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadRentalRequests();
        },
        backgroundColor: const Color(0xFF1A1A1A),
        color: const Color(0xFFFFD700),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              )
            : rentalRequests.isEmpty
                ? _buildEmptyState()
                : _buildRentalsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No Rental Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t made any rental requests yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Browse Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentalRequests.length,
      itemBuilder: (context, index) {
        final rental = rentalRequests[index];
        return FutureBuilder<Product?>(
          future: ProductService.getProductById(rental.productId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            return _buildRentalCard(rental, snapshot.data);
          },
        );
      },
    );
  }

  Widget _buildRentalCard(RentalRequest rental, Product? product) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/rental-details',
          arguments: {
            'rental': rental,
            'product': product,
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(rental.status).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header with product and status
          Row(
            children: [
              // Product image
              if (product != null)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(product.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(width: 12),

              // Product info and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.name ?? 'Unknown Product',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Request ID: ${rental.id}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(rental.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(rental.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusText(rental.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(rental.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rental details
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn('Duration', '${rental.days} days'),
              ),
              Expanded(
                child: _buildInfoColumn('Quantity', '${rental.quantity}'),
              ),
              Expanded(
                child: _buildInfoColumn(
                  'Total',
                  '\$${rental.totalPrice.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date range
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(rental.startDate)} - ${_formatDate(rental.endDate)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                ),
                const Spacer(),
                Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  rental.deliveryLocation,
                  style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                ),
              ],
            ),
          ),

          // Rejection reason if rejected
          if (rental.status == RentalStatus.rejected &&
              rental.rejectionReason != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${rental.rejectionReason}',
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons for specific statuses
          if (rental.status == RentalStatus.pending)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _showCancelDialog(rental);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel Request'),
                ),
              ),
            ),
        ],
      ),
        ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(RentalStatus status) {
    switch (status) {
      case RentalStatus.pending:
        return const Color(0xFFFFD700);
      case RentalStatus.approved:
        return Colors.green;
      case RentalStatus.rejected:
        return Colors.red;
      case RentalStatus.active:
        return Colors.blue;
      case RentalStatus.completed:
        return Colors.grey;
      case RentalStatus.cancelled:
        return Colors.orange;
    }
  }

  String _getStatusText(RentalStatus status) {
    switch (status) {
      case RentalStatus.pending:
        return 'Pending';
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCancelDialog(RentalRequest rental) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Cancel Request',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to cancel this rental request?',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Keep Request',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                _cancelRental(rental);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel Request',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelRental(RentalRequest rental) async {
    try {
      await RentalService.updateRentalStatus(
        rentalId: rental.id,
        status: RentalStatus.cancelled,
      );
      await _loadRentalRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rental request cancelled'),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling rental: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
