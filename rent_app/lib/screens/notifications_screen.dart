import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../models/rental.dart';
import '../models/product.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/rental_service.dart';
import '../services/product_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when screen is opened
    if (AuthService.userId != null) {
      NotificationService.markAllAsRead(AuthService.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService.userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view notifications'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () async {
              await NotificationService.markAllAsRead(AuthService.userId!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService.getUserNotifications(AuthService.userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading notifications: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ll see rental updates and messages here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification.status == NotificationStatus.unread ? 4 : 1,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.status == NotificationStatus.unread
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (notification.status == NotificationStatus.unread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _formatTimestamp(notification.createdAt),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            if (notification.fromUserName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• From: ${notification.fromUserName}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, notification),
                    itemBuilder: (context) => [
                      if (notification.status == NotificationStatus.unread)
                        const PopupMenuItem(
                          value: 'mark_read',
                          child: Text('Mark as read'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    child: Icon(Icons.more_vert, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.rentalRequest:
        iconData = Icons.request_page;
        color = Colors.orange;
        break;
      case NotificationType.rentalApproved:
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.rentalRejected:
        iconData = Icons.cancel;
        color = Colors.red;
        break;
      case NotificationType.rentalStarted:
        iconData = Icons.play_arrow;
        color = Colors.blue;
        break;
      case NotificationType.rentalExtended:
        iconData = Icons.schedule;
        color = Colors.amber;
        break;
      case NotificationType.rentalReturned:
        iconData = Icons.keyboard_return;
        color = Colors.teal;
        break;
      case NotificationType.rentalOverdue:
        iconData = Icons.warning;
        color = Colors.red;
        break;
      case NotificationType.paymentDue:
        iconData = Icons.payment;
        color = Colors.orange;
        break;
      case NotificationType.paymentReceived:
        iconData = Icons.monetization_on;
        color = Colors.green;
        break;
      case NotificationType.general:
        iconData = Icons.info;
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read if unread
    if (notification.status == NotificationStatus.unread) {
      NotificationService.markAsRead(notification.id);
    }

    // Handle navigation based on notification type and data
    final data = notification.data;
    if (data.containsKey('rentalId')) {
      _navigateToRentalDetails(data['rentalId'], data['productId']);
    }
  }

  Future<void> _navigateToRentalDetails(String? rentalId, String? productId) async {
    if (rentalId == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );

      // Fetch rental and product data
      final rentals = await RentalService.getUserRentals(AuthService.userId!);
      final rental = rentals.firstWhere((r) => r.id == rentalId);
      
      Product? product;
      if (productId != null) {
        product = await ProductService.getProductById(productId);
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Navigate to details
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/rental-details',
          arguments: {
            'rental': rental,
            'product': product,
          },
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rental details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action, AppNotification notification) {
    switch (action) {
      case 'mark_read':
        NotificationService.markAsRead(notification.id);
        break;
      case 'delete':
        _showDeleteConfirmation(notification);
        break;
    }
  }

  void _showDeleteConfirmation(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationService.deleteNotification(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
