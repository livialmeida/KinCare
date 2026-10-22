import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kincare/core/services/web_push_notification_service.dart';
import 'package:kincare/main.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _ordersChannel = const AndroidNotificationChannel(
    'kincare_orders_channel',
    'Pedidos - KinCare',
    description: 'Notificações de novos pedidos e atualizações de status.',
    importance: Importance.max,
    playSound: true,
  );

  final AndroidNotificationChannel _expiryChannel = const AndroidNotificationChannel(
    'kincare_expiry_channel',
    'Validade - KinCare',
    description: 'Alertas de vencimento e controle sanitário de itens no estoque.',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      if (kDebugMode) {
        debugPrint('Notification permissions declined or not authorized.');
      }
      return;
    }

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Technical: Execute local notification plugin strictly on native mobile platforms
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await _initializeLocalNotifications();
    }

    _setupForegroundNotificationListener();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/ic_notification');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationClick(response.payload);
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_ordersChannel);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_expiryChannel);
  }

  void _setupForegroundNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && kIsWeb) {
        if (kDebugMode) {
          debugPrint(
            'Web foreground notification: ${notification.title} - ${notification.body}',
          );
        }
        return;
      }

      if (notification != null && android != null) {
        String type = message.data['type'] ?? '';
        AndroidNotificationChannel selectedChannel =
        (type == 'stock_expiry') ? _expiryChannel : _ordersChannel;

        await _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              selectedChannel.id,
              selectedChannel.name,
              channelDescription: selectedChannel.description,
              icon: android.smallIcon,
              importance: selectedChannel.importance,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(jsonEncode(message.data));
    });
  }

  /// Synchronizes FCM topic subscriptions according to the user's role.
  /// On Web, topics aren't supported by the client SDK — saves an
  /// individual token to Firestore instead.
  Future<void> syncTopicSubscriptions({
    required String userUid,
    required String role,
  }) async {
    if (kIsWeb) {
      await WebPushNotificationService.initializeWebNotifications(
        userUid: userUid,
        role: role,
      );
      await _saveWebTokenToFirestore(userUid);
      return;
    }

    await _unsubscribeAllDefaultTopics(userUid);
    await _fcm.subscribeToTopic('user_$userUid');

    switch (role) {
      case 'admin':
        await _fcm.subscribeToTopic('admin_stock_alerts');
        await _fcm.subscribeToTopic('admin_approval_alerts');
        await _fcm.subscribeToTopic('orders_management_alerts');
        break;

      case 'support':
        await _fcm.subscribeToTopic('orders_management_alerts');
        await _fcm.subscribeToTopic('support_pantry_alerts');
        break;

      default:
        await _fcm.subscribeToTopic('general_users');
        break;
    }
  }

  Future<void> _unsubscribeAllDefaultTopics(String userUid) async {
    try {
      await _fcm.unsubscribeFromTopic('user_$userUid');
      await _fcm.unsubscribeFromTopic('admin_stock_alerts');
      await _fcm.unsubscribeFromTopic('orders_management_alerts');
      await _fcm.unsubscribeFromTopic('support_pantry_alerts');
      await _fcm.unsubscribeFromTopic('admin_approval_alerts');
      await _fcm.unsubscribeFromTopic('general_users');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cleaning up previous topic subscriptions: $e');
      }
    }
  }

  /// Web/iOS PWA: persists individual token to Firestore since
  /// topics are unsupported by the FCM Web client SDK
  Future<void> _saveWebTokenToFirestore(String userUid) async {
    const vapidKey = String.fromEnvironment(
      'KINCARE_VAPID_KEY',
      defaultValue: '',
    );

    if (vapidKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[KinCare Warning] VAPID Key not configured for Web token persistence.');
      }
      return;
    }

    try {
      // ignore: deprecated_member_use
      final token = await _fcm.getToken(vapidKey: vapidKey);

      if (token == null || token.isEmpty) {
        if (kDebugMode) debugPrint('Não foi possível obter o token web.');
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(userUid).set(
        {'fcmToken': token, 'platform': 'web'},
        SetOptions(merge: true),
      );

      if (kDebugMode) debugPrint('Token Web salvo para $userUid.');
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao registrar o token web: $e');
    }
  }

  void _handleNotificationClick(String? payloadJson) {
    if (payloadJson == null) return;
    try {
      Map<String, dynamic> data = jsonDecode(payloadJson);
      String type = data['type'] ?? '';

      if (kDebugMode) {
        debugPrint("Navegando por causa da notificação, tipo: $type");
      }

      switch (type) {
        case 'new_order':
        case 'order_status':
        case 'order_accepted':
        case 'surprise':
          navigatorKey.currentState?.pushNamed('/orders');
          break;

        case 'stock_expiry':
          navigatorKey.currentState?.pushNamed('/stock');
          break;

        case 'pantry_access_request':
        case 'pending_user_registration':
          navigatorKey.currentState?.pushNamed('/account', arguments: {'openFamilyModal': true});
          break;

        case 'pantry_access_granted':
        case 'user_approved':
          navigatorKey.currentState?.pushNamed('/account');
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Failed to parse notification payload: $e");
      }
    }
  }
}