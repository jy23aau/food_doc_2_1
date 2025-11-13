import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notifications.dart';
import 'storage.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;

  /// Initialize Firebase. NOTE: You must add `google-services.json` and iOS
  /// plist files or run `flutterfire configure` for proper FirebaseOptions.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      // Ensure we have an authenticated context for Firestore rules and FCM topics
      try {
        final auth = FirebaseAuth.instance;
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
          if (kDebugMode) print('Signed in anonymously to Firebase');
        }
      } catch (e) {
        if (kDebugMode) print('Firebase auth init failed: $e');
      }
      _initialized = true;

      // Setup messaging to show local alerts when messages are received
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'Alert';
        final body = message.notification?.body ?? '';
        NotificationService().showAlert(title: title, body: body);
      });

      // Optionally, sync any existing local records to Firestore
      // You can call syncLocalRecords() periodically or via user action
    } catch (e) {
      if (kDebugMode) print('FirebaseService.init error: $e');
      // Initialization can fail if config files are missing; app can still work offline
    }
  }

  /// Upload a record and return the Firestore document ID (or null on failure).
  Future<String?> uploadRecord(Map<String, dynamic> record) async {
    if (!_initialized) await init();
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('records')
          .add(record);
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('uploadRecord failed: $e');
      return null;
    }
  }

  Future<String?> uploadPhoto(String localPath) async {
    if (!_initialized) await init();
    try {
      final file = File(localPath);
      final ref = FirebaseStorage.instance.ref().child(
        'photos/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}',
      );
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      return url;
    } catch (e) {
      if (kDebugMode) print('uploadPhoto failed: $e');
      return null;
    }
  }

  /// Upload all local Hive records to Firestore (basic sync). This is a simple
  /// one-way sync to allow audits in the cloud. It does not yet handle
  /// de-duplication or conflict resolution.
  Future<void> syncLocalRecords() async {
    final entries = StorageService().allEntries();
    for (final key in entries.keys) {
      final record = Map<String, dynamic>.from(entries[key]!);
      try {
        final remoteId = await uploadRecord(record);
        if (remoteId != null) {
          record['remote_id'] = remoteId;
          record['synced'] = true;
          record['synced_at'] = DateTime.now().toIso8601String();
          await StorageService().updateRecord(key, record);
        }
      } catch (_) {}
    }
  }
}
