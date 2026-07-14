import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';

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

    // Listener untuk menerima notifikasi ketika aplikasi sedang dibuka (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotificationDialog(
          message.notification!.title,
          message.notification!.body,
        );
      }
    });
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
      home: const LoginScreen(),
    );
  }
}
