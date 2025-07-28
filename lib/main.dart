import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'playlist_page.dart';
import 'package:quark/database.dart';
// import 'package:smtc_windows/smtc_windows.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'yMusic.dart';
import 'ymPlaylistPage.dart';

// Temp folder at this app is a Local/quark/quarkaudio or .local/quark/quarkaudio for linux

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Database.init();
  // await SMTCWindows.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QUARK',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  String? selectedFolderPath;
  List<String> files = [];
  List<String> selectedFiles = [];
  String lastSong = '';
  List userPlaylists = [];
  bool reloginNeed = false;
  final TextEditingController _tokenController = TextEditingController();

  void navigateToPlaylist() {
    if (selectedFiles.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  PlaylistPage(songs: selectedFiles, lastSong: lastSong),
        ),
      );
    }
  }

  void navigateToYMPlaylistPage(
    List<String> songs,
    List ymTrackInfo,
    String uid,
    String token,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ymPlaylistPage(
              songs: songs,
              ymTracksInfo: ymTrackInfo,
              ymToken: token,
              ymUid: uid,
            ),
      ),
    );
  }

  Future<void> pickFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        setState(() {
          selectedFolderPath = selectedDirectory;
          files = [];
          selectedFiles = [];
        });
        await getFilesFromDirectory(selectedDirectory);
        navigateToPlaylist();
      }
    } catch (e) {
      print('An error occurred while retrieving the file folder: $e');
    }
  }

  Future<void> getFilesFromDirectory(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      final List<String> fileNames = [];

      await for (final entity in dir.list()) {
        if (entity is File) {
          if (entity.path.toLowerCase().endsWith('.mp3') ||
              entity.path.toLowerCase().endsWith('.wav') ||
              entity.path.toLowerCase().endsWith('.flac') ||
              entity.path.toLowerCase().endsWith('.aac') ||
              entity.path.toLowerCase().endsWith('.m4a')) {
            fileNames.add(entity.path);
          }
        }
      }

      setState(() {
        files = fileNames.map((path) => path.split('/').last).toList();
        selectedFiles = fileNames;
      });
    } catch (e) {
      print(
        'An error occurred while retrieving the selected multiple file: $e',
      );
    }
  }

  Future<void> restorePlaylist() async {
    try {
      final dynamic lastPlaylist = await Database.getValue('lastPlaylist');
      final dynamic lastSong2 = await Database.getValue('lastPlaylistTrack');

      if (lastPlaylist != null && lastPlaylist is List<dynamic>) {
        setState(() {
          selectedFiles = List<String>.from(lastPlaylist);
          restorePlaylistButtonText = 'Restore playlist';
        });

        if (lastSong2 != null) {
          setState(() {
            lastSong = lastSong2;
          });
        }

        navigateToPlaylist();
      } else {
        setState(() {
          restorePlaylistButtonText =
              'Ooops... Your previous playlist is empty.';
        });
      }
    } catch (e) {
      setState(() {
        restorePlaylistButtonText = 'Ooops... Your previous playlist is empty.';
      });
      print('Error: $e');
    }
  }

  Future<void> loadYMPlaylist(List tracks, String uid, String token) async {
    print('-------------------------------');
    print(tracks);
    print('aaaaa');
    List<String> fileMap = [];
    // getApplicationSupportDirectory().then((direc) {print(direc);});
    // getApplicationDocumentsDirectory().then((direc) {print(direc);});
    getApplicationCacheDirectory().then((direc) {
      print(direc);
    });
    getApplicationCacheDirectory().then((directory) {
      String tempDir = directory.path;
      for (var track in tracks) {
        fileMap.add('${tempDir}/quarkaudiotemptrack${track['id']}.mp3');
      }
    });

    hideYMInterface().then((_) {
      navigateToYMPlaylistPage(fileMap, tracks, uid, token);
    });

    // Map track = {
    //   'available': true,
    //   'downloading': false,
    //   'filepath': '....',
    //   'ymusic': true,
    //   'coverart': Uint8List(0),
    //   'title': '',
    //   'artists': [],
    //   'ymTrackId': '',
    //   'ymPlaylistKind': '',
    //   'ymPlaylistUid': '',

    // };

    // YandexMusicAPI.getPlaylists(uid, token).then(
    //   (playlists) async {
    //     String tempDir = r'C:\Users\zenar56\Documents\Quark';

    //     List trackIds = [];
    //     playlists.removeAt(0);
    //     try {
    //     getTemporaryDirectory().then((temp) async {
    //             for (var playlist in playlists) {
    //       YandexMusicAPI.getPlaylistFromKind(uid, token, playlist['kind']).then((playlist2) {
    //         for (var track in playlist2) {
    //           YandexMusicAPI.getTrackDownloadLink(track['id'], token, uid).then((downloadLink) async {
    //           var a = await YandexMusicAPI.downloadTrack('${tempDir}/quarkaudiotemptrack${track['id']}.mp3', downloadLink);
    //           print('download ${track['id']}');
    //           });
    //         }
    //       });
    //     }
    //     });

    //     YandexMusicAPI.getLikedSongs(token, uid).then((songs) async {
    //     for (var track in songs) {
    //           YandexMusicAPI.getTrackDownloadLink(track['id'], token, uid).then((downloadLink) async {
    //           var a = await YandexMusicAPI.downloadTrack('${tempDir}/quarkaudiotemptrack${track['id']}.mp3', downloadLink);
    //           print('download ${track['id']}');

    //           });
    //         }
    //     });
    //     } catch (e) {print(e);}

    //   }

    // );
  }

  void showYMInterface() {
    YandexMusicAPI.downloadFirstTracksFromAllUsersPlaylistsIntoTempFolder(
      userPlaylists[0]['accountToken'],
      userPlaylists[0]['accountUuid'].toString(),
    ).then((onValue) {
      print(onValue);
    });
    getYMInterfaceOverlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            child: SlideTransition(
              position: getYMInterfaceOffsetAnimation,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity!.abs() > 500) {
                        if (details.primaryVelocity! < -500 ||
                            details.primaryVelocity! > 500) {
                          hideYMInterface();
                        }
                      }
                    },

                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                        child: Container(
                          width: math.min(
                            MediaQuery.of(context).size.width * 0.92,
                            1040,
                          ),
                          height: math.min(
                            MediaQuery.of(context).size.height * 0.92,
                            1036,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(36.0),
                            child: Wrap(
                              spacing: 16.0,
                              runSpacing: 16.0,
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              direction: Axis.horizontal,
                              children: List.generate(userPlaylists.length, (
                                index,
                              ) {
                                return InkWell(
                                  onHover: (value) {},
                                  onTap: () async {
                                    List trackList = [];
                                    if (index != 0) {
                                      trackList =
                                          await YandexMusicAPI.getPlaylistFromKind(
                                            userPlaylists[index]['accountUuid']
                                                .toString(),
                                            userPlaylists[index]['accountToken'],
                                            userPlaylists[index]['kind'],
                                          );
                                    } else {
                                      trackList =
                                          await YandexMusicAPI.getLikedSongs(
                                            userPlaylists[index]['accountToken'],
                                            userPlaylists[index]['accountUuid']
                                                .toString(),
                                          );
                                    }

                                    hideYMInterface();
                                    loadYMPlaylist(
                                      trackList,
                                      userPlaylists[index]['accountUuid']
                                          .toString(),
                                      userPlaylists[index]['accountToken'],
                                    );
                                  },
                                  child: Container(
                                    width: 310,
                                    height: 310,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(15),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          userPlaylists[index]['picture'],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.8),
                                                  Colors.black.withOpacity(0.4),
                                                  Colors.transparent,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(15),
                                                bottomRight: Radius.circular(
                                                  15,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              userPlaylists[index]['title'],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(getYMInterfaceOverlayEntry!);
    getYMInterfaceAnimationController.forward();
  }

  Future<void> hideYMInterface() {
    return getYMInterfaceAnimationController.reverse().then((_) {
      getYMInterfaceOverlayEntry?.remove();
      getYMInterfaceOverlayEntry = null;
    });
  }

  void showYMLoginWebview() {
    if (Platform.isLinux) {
      getYMLoginOverlayEntry = OverlayEntry(
        builder:
            (context) => Positioned(
              child: SlideTransition(
                position: getYMTokenOffsetAnimation,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity!.abs() > 500) {
                          if (details.primaryVelocity! < -500 ||
                              details.primaryVelocity! > 500) {
                            hideYMLoginWebview();
                          }
                        }
                      },

                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(15),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                          child: Container(
                            width: 400,
                            height: 520,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(20),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(25),
                                child: Column(
                                  children: [
                                    Text(
                                      "Native connection of Yandex Music through a browser window is currently unavailable.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      "So you can manually enter the Yandex Music access token.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),

                                    SizedBox(height: 70),

                                    TextField(
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                      controller: _tokenController,
                                      decoration: InputDecoration(
                                        hintText: 'Enter token here',
                                        hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.key,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        filled: false,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 15),

                                    ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(15),
                                      ),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 175,
                                          sigmaY: 175,
                                        ),
                                        child: Container(
                                          height: 45,
                                          width: 250,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                            borderRadius:
                                                const BorderRadius.all(
                                                  Radius.circular(20),
                                                ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topRight,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white.withOpacity(0.15),
                                                Colors.white.withOpacity(0.05),
                                              ],
                                            ),
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                            onTap: () {
                                              print(
                                                _tokenController.value.text,
                                              );
                                              try {
                                                String token =
                                                    _tokenController.value.text;
                                                if (token.length > 3) {
                                                  print(token);
                                                  YandexMusicAPI.getAccountDetails(
                                                    token,
                                                  ).then((data) {
                                                    if (data.containsKey(
                                                      'error',
                                                    )) {
                                                      print(data);
                                                      _tokenController
                                                          .value = TextEditingValue(
                                                        text:
                                                            'error! invalid token!',
                                                      );
                                                    } else {
                                                      print('else');
                                                      Database.setValue(
                                                        "ymtoken",
                                                        token,
                                                      );
                                                      int ymuid =
                                                          data['result']['account']['uid'];
                                                      print(ymuid);
                                                      print(ymuid.toString());

                                                      String defaultEmail =
                                                          data['result']['defaultEmail'];
                                                      // var hostname = data['invocationInfo']['hostname'];
                                                      // var activeSubscriptions = data['result']['masterhub']['activeSubscriptions'];
                                                      // var availableSubscriptions = data['result']['masterhub']['availableSubscriptions'];
                                                      var hadAnySubscription = data['result']['subscription']['hadAnySubscription'];
                                                      print(hadAnySubscription);
                                                      // var canStartTrial = data['result']['subscription']['canStartTrial'];

                                                      Database.setValue(
                                                        "ymuid",
                                                        ymuid.toString(),
                                                      );
                                                      Database.setValue(
                                                        "ymemail",
                                                        defaultEmail.toString(),
                                                      );

                                                      YandexMusicAPI.getPlaylists(
                                                        ymuid.toString(),
                                                        token,
                                                      ).then((playlists) {
                                                        userPlaylists =
                                                            playlists;
                                                        getYMTokenAnimationController
                                                            .reverse();
                                                        showYMInterface();
                                                      });
                                                    }
                                                  });
                                                }
                                              } catch (ex) {}
                                            },
                                            child: Center(
                                              child: Text(
                                                'Submit',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 75),
                                    Text(
                                      "Read about how to obtain a token on our GitHub.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      );
    } else {
      getYMLoginOverlayEntry = OverlayEntry(
        builder:
            (context) => Positioned(
              child: SlideTransition(
                position: getYMTokenOffsetAnimation,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity!.abs() > 500) {
                          if (details.primaryVelocity! < -500 ||
                              details.primaryVelocity! > 500) {
                            hideYMLoginWebview();
                          }
                        }
                      },

                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(15),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                          child: Container(
                            width: 400,
                            height: 650,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(20),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: InAppWebView(
                                    initialUrlRequest: URLRequest(
                                      url: WebUri(
                                        'https://oauth.yandex.ru/authorize?response_type=token&client_id=23cabbbdc6cd418abb4b39c32c41195d',
                                      ),
                                    ),
                                    initialSettings: InAppWebViewSettings(
                                      javaScriptEnabled: true,
                                    ),
                                    onWebViewCreated: (controller) {
                                      webViewController = controller;
                                    },
                                    onLoadStop: (controller, url) async {
                                      if (url.toString().contains(
                                        'access_token',
                                      )) {
                                        try {
                                          String token = url
                                              .toString()
                                              .split('#')[1]
                                              .split('&')[0]
                                              .replaceAll('access_token=', '');
                                          if (token.length > 3) {
                                            print(token);
                                            YandexMusicAPI.getAccountDetails(
                                              token,
                                            ).then((data) {
                                              if (data.containsKey('error')) {
                                              } else {

                                                int ymuid =
                                                    data['result']['account']['uid'];
                                                print(ymuid);
                                                print(ymuid.toString());

                                                String defaultEmail =
                                                    data['result']['defaultEmail'];
                                                // var hostname = data['invocationInfo']['hostname'];
                                                var activeSubscriptions = data['result']['masterhub']['activeSubscriptions'];
                                                // var availableSubscriptions = data['result']['masterhub']['availableSubscriptions'];
                                                var hadAnySubscription = data['result']['subscription']['hadAnySubscription'];
                                                print(hadAnySubscription);
                                                // var canStartTrial = data['result']['subscription']['canStartTrial'];
                                                print(data);

                                                // if (activeSubscriptions.isEmpty && !reloginNeed && data['result']['subscription']['familyAutoRenewable']) {
                                                //   reloginNeed = true;
                                                //   controller.loadUrl(urlRequest: URLRequest(url: WebUri('https://quarkaudio.github.io/no-plus-subscription-on-yandex-music-page/')));
                                                // } else if (reloginNeed) {
                                                //   reloginNeed = false;
                                                // } else {  
                                                //   print('LOGINED!');
                                                Database.setValue(
                                                    "ymtoken",
                                                    token,
                                                );
                                                Database.setValue(
                                                  "ymuid",
                                                  ymuid.toString(),
                                                );
                                                Database.setValue(
                                                  "ymemail",
                                                  defaultEmail.toString(),
                                                );

                                                YandexMusicAPI.getPlaylists(
                                                  ymuid.toString(),
                                                  token,
                                                ).then((playlists) {
                                                  userPlaylists = playlists;
                                                  getYMTokenAnimationController
                                                      .reverse();
                                                  showYMInterface();
                                                });
                                                

                                              }
                                            });
                                          }
                                        } catch (ex) {}
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      );
    }

    Overlay.of(context).insert(getYMLoginOverlayEntry!);
    getYMTokenAnimationController.forward();
  }

  void hideYMLoginWebview() {
    getYMTokenAnimationController.reverse().then((_) {
      getYMLoginOverlayEntry?.remove();
      getYMLoginOverlayEntry = null;
    });
  }

  @override
  void initState() {
    super.initState();
    getYMTokenAnimationController = AnimationController(
      duration: Duration(milliseconds: (650).round()),
      vsync: this,
    );

    getYMTokenOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: getYMTokenAnimationController,
        curve: Curves.ease,
      ),
    );
    getYMInterfaceAnimationController = AnimationController(
      duration: Duration(milliseconds: (650).round()),
      vsync: this,
    );

    getYMInterfaceOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: getYMInterfaceAnimationController,
        curve: Curves.ease,
      ),
    );
  }

  String restorePlaylistButtonText = 'Restore playlist';
  InAppWebViewController? webViewController;

  late AnimationController getYMTokenAnimationController;
  late Animation<Offset> getYMTokenOffsetAnimation;
  OverlayEntry? getYMLoginOverlayEntry;

  late AnimationController getYMInterfaceAnimationController;
  late Animation<Offset> getYMInterfaceOffsetAnimation;
  OverlayEntry? getYMInterfaceOverlayEntry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          // MAIN CONTAINER THAT CONTAINS MAIN PAGE
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(24, 24, 26, 1),
                Color.fromRGBO(18, 18, 20, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: Color.fromRGBO(40, 40, 40, 1),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 95.0, sigmaY: 95.0),
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/play.png', width: 150, height: 150),
                    SizedBox(height: 25),
                    SizedBox(
                      width: 400,
                      child: Text(
                        'QUARK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: 400,
                      child: Text(
                        'Select a file or folder, or drag files from the file manager into the application window to add songs to the playlist.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 30),

                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 175, sigmaY: 175),
                        child: Container(
                          height: 45,
                          width: 350,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            child: InkWell(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              onTap: restorePlaylist,
                              child: Center(
                                child: Text(
                                  restorePlaylistButtonText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 175, sigmaY: 175),
                        child: Container(
                          height: 45,
                          width: 350,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              onTap: pickFolder,
                              child: Center(
                                child: Text(
                                  'Add folder',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 175, sigmaY: 175),
                        child: Container(
                          height: 45,
                          width: 350,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            child: InkWell(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              onTap: () {
                                Database.getValue("ymuid").then((uid) {
                                  Database.getValue("ymtoken").then((token) {
                                    if (uid != null && token != null) {
                                      YandexMusicAPI.getPlaylists(
                                        uid,
                                        token,
                                      ).then((playlists) {
                                        userPlaylists = playlists;
                                        showYMInterface();
                                      });
                                    } else {
                                      showYMLoginWebview();
                                      }
                                  });
                                });
                              },
                              child: Center(
                                child: Text(
                                  'Yandex Music',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
