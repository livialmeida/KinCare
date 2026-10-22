import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class WebPushNotificationService {
  // Configuration injected via --dart-define
  // Example: --dart-define=KINCARE_VAPID_KEY=your_vapid_key
  static const String _vapidKey = String.fromEnvironment(
    'KINCARE_VAPID_KEY',
    defaultValue: '',
  );

  // Optional endpoint for deployments using Cloud Functions (Blaze Plan)
  static const String _subscribeEndpoint = String.fromEnvironment(
    'KINCARE_SUBSCRIBE_ENDPOINT',
    defaultValue: '',
  );

  static Future<void> initializeWebNotifications({
    required String userUid,
    required String role,
  }) async {
    // Technical: Defensive guard - run strictly in web runtime
    if (!kIsWeb) return;

    if (_vapidKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[KinCare Warning] VAPID Key not configured for Web Push.');
      }
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Explicit permission request in the browser
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        if (kDebugMode) {
          debugPrint('[KinCare] Web notification permissions declined or not authorized.');
        }
        return;
      }

      // 2. Retrieve Web FCM registration token using public VAPID key
      // ignore: deprecated_member_use
      final token = await messaging.getToken(vapidKey: _vapidKey);
      if (token == null || token.isEmpty) return;

      // 3. Spark Plan bypass: If no Cloud Function endpoint is provided, stop here.
      // The individual token is already persisted to Firestore via NotificationService.
      if (_subscribeEndpoint.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[KinCare Info] Spark Plan: No Cloud Function endpoint configured. Topic subscription bypassed.',
          );
        }
        return;
      }

      // 4. Map message topics based on access control role
      final topics = <String>['general_users', 'user_$userUid'];

      if (role == 'admin') {
        topics.add('admin_stock_alerts');
        topics.add('admin_approval_alerts');
        topics.add('orders_management_alerts');
      } else if (role == 'support') {
        topics.add('orders_management_alerts');
        topics.add('support_pantry_alerts');
      }

      // 5. Dispatch registration payload to backend bridge
      final response = await http.post(
        Uri.parse(_subscribeEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'topics': topics,
        }),
      );

      if (kDebugMode) {
        debugPrint('[KinCare] Backend topic subscription status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Technical: Error initializing web push notifications: $e');
      }
    }
  }
}