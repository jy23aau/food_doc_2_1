import 'package:hive/hive.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Box get _box => Hive.box('records');

  /// Generic record saving. Key should be unique (e.g. timestamp millis)
  Future<void> saveRecord(String key, Map<String, dynamic> value) async {
    await _box.put(key, value);
  }

  /// Update an existing record by key
  Future<void> updateRecord(String key, Map<String, dynamic> value) async {
    if (_box.containsKey(key)) {
      await _box.put(key, value);
    }
  }

  /// Save a typed checkpoint (fridge/oven/pest/cleaning etc.)
  Future<void> saveCheckpoint(Map<String, dynamic> checkpoint) async {
    final key = 'checkpoint_${DateTime.now().millisecondsSinceEpoch}';
    await saveRecord(key, checkpoint);
  }

  /// Save an allergen incident or plan entry
  Future<void> saveAllergen(Map<String, dynamic> allergenRecord) async {
    final key = 'allergen_${DateTime.now().millisecondsSinceEpoch}';
    await saveRecord(key, allergenRecord);
  }

  /// Get a record by key
  Map<String, dynamic>? getRecord(String key) {
    final v = _box.get(key);
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  /// Query records optionally by type field
  List<Map<String, dynamic>> queryRecords({String? type}) {
    final records = _box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (type == null) return records;
    return records.where((r) => r['type'] == type).toList();
  }

  List<Map<String, dynamic>> allRecords() => queryRecords();

  /// Return a map of key->record for all entries
  Map<String, Map<String, dynamic>> allEntries() {
    final Map<String, Map<String, dynamic>> out = {};
    for (final key in _box.keys) {
      final v = _box.get(key);
      if (v is Map) out[key.toString()] = Map<String, dynamic>.from(v);
    }
    return out;
  }
}
