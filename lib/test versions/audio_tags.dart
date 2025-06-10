// import 'dart:io';
// import 'package:dart_tags/dart_tags.dart';

// class AudioTags {
//   final TagProcessor _tagProcessor = TagProcessor();

//   Future<List<Tag>> getTagsFromFile(String filePath) async {
//     try {
//       final file = File(filePath);
//       final bytes = await file.readAsBytes();
//       return await _tagProcessor.getTagsFromByteArray(Future.value(bytes));
//     } catch (e) {
//       print('Ошибка при чтении тегов: $e');
//       return [];
//     }
//   }

//   Future<String?> getTitle(String filePath) async {
//     final tags = await getTagsFromFile(filePath);
//     for (var tag in tags) {
//       if (tag.toString().contains('TITLE')) {
//         return tag.toString().split('=')[1];
//       }
//     }
//     return null;
//   }

//   Future<String?> getArtist(String filePath) async {
//     final tags = await getTagsFromFile(filePath);
//     for (var tag in tags) {
//       if (tag.toString().contains('ARTIST')) {
//         return tag.toString().split('=')[1];
//       }
//     }
//     return null;
//   }
// } 