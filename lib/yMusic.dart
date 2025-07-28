import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:xml/xml.dart' as xml;
import 'dart:io';
import 'package:crypto/crypto.dart';

// Ктоо здесь? Гандооооны?

// Микро библия для работы с апи яндекс музыки. Завтра сделаем полноценную.

class YandexMusicAPI {
  static const String baseUrl = 'https://api.music.yandex.net';
  static const String imageSize =
      '300x300'; // Используем оптимальный размер (Время загрузки + качество)
  static const String likedPlaylistPictureUrl =
      'https://avatars.yandex.net/get-music-user-playlist/11418140/favorit-playlist-cover.bb48fdb9b9f4/$imageSize';

  // Создаем HTTP клиент от имени которого будем делать все запросы

  static final http.Client _httpClient = http.Client();

  /// Создаем header для нашего запроса

  static Map<String, String> getHeaders(String token) {
    return {
      'Authorization': 'OAuth $token',
      'Content-Type': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 YaBrowser/22.3.0.2436 YandexBrowser/22.3.0.2436 Safari/537.36',
    };
  }

  /// Кастомный get для удобного использования одного клиента

  static Future<http.Response> get(String url, String token) async {
    return await _httpClient.get(Uri.parse(url), headers: getHeaders(token));
  }

  /// Кастомный post для удобного использования одного клиента

  static Future<http.Response> post(
    String url,
    String token, {
    Map<String, dynamic>? queryParams,
  }) async {
    final uri =
        queryParams != null
            ? Uri.parse(url).replace(queryParameters: queryParams)
            : Uri.parse(url);

    return await _httpClient.post(uri, headers: getHeaders(token));
  }

  /// Получение полной информации об аккаунте пользователя используя токен. Чаще всего нужен UID пользователя
  static Future<Map<String, dynamic>> getAccountDetails(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/account/status'),
        headers: {
          'Authorization': 'OAuth $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'HTTP ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Полноценное получение URL картинки плейлиста
  static String? getPictureUrlForPlaylist(
    Map<String, dynamic>? cover, {
    String size = imageSize,
  }) {
    if (cover == null) return null;

    String? type = cover['type'];

    if (type == 'pic' && cover['uri'] != null) {
      String uri = cover['uri'].toString();
      return 'https://${uri.replaceAll('%%', size)}';
    } else if (type == 'mosaic' && cover['itemsUri'] != null) {
      List<dynamic> itemsUri = cover['itemsUri'];
      if (itemsUri.isNotEmpty) {
        String firstUri = itemsUri[0].toString();
        return 'https://${firstUri.replaceAll('%%', size)}';
      }
    }

    return null;
  }

  /// Получаем список всех плейлистом пользователя, дополнительно добавляя плейлист Мне нравится
  /// Результат возвращается в кастомной мапе
  static Future<List> getPlaylists(String uid, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$uid/playlists/list'),
      headers: {
        'Authorization': 'OAuth $token',
        'Content-Type': 'application/json',
      },
    );

    List playlists = [];
    playlists.add({
      'title': 'Liked',
      'picture': likedPlaylistPictureUrl,
      'accountUuid': uid,
      'accountToken': token,
    });
    print(jsonDecode(response.body));
    if (jsonDecode(response.body)['error'] != null) {
      print('error');
      return playlists;
    }
    for (var playlist in jsonDecode(response.body)['result']) {
      int duration = playlist['durationMs'];
      Map<String, dynamic> playlistData = {
        'playlistUuid': playlist['playlistUuid'],
        'available': playlist['available'],
        'title': playlist['title'],
        'trackCount': playlist['trackCount'],
        'visibility': playlist['visibility'],
        'duration': duration,
        'picture': getPictureUrlForPlaylist(playlist['cover']),
        'accountUuid': uid,
        'accountToken': token,
        'kind': playlist['kind'],
      };
      playlists.add(playlistData);
    }

    return playlists;
  }

  /// Получение картинки плейлиста в байтовом формате
  static Future<Uint8List> downloadPlaylistImage(String? imageUrl) async {
    if (imageUrl == null) return Uint8List(0);

    try {
      final response = await http.get(Uri.parse('https://$imageUrl'));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {}
    return Uint8List(0);
  }

  /// Получаем полную информацию о плейлисте включая треки, которые в нем находятся.
  static Future<List> getPlaylistFromKind(
    String uid,
    String token,
    int kind,
  ) async {
    List a = [];

    final response = await http.get(
      Uri.parse('$baseUrl/users/$uid/playlists/$kind'),
      headers: {
        'Authorization': 'OAuth $token',
        'Content-Type': 'application/json',
      },
    );

    for (var track in jsonDecode(response.body)['result']['tracks']) {
      Map b = {
        'id': track['id'].toString(),
        'title': track['track']['title'] ?? '',
        'cover': track['track']['coverUri'].toString().replaceAll(
          "%%",
          "300x300",
        ),
        'artists':
            track['track']['artists'].isNotEmpty
                ? track['track']['artists'][0]['name']
                : 'Unknown',
      };
      a.add(b);
    }

    return a;
  }

  /// Получение полной ссылки на скачивания трека используя только trackID.
  /// Ссылка действует < 30 минут
  static Future<String> getTrackDownloadLink(
    String trackID,
    String token,
    String uid,
  ) async {
    // Получаем информацию о том как мы можем скачать этот трек

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tracks/$trackID/download-info'),
        headers: {
          'Authorization': 'OAuth $token',
          'Content-Type': 'application/json',
        },
      );

      // Результат получаем в XML
      print(jsonDecode(response.body));

      var xmlLink =
          jsonDecode(
            response.body,
          )['result'][0]['downloadInfoUrl']; // Получаем ссылку на самое высокое качество. Todo: сделать выбор качества. Сделаем завтра.
      // print(xmlLink);
      // Парсим XML
      final infoResponse = await http.get(
        Uri.parse(xmlLink),
        headers: {
          'Authorization': 'OAuth $token',
          'Content-Type': 'application/json',
        },
      );

      if (infoResponse.statusCode != 200) {
        print('XML Error: ${infoResponse.statusCode}');
        return '';
      }
      // Получаем все данные из нашего ответа
      final xmlDoc = xml.XmlDocument.parse(infoResponse.body);

      final host = xmlDoc.findAllElements('host').first.text;
      final path = xmlDoc.findAllElements('path').first.text;
      final ts = xmlDoc.findAllElements('ts').first.text;
      final s = xmlDoc.findAllElements('s').first.text;

      // Создаем сверх секретную подпись для скачивания трека которую яндекс сделали по приколу

      const signSalt = 'XGRlBW9FXlekgbPrRHuSiA';
      final signData = signSalt + path.substring(1) + s;
      final signBytes = utf8.encode(signData);
      final sign = md5.convert(signBytes).toString();

      // Формируем ссылку для скачивания

      final directLink = 'https://$host/get-mp3/$sign/$ts$path';

      return directLink;
    } catch (e) {
      return '$e';
    }
  }

  /// Скачивает трек в указанную директорию с уже сформированным именем файла!
  static Future<bool> downloadTrack(
    String filenameWithFilepath,
    String downloadLink,
  ) async {
    try {
    final response3 = await http.get(Uri.parse(downloadLink));

    if (response3.statusCode == 200) {
      final file = File(filenameWithFilepath);
      await file.writeAsBytes(response3.bodyBytes);
      print('downloaded!');
      return true;

    } else {
      print('NOT !');

      return false;
    }
    } catch (e) {print(e); return false; }

  }

  /// Получение информации о нескольких треках используя их ID
  static Future<List> getTracksFromIDS(
    List trackIDS,
    String token,
    String uid,
  ) async {
    List tracks = [];
    final response = await http.post(
      Uri.parse(
        '$baseUrl/tracks/',
      ).replace(queryParameters: {'track-ids': trackIDS}),
      headers: {
        'Authorization': 'OAuth $token',
        'Content-Type': 'application/json',
      },
    );

    for (var track in jsonDecode(response.body)['result']) {
      Map b = {
        'id': track['id'].toString(),
        'title': track['title'] ?? '',
        'cover': track['coverUri'].toString().replaceAll("%%", "300x300"),
        'artists':
            track['artists'].isNotEmpty
                ? track['artists'][0]['name']
                : 'Unknown',
      };
      tracks.add(b);
    }
    return tracks;
  }

  /// Получение всех лайкнутых треков пользователя
  static Future<List> getLikedSongs(String token, String uid) async {
    final response3 = await get('$baseUrl/users/{uid}/likes/tracks', token);
    List tracks = jsonDecode(response3.body)['result']['library']['tracks'];
    List output = [];

    List query = [];

    for (var track in tracks) {
      query.add(track['id'].toString());
    }

    output = await getTracksFromIDS(query, token, uid);

    return output;
  }

  /// Скачивание первых треков всех плейлистов пользователя включая Liked Songs.
  /// Тк yandex music api не умеет в поток делаем оптимизацию чтобы пользователю не пришлось ждать лишнюю секунду.
  /// Да, я засунул функцию в класс, которая требуется в 1 месте и че
  static Future<List> downloadFirstTracksFromAllUsersPlaylistsIntoTempFolder(
    String token,
    String uid,
  ) async {
    var playlists = await getPlaylists(uid, token);
    playlists.removeAt(0);

    getLikedSongs(token, uid).then((likedSongs) {
      getApplicationCacheDirectory().then((tempDirectory) async {
        var tempDir = tempDirectory.path;

        String filename =
            '${tempDir}/quarkaudiotemptrack${likedSongs[0]['id']}.mp3';
        var trackfile = File(filename);
        bool exist = await trackfile.exists();
        if (!exist) {
          try {
            getTrackDownloadLink(likedSongs[0]['id'], token, uid).then((link) {
              downloadTrack(filename, link);
            });
          } catch (e) {
            print('An error has occured: $e');
          }
        }
      });
    });

    for (var playlist in playlists) {
      getPlaylistFromKind(uid, token, playlist['kind']).then((onValue) async {
        getApplicationCacheDirectory().then((tempDirectory) async {
          var tempDir = tempDirectory.path;

          String filename =
              '${tempDir}/quarkaudiotemptrack${onValue[0]['id']}.mp3';
          var trackfile = File(filename);
          bool exist = await trackfile.exists();
          if (!exist) {
            try {
              getTrackDownloadLink(onValue[0]['id'], token, uid).then((link) {
                downloadTrack(filename, link);
              });
            } catch (e) {
              print('An error has occured: $e');
            }
          }
        });
      });
    }

    return [];
  }
}


// special thanks to the developer of the python library yandex_music

