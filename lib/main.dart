import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'playlist_page.dart';
import 'package:quark/database.dart';
import 'package:smtc_windows/smtc_windows.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Database.init();
  await SMTCWindows.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QUARK',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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

  Future<void> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
      );

      if (result != null) {
        setState(() {
          selectedFiles = result.paths.map((path) => path!).toList();
        });

        navigateToPlaylist();
      }
    } catch (e) {
      print('An error occurred while retrieving the selected single file: $e');
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

  InAppWebViewController? webViewController;

  void showYMLoginWebview() {
    warningMetadataOverlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            child: SlideTransition(
              position: getYMTokenOffsetAnimation,
              child: Center(child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 100) {
                      hideYMLoginWebview();
                    }
                  },

                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                      child: Container(
                        width: 400,
                        height: 690,
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
                                  initialUrlRequest: URLRequest(url: WebUri('https://oauth.yandex.ru/authorize?response_type=token&client_id=23cabbbdc6cd418abb4b39c32c41195d')),
                                  initialSettings: InAppWebViewSettings(
                                    javaScriptEnabled: true,
                                  ),
                                  onWebViewCreated: (controller) {
                                    webViewController = controller;
                                  },
                                  onLoadStart: (controller, url) {
                                    print('Начал загрузку: $url');
                                    if (url.toString().contains('access_token')) {
                                    try {
                                      final token = url.toString().split('#')[1].split('&')[0].replaceAll('access_token=', '');
                                      if (token.length > 3) {
                                        print(token);
                                        Database.setValue("ymtoken", token);
                                          // if (warningMetadataOverlayEntry != null) {
                                          //   warningMetadataOverlayEntry!.remove();
                                          //   warningMetadataOverlayEntry = null;
                                          // }
                                          // // Опционально: сброс анимации
                                          // warningMetadataAnimationController.reverse();
                                      }
                                    } catch (ex) {}
                                  }
                                  },
                                  onLoadStop: (controller, url) {
                                    print('Загрузка завершена: $url');
                                  },
                                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                                    print('Переход на: $url');
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
            )),
          ),
    );

    Overlay.of(context).insert(warningMetadataOverlayEntry!);
    getYMTokenAnimationController.forward();
  }

  void hideYMLoginWebview() {
    getYMTokenAnimationController.reverse().then((_) {
      warningMetadataOverlayEntry?.remove();
      warningMetadataOverlayEntry = null;
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

  }
  
  String restorePlaylistButtonText = 'Restore playlist';

  late AnimationController getYMTokenAnimationController;
  late Animation<Offset> getYMTokenOffsetAnimation;
  OverlayEntry? warningMetadataOverlayEntry;

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
                              onTap: () {showYMLoginWebview();},
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
