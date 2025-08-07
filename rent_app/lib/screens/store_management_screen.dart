import 'package:flutter/material.dart';
import '../models/rental.dart';
import '../models/product.dart';
import '../services/rental_service.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  List<RentalRequest> pendingRequests = [];
  List<RentalRequest> allRequests = [];
  int selectedTabIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        final allRentals = await RentalService.getStoreRentals(currentUser.id);
        final pending = allRentals.where((r) => r.status == RentalStatus.pending).toList();
        
        setState(() {
          allRequests = allRentals;
          pendingRequests = pending;
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
            content: Text('Error loading requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text(
            'Store Management',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/add-product');
                if (result == true) {
                  // Refresh data when a new product is added
                  _loadRequests();
                }
              },
              icon: const Icon(Icons.add),
              tooltip: 'Add Product',
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                selectedTabIndex = index;
              });
            },
            indicatorColor: const Color(0xFFFFD700),
            labelColor: const Color(0xFFFFD700),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_actions),
                    const SizedBox(width: 8),
                    Text('Pending (${pendingRequests.length})'),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('All Requests'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildPendingTab(), _buildAllRequestsTab()],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    }
    
    if (pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Pending Requests',
        subtitle: 'All rental requests have been processed.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadRequests(),
      backgroundColor: const Color(0xFF1A1A1A),
      color: const Color(0xFFFFD700),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingRequests.length,
        itemBuilder: (context, index) {
          final rental = pendingRequests[index];
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
              return _buildPendingRequestCard(rental, snapshot.data);
            },
          );
        },
      ),
    );
  }

  Widget _buildAllRequestsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    }
    
    if (allRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No Requests Found',
        subtitle: 'No rental requests have been made yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadRequests(),
      backgroundColor: const Color(0xFF1A1A1A),
      color: const Color(0xFFFFD700),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allRequests.length,
        itemBuilder: (context, index) {
          final rental = allRequests[index];
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
              return _buildRequestCard(rental, snapshot.data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestCard(RentalRequest rental, Product? product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          // Header
          Row(
            children: [
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Request ID: ${rental.id}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    Text(
                      'Requested: ${_formatDate(rental.requestDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Request details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem('Quantity', '${rental.quantity}'),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Duration',
                        '${rental.days} days',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Total',
                        '\$${rental.totalPrice.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[400],
                    ),
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveRequest(rental),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRejectDialog(rental),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RentalRequest rental, Product? product) {
    return Container(
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
          Row(
            children: [
              if (product != null)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(product.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.name ?? 'Unknown Product',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ID: ${rental.id} • ${_formatDate(rental.requestDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(rental.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(rental.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusText(rental.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(rental.status),
                  ),
                ),
              ),
            ],
          ),
          if (rental.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Rejection Reason: ${rental.rejectionReason}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
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

  void _approveRequest(RentalRequest rental) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final responseController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Approve Request',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add an optional message for the customer:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responseController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Equipment will be ready for pickup...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await RentalService.updateRentalStatus(
                    rentalId: rental.id,
                    status: RentalStatus.approved,
                    storeResponse: responseController.text.isEmpty
                        ? 'Request approved by store manager'
                        : responseController.text,
                  );

                  // Get product details for notification
                  final product = await ProductService.getProductById(rental.productId);
                  if (product != null) {
                    // Send approval notification to customer
                    await NotificationService.sendRentalApprovedNotification(
                      customerId: rental.userId,
                      rental: rental,
                      product: product,
                    );
                  }

                  _loadRequests();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request approved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error approving request: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(RentalRequest rental) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final reasonController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Reject Request',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please provide a reason for rejection:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Equipment not available for selected dates',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a rejection reason'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await RentalService.updateRentalStatus(
                    rentalId: rental.id,
                    status: RentalStatus.rejected,
                    rejectionReason: reasonController.text,
                  );

                  // Get product details for notification
                  final product = await ProductService.getProductById(rental.productId);
                  if (product != null) {
                    // Send rejection notification to customer
                    await NotificationService.sendRentalRejectedNotification(
                      customerId: rental.userId,
                      rental: rental,
                      product: product,
                      reason: reasonController.text,
                    );
                  }

                  _loadRequests();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request rejected'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error rejecting request: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
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
}
