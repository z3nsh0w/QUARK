import 'package:audio_service/audio_service.dart';
import 'package:audio_service_mpris/audio_service_mpris.dart';
import 'package:smtc_windows/smtc_windows.dart';
import 'dart:io';



class Nativemedia {

  static Future<void> initialize() async {
    if (Platform.isWindows) {
      await SMTCWindows.initialize();
    }
    if (Platform.isMacOS) {
      
    }
    
    if (Platform.isLinux) {
      
    }
  }


}