import 'package:flutter/material.dart';
import '../services/storage.dart';
import '../services/firebase_service.dart';
import '../services/notifications.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _syncing = false;
  int _total = 0;
  int _uploaded = 0;
  String _status = '';

  Future<void> _startSync() async {
    setState(() {
      _syncing = true;
      _status = 'Gathering local records...';
      _uploaded = 0;
      _total = 0;
    });

    final entries = StorageService().allEntries();
    setState(() => _total = entries.length);

    int i = 0;
    for (final key in entries.keys) {
      final record = Map<String, dynamic>.from(entries[key]!);
      setState(() => _status = 'Syncing ${i + 1} of $_total');

      // If record has a local photo path, try uploading it first
      if (record.containsKey('photo') &&
          (record['photo'] is String) &&
          (record['photo'] as String).isNotEmpty) {
        final localPath = record['photo'] as String;
        try {
          final remoteUrl = await FirebaseService().uploadPhoto(localPath);
          if (remoteUrl != null) {
            record['photo_remote'] = remoteUrl;
          }
        } catch (e) {
          // keep local photo if upload failed
        }
      }

      // Upload record data and store remote ID if available
      try {
        final remoteId = await FirebaseService().uploadRecord(record);
        if (remoteId != null) {
          record['remote_id'] = remoteId;
          record['synced'] = true;
          record['synced_at'] = DateTime.now().toIso8601String();
          await StorageService().updateRecord(key, record);
          setState(() => _uploaded = _uploaded + 1);
        }
      } catch (e) {
        // record upload failed; continue with next
      }

      i++;
    }

    setState(() {
      _syncing = false;
      _status = 'Sync complete. Uploaded $_uploaded of $_total records.';
    });

    if (_uploaded > 0) {
      await NotificationService().showAlert(
        title: 'Cloud sync',
        body: 'Uploaded $_uploaded records',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Sync')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text('Local records: ${StorageService().allEntries().length}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _syncing ? null : _startSync,
              child: Text(_syncing ? 'Syncing...' : 'Sync Now'),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _total == 0 ? 0 : (_uploaded / _total),
            ),
            const SizedBox(height: 8),
            Text('Status: $_status'),
            const SizedBox(height: 8),
            Text('Uploaded: $_uploaded / $_total'),
          ],
        ),
      ),
    );
  }
}
