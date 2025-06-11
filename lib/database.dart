import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
// now database accepting this variables:

// light_theme BOOLEAN
// show_albumart_as_background BOOLEAN
// volume DOUBLE
// last_playlist STRING or LIST      (list with many file links)
// shuffle_mode BOOLEAN
// repeat_mode INTEGER
// first_run BOOLEAN

// future updates

// accent_color STRING
// language STRING

// DATABASE SHAREDPREFERENCES

class DatabasePreferences {
  static SharedPreferences? _prefs;
  static bool _isInitializing = false;

  static Future<SharedPreferences> _ensureInitialized() async {
    if (_prefs != null) return _prefs!;

    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return _prefs!;
    }

    _isInitializing = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs!;
    } finally {
      _isInitializing = false;
    }
  }

  static Future<void> init() async {
    await _ensureInitialized();
  }

  static Future<bool> setValue<T>(String key, T value) async {
    final prefs = await _ensureInitialized();

    switch (T) {
      case String:
        return await prefs.setString(key, value as String);
      case int:
        return await prefs.setInt(key, value as int);
      case double:
        return await prefs.setDouble(key, value as double);
      case bool:
        return await prefs.setBool(key, value as bool);
      case const (List<String>):
        return await prefs.setStringList(key, value as List<String>);
      default:
        throw ArgumentError(
          'An error has occured. Type $T is not supported by database',
        );
    }
  }

  static Future<dynamic> getValue(String key) async {
    final prefs = await _ensureInitialized();

    if (!prefs.containsKey(key)) {
      return null;
    }

    return prefs.get(key);
  }

  static Future<bool> containsKey(String key) async {
    final prefs = await _ensureInitialized();
    return prefs.containsKey(key);
  }

  static Future<Set<String>> getKeys() async {
    final prefs = await _ensureInitialized();
    return prefs.getKeys();
  }

  static Future<bool> remove(String key) async {
    final prefs = await _ensureInitialized();
    return await prefs.remove(key);
  }

  static Future<bool> clear() async {
    final prefs = await _ensureInitialized();
    return await prefs.clear();
  }
}

// 
// 
// HIVE DATABASE
// 
// 

class Database {
  static Box? _box;
  static bool _isInitializing = false;

  static Future<Box> _ensureInitialized() async {
    if (_box != null) return _box!;

    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return _box!;
    }

    _isInitializing = true;
    try {
      _box = await Hive.openBox('database');
      return _box!;
    } finally {
      _isInitializing = false;
    }
  }

  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);
    await _ensureInitialized();
  }

  static Future<bool> setValue<T>(String key, T value) async {
    final box = await _ensureInitialized();

    switch (T) {
      case String:
      case int:
      case double:
      case bool:
      case const (List<String>):
      case const (List<Map<String, dynamic>>):
        try {
          await box.put(key, value);
          return true;
        } catch (e) {
          return false;
        }
      default:
        throw ArgumentError(
          'An error has occured. Type $T is not supported by database',
        );
    }
  }

  static Future<dynamic> getValue(String key) async {
    final box = await _ensureInitialized();

    if (!box.containsKey(key)) {
      return null;
    }

    return box.get(key);
  }

  static Future<bool> containsKey(String key) async {
    final box = await _ensureInitialized();
    return box.containsKey(key);
  }

  static Future<Set<String>> getKeys() async {
    final box = await _ensureInitialized();
    return box.keys.cast<String>().toSet();
  }

  static Future<bool> remove(String key) async {
    final box = await _ensureInitialized();
    try {
      await box.delete(key);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clear() async {
    final box = await _ensureInitialized();
    try {
      await box.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getDirectory() async {
    final box = await _ensureInitialized();
    var path = box.path.toString();
    print(path);
    return path;
  }

  
}
