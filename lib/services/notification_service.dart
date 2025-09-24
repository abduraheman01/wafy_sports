import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  NotificationService._internal();

  bool _permissionGranted = false;
  bool get isPermissionGranted => _permissionGranted;

  Future<void> initialize() async {
    if (kIsWeb) {
      await _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    if (kIsWeb) {
      try {
        final permission = html.Notification.permission;
        _permissionGranted = permission == 'granted';

        if (permission == 'default') {
          // Permission will be requested by the service worker
          // after the app loads
        }
      } catch (e) {
        print('Notification not supported: $e');
      }
    }
  }

  Future<bool> requestPermission() async {
    if (!kIsWeb) return false;

    try {
      final permission = await html.Notification.requestPermission();
      _permissionGranted = permission == 'granted';
      return _permissionGranted;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  void showLocalNotification({
    required String title,
    required String body,
    String? icon,
  }) {
    if (!kIsWeb || !_permissionGranted) return;

    try {
      final notification = html.Notification(
        title,
        body: body,
        icon: icon ?? '/icons/Icon-192.png',
      );

      // Auto close after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        notification.close();
      });

      notification.onClick.listen((_) {
        // Handle notification click
        html.window.location.href = html.window.location.href;
        notification.close();
      });
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  void showMatchStartNotification(String homeTeam, String awayTeam) {
    showLocalNotification(
      title: 'Match Starting Soon! ⚽',
      body: '$homeTeam vs $awayTeam is about to begin!',
    );
  }

  void showLiveMatchNotification(String homeTeam, String awayTeam, String event) {
    showLocalNotification(
      title: 'LIVE: $homeTeam vs $awayTeam',
      body: event,
    );
  }

  void showGoalNotification(String player, String team) {
    showLocalNotification(
      title: 'GOAL! ⚽',
      body: '$player scored for $team!',
    );
  }

  void showMatchEndNotification(String homeTeam, String awayTeam, String score) {
    showLocalNotification(
      title: 'Full Time! 🏁',
      body: '$homeTeam $score $awayTeam',
    );
  }

  // Simulate push notification (for demo purposes)
  void sendTestNotification() {
    if (!kIsWeb) return;

    Future.delayed(const Duration(seconds: 2), () {
      showLocalNotification(
        title: 'Wafy Sports Update',
        body: 'Check out the latest match results and upcoming fixtures!',
      );
    });
  }

  // Register for specific match notifications
  void subscribeToMatchNotifications(String matchId) {
    // In a real app, this would register with your push notification service
    print('Subscribed to notifications for match: $matchId');
  }

  void unsubscribeFromMatchNotifications(String matchId) {
    // In a real app, this would unregister from your push notification service
    print('Unsubscribed from notifications for match: $matchId');
  }

  // Check if browser supports notifications
  bool get isSupported {
    if (!kIsWeb) return false;
    return html.Notification.supported;
  }
}