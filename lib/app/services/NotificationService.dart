import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request permissions for iOS
    await _firebaseMessaging.requestPermission();

    // Gunakan icon kustom jika tersedia di drawable
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon'); 
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Handle when app is opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle navigation or other logic here
    });
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      AndroidNotificationDetails androidDetails;
      String? tempImagePath;

      String? imageUrl = android.imageUrl ?? message.data['image'];

      try {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          tempImagePath = await _downloadAndSaveFile(
            imageUrl,
            'notification_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          androidDetails = AndroidNotificationDetails(
            'default_channel_id',
            'Default Channel',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/launcher_icon', // Gunakan icon kustom
            styleInformation: BigPictureStyleInformation(
              FilePathAndroidBitmap(tempImagePath),
              hideExpandedLargeIcon: true,
            ),
          );
        } else {
          androidDetails = const AndroidNotificationDetails(
            'default_channel_id',
            'Default Channel',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/launcher_icon', // Gunakan icon kustom
          );
        }

        final NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails,
        );

        await _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          platformDetails,
        );
      } finally {
        if (tempImagePath != null) {
          try {
            final file = File(tempImagePath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            print('Error deleting temporary image: $e');
          }
        }
      }
    }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

// Contoh penggunaan di main.dart:
// await NotificationService().init();
// await NotificationService().subscribeToTopic('news');
