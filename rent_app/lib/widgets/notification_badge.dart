import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/google_auth_service.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (GoogleAuthService.userId == null) {
      return child;
    }

    return StreamBuilder<int>(
      stream: NotificationService.getUnreadCount(GoogleAuthService.userId!),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        
        if (count == 0) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Widget for showing notification icon with badge
class NotificationIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double? iconSize;

  const NotificationIconButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      child: IconButton(
        icon: Icon(
          Icons.notifications,
          color: iconColor ?? Colors.white,
          size: iconSize ?? 24,
        ),
        onPressed: onPressed ?? () {
          Navigator.pushNamed(context, '/notifications');
        },
        tooltip: 'Notifications',
      ),
    );
  }
}
