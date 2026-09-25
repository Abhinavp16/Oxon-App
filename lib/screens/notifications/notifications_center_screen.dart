import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/notification_service.dart';

class NotificationsCenterScreen extends ConsumerStatefulWidget {
  const NotificationsCenterScreen({super.key, this.initialTab = 4});

  final int initialTab;

  @override
  ConsumerState<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState
    extends ConsumerState<NotificationsCenterScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  // Colors from design
  static const Color primary = Color(0xFF46ec13);
  static const Color backgroundLight = Color(0xFFf6f8f6);
  static const Color textDark = Color(0xFF111b0d);
  static const Color statusGreen = Color(0xFF22c55e);
  static const Color statusBlue = Color(0xFF3b82f6);
  static const Color statusOrange = Color(0xFFf97316);
  static const Color gray200 = Color(0xFFe5e7eb);
  static const Color gray400 = Color(0xFF9ca3af);
  static const Color gray500 = Color(0xFF6b7280);
  static const Color gray600 = Color(0xFF4b5563);
  static const Color red500 = Color(0xFFef4444);

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(
        '/notifications/my',
        queryParameters: {'limit': 50},
      );

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> items = response.data['data'] ?? [];
        setState(() {
          _notifications = items.map<Map<String, dynamic>>((item) {
            return {
              'id': item['_id']?.toString() ?? '',
              'title': item['title']?.toString() ?? '',
              'body': item['body']?.toString() ?? '',
              'type': item['type']?.toString() ?? 'general',
              'isRead': item['isRead'] == true,
              'createdAt': item['createdAt'],
              'data': item['data'],
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    final notificationId = notification['id']?.toString() ?? '';
    if (notificationId.isNotEmpty && notification['isRead'] != true) {
      try {
        await ref
            .read(apiClientProvider)
            .post(
              '/notifications/mark-read',
              data: {
                'ids': [notificationId],
              },
            );
        if (mounted) {
          setState(() => notification['isRead'] = true);
        }
      } catch (error) {
        debugPrint('Error marking notification as read: $error');
      }
    }

    final rawData = notification['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    data.putIfAbsent(
      'type',
      () => notification['type']?.toString() ?? 'general',
    );
    ref.read(notificationServiceProvider).handleNotificationData(data);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'order_update':
        return Icons.shopping_bag;
      case 'payment_verified':
      case 'payment_rejected':
        return Icons.verified;
      case 'price_change':
        return Icons.sell_outlined;
      case 'negotiation_update':
      case 'negotiation_accepted':
      case 'negotiation_rejected':
      case 'negotiation_countered':
        return Icons.handshake;
      case 'promotion':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'order_update':
        return statusBlue;
      case 'payment_verified':
        return statusGreen;
      case 'payment_rejected':
        return red500;
      case 'price_change':
        return statusOrange;
      case 'negotiation_update':
      case 'negotiation_accepted':
      case 'negotiation_rejected':
      case 'negotiation_countered':
        return const Color(0xFF7C3AED);
      case 'promotion':
        return statusOrange;
      default:
        return gray600;
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return 'Just now';

    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Column(
        children: [
          // Header
          Container(
            color: backgroundLight.withValues(alpha: 0.8),
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: gray200)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: textDark,
                          size: 18,
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home', extra: {'tab': 4});
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Notifications',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ),
                    SizedBox(width: 40, height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: gray400),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: gray600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see your notifications here',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final type = notification['type']?.toString() ?? 'general';
    final isRead = notification['isRead'] == true;
    final title = notification['title']?.toString() ?? '';
    final body = notification['body']?.toString() ?? '';
    final createdAt = notification['createdAt']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isRead
            ? null
            : Border.all(color: primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openNotification(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getIconColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(type),
                    color: _getIconColor(type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(createdAt),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: gray500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
