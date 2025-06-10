import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';




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




class DatabaseCheckResult {
  final bool success;
  final String? value;
  final String? error;

  DatabaseCheckResult({
    required this.success,
    this.value,
    this.error,
  });
}



Future<Map<String, dynamic>> saveVariables(List<Map<String, dynamic>> variables) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    for (final variable in variables) {
      final name = variable['name'] as String;
      final type = variable['type'] as String;
      final value = variable['value'];

      switch (type) {
        case 'String':
          await prefs.setString(name, value as String);
          break;
        case 'int':
          await prefs.setInt(name, value as int);
          break;
        case 'double':
          await prefs.setDouble(name, value as double);
          break;
        case 'bool':
          await prefs.setBool(name, value as bool);
          break;
        case 'List<String>':
          await prefs.setStringList(name, value as List<String>);
          break;
        default:
          throw 'Unsupported type: $type';
      }
    }

    return {'success': true};
  } catch (e) {
    return {
      'success': false,
      'error': e.toString()
    };
  }
}



Future<DatabaseCheckResult> checkDatabaseExists() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final databaseState = await prefs.getKeys().isNotEmpty;

    return 
      DatabaseCheckResult(
        success: true,
        value: databaseState.toString(),
        error: null
        );

  } catch (e) {
    return 
      DatabaseCheckResult(
        success: false,
        value: null,
        error: e.toString()
      );

  }
}


Future<dynamic> getVariable(String variableName) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    var result = prefs.get(variableName);
    return result;

  } catch (e) {return {};}



} 