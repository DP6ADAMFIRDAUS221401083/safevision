import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/detail_alert_screen.dart';
import 'services/firestore_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Meminta izin notifikasi (terutama untuk Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Mengambil dan mencetak FCM Token
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    // Listener untuk memperbarui token jika berubah (onTokenRefresh)
    messaging.onTokenRefresh.listen((newToken) async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'fcmToken': newToken,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print('Error updating token on refresh: $e');
        }
      }
    });

    // Listener untuk menerima notifikasi ketika aplikasi sedang dibuka (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification received');
      if (message.data.containsKey('alertId')) {
        print('Alert ID: ${message.data['alertId']}');
      }

      if (message.notification != null) {
        _showNotificationDialog(
          message.notification!.title,
          message.notification!.body,
        );
      }
    });

    // Listener untuk menangani notifikasi yang ditekan dari background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Background notification opened');
      if (message.data.containsKey('alertId')) {
        final alertId = message.data['alertId'];
        print('Alert ID: $alertId');
        _navigateToDetailAlert(alertId);
      }
    });

    // Menangani notifikasi jika aplikasi dibuka dari kondisi terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('Terminated notification opened');
      if (initialMessage.data.containsKey('alertId')) {
        final alertId = initialMessage.data['alertId'];
        print('Alert ID: $alertId');
        // Tunggu splash screen selesai (3 detik) sebelum navigasi
        Future.delayed(const Duration(seconds: 4), () {
          _navigateToDetailAlert(alertId);
        });
      }
    }
  }

  void _navigateToDetailAlert(String alertId) async {
    try {
      final alert = await FirestoreService().getAlert(alertId);
      if (alert != null) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailAlertScreen(alert: alert),
            ),
          );
        }
      }
    } catch (e) {
      print('Error navigating to Detail Alert: $e');
    }
  }

  void _showNotificationDialog(String? title, String? body) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title ?? 'Notifikasi Baru'),
          content: Text(body ?? 'Anda menerima pesan baru.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SafeVision',
      home: const SplashScreen(),
    );
  }
}
