import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final player = AudioPlayer();
  final filePath = r'/home/zenar56/Музыка/А-для-вас-я-никто-_LUxKVjQPuXE_.wav';
  
  // Проверяем, существует ли файл
  if (await File(filePath).exists()) {
    await player.play(DeviceFileSource(filePath));
    print('Воспроизведение начато');
  } else {
    print('Файл не найден по пути: $filePath');
  }
}