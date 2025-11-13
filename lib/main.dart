import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/notifications.dart';
import 'services/firebase_service.dart';
import 'screens/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('records');
  await NotificationService().init();
  // Initialize Firebase (optional). Requires Firebase project configuration files.
  // On web, FirebaseOptions must be provided (via `flutterfire configure`).
  try {
    await FirebaseService().init();
  } catch (e) {
    // Initialization errors already logged in service; continue offline.
  }

  // Request common permissions used by app. Skip on web (browser handles permissions).
  if (!kIsWeb) {
    try {
      await Permission.photos.request();
      await Permission.camera.request();
      await Permission.microphone.request();
    } catch (e) {
      // Some platforms or plugin states may throw; continue and let features fail gracefully.
    }
  }

  runApp(const BreadOfLifeApp());
}

class BreadOfLifeApp extends StatelessWidget {
  const BreadOfLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bread of Life',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DashboardScreen(),
    );
  }
}
