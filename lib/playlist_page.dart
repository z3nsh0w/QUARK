import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';
import 'dart:typed_data';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:player_project/styles.dart';

final log = Logger('ExampleLogger');



// class AudioManager {
//   static final AudioManager _instance = AudioManager._internal();
  
//   factory AudioManager() {
//     return _instance;
//   }
  
//   AudioManager._internal();
  
//   final recorderController = RecorderController();
//   final playerController = PlayerController();
//   final audioPlayer = AudioPlayer();
  
//   void dispose() {
//     recorderController.dispose();
//     playerController.dispose();
//     audioPlayer.dispose();
//   }
// }



// INSTANCES

final RecorderController recorderController = RecorderController();
final PlayerController playerController = PlayerController();
bool _isSettingsHovered = false;

// INSTANCES



class PlaylistPage extends StatefulWidget {
  final List<String> songs;
  const PlaylistPage({super.key, required this.songs});


  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  double _volumeValue = 0.25;
  bool _isPlaying = false;
  bool _shuffle_enabled = false;  //
  bool _repeater_status = false;  // dodelat' pidarasa

  final player = AudioPlayer();


 // FIELDS

  Uint8List imageData = Uint8List.fromList([]);

  
  int nowPlayingIndex = 0;
  String _trackName = '';
  String _trackArtist = '';
  String _album = '';
  String _albumArtist = '';
  int _trackNumber = 0;
  int _albumLength = 0;
  int _year = 0;
  String _genre = '';
  String _authorName = '';
  String _writerName = '';
  int _discNumber = 0;
  String _mimeType = '';
  int _trackDuration = 0;
  int _bitrate = 0;
  List<String>? trackArtistNames = [];
  String startup_track = '';

// FIELDS



  void _initializeWaveform() async {
    try {


      if (widget.songs.isEmpty) {
        print("кто здесь");
        return;
      }

      final path = widget.songs[nowPlayingIndex];

      print(path);

      
      if (!File(path).existsSync()) {
        print("нет никого");
        return;
      }

      playerController.preparePlayer(
        path: path,
        volume: 0,
        shouldExtractWaveform: true
      );

      
      final waveformData = await playerController.extractWaveformData(
        path: path,
      );
      
      if (waveformData.isEmpty) {
          print("кто здесь гандоны");
          return;
        }

      setState( () {} );

    } catch (e) {
      print(e);
    }
  }


  Future<Map<String, dynamic>> _loadTag_using_dart_tags() async {
    try {
      final metadata = await MetadataRetriever.fromFile(
        File(widget.songs[nowPlayingIndex]),
      );

      String? trackName = metadata.trackName;
      List<String>? trackArtistNames = metadata.trackArtistNames;
      String? albumName = metadata.albumName;
      String? albumArtistName = metadata.albumArtistName;
      int? trackNumber = metadata.trackNumber;
      int? albumLength = metadata.albumLength;
      int? year = metadata.year;
      String? genre = metadata.genre;
      String? authorName = metadata.authorName;
      String? writerName = metadata.writerName;
      int? discNumber = metadata.discNumber;
      String? mimeType = metadata.mimeType;
      int? trackDuration = metadata.trackDuration;
      int? bitrate = metadata.bitrate;
      Uint8List? albumArt = metadata.albumArt;

      trackName = trackName ?? 'Unknown';
      trackArtistNames = trackArtistNames ?? ['Unknown'];
      albumName = albumName ?? 'Unknown';
      albumArtistName = albumArtistName ?? 'Unknown';
      genre = genre ?? 'Unknown';
      authorName = authorName ?? 'Unknown';
      writerName = writerName ?? 'Unknown';
      discNumber = discNumber ?? 0;
      mimeType = mimeType ?? 'Unknown';
      trackDuration = trackDuration ?? 0;
      bitrate = bitrate ?? 0;
      albumArt = albumArt ?? Uint8List.fromList([]);

      Map<String, dynamic> all_tags = {
        'trackName': trackName,
        'trackArtistNames': trackArtistNames,
        'albumName': albumName,
        'albumArtistName': albumArtistName,
        'trackNumber': trackNumber,
        'albumLength': albumLength,
        'year': year,
        'genre': genre,
        'authorName': authorName,
        'writerName': writerName,
        'discNumber': discNumber,
        'mimeType': mimeType,
        'trackDuration': trackDuration,
        'bitrate': bitrate,
        'albumArt': albumArt,
      };

      return all_tags;


    } catch (e) {
      log.severe('Error loading tag: $e');
      return {};
    }
  } 


  void _setupPlayerListeners() {
    player.onPlayerComplete.listen((_) async {
      setState(() {
        nowPlayingIndex++;
        if (nowPlayingIndex >= widget.songs.length) {
          nowPlayingIndex = 0;
        }
      });

      if (_isPlaying) {
        await playerController.startPlayer();
        await player.play(DeviceFileSource(widget.songs[nowPlayingIndex]));
      }

      Map<String, dynamic> a = await _loadTag_using_dart_tags();

      setState(() {
        _trackName =
            a['trackName']?.isEmpty ?? true
                ? widget.songs[nowPlayingIndex].split('/').last
                : a['trackName'];
        trackArtistNames =
            a['trackArtistNames'][0]?.isEmpty ?? true
                ? ['Unknown']
                : a['trackArtistNames'];
        imageData = a['albumArt'] ?? '/Users/aror/Documents/music/flacMusic/Radiohead - In Rainbows (2007) [FLAC] {XL Recordings XL1247CDJP}/Artwork/13.jpg';
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _setupPlayerListeners();
    // _initializeWaveform();
  }



  @override
  void dispose() {
    player.dispose();
    playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,

          decoration: BoxDecoration(
            image: DecorationImage(
              image: MemoryImage(imageData),

              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.25),
                BlendMode.darken,
              ),
            ),

            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(44, 44, 48, 1),
                Color.fromRGBO(34, 34, 38, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),

          child: ClipRect(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 1000),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: BackdropFilter(
                key: ValueKey<Uint8List>(imageData),
                filter: ImageFilter.blur(sigmaX: 95.0, sigmaY: 95.0),
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: MemoryImage(imageData),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0),
                              BlendMode.darken,
                            ),
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 21, 21, 21),
                              blurRadius: 10,
                              offset: Offset(5, 10),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 35),

                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 1000),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          _trackName,
                          key: ValueKey(_trackName),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Text(
                        trackArtistNames?.join(', ') ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      SizedBox(height: 35),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),

                            child: InkWell(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),

                              onTap: () async {
                                setState(() {
                                  nowPlayingIndex--;
                                  if (nowPlayingIndex < 0) {
                                    nowPlayingIndex = widget.songs.length - 1;
                                  }
                                });
                                player.stop();
                                

                                if (_isPlaying) {                                
                                  
                                  player.play(
                                    DeviceFileSource(
                                      widget.songs[nowPlayingIndex],
                                    ),
                                  );                        
                                }

                                Map<String, dynamic> a =
                                    await _loadTag_using_dart_tags();

                                setState(() {
                                  print(a['trackName']);
                                  if (a['trackName'] == '') {
                                    _trackName =
                                        widget.songs[nowPlayingIndex]
                                            .split('/')
                                            .last;
                                  } else {
                                    _trackName = a['trackName'];
                                  }

                                  if (a['trackArtistNames'][0] == "") {
                                    trackArtistNames = ['Unknown'];
                                  } else {
                                    trackArtistNames = a['trackArtistNames'];
                                  }
                                  imageData = a['albumArt'];
                                });
                              },

                              child: Container(
                                height: 40,
                                width: 40,

                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(56, 56, 59, 1),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.skip_previous,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 15),

                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),

                            child: InkWell(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              onTap: () {
                                setState(() {
                                  _isPlaying = !_isPlaying;

                                  if (!_isPlaying) {
                                    player.pause();
                                  } else {
                                    player.play(
                                      DeviceFileSource(
                                        widget.songs[nowPlayingIndex],
                                      ),
                                    );
                                  }
                                });
                              },

                              child: Container(
                                height: 50,
                                width: 50,

                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(56, 56, 59, 1),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 15),

                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),

                            child: InkWell(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              onTap: () async {
                                setState(() {
                                  nowPlayingIndex++;
                                  if (nowPlayingIndex >= widget.songs.length) {
                                    nowPlayingIndex = 0;
                                  }
                                  player.stop();
                                  if (_isPlaying) {
                                    player.play(
                                      DeviceFileSource(
                                        widget.songs[nowPlayingIndex],
                                      ),
                                    );
                                  }
                                });

                                Map<String, dynamic> a =
                                    await _loadTag_using_dart_tags();

                                setState(() {
                                  print(a['trackName']);
                                  if (a['trackName'] == '') {
                                    _trackName =
                                        widget.songs[nowPlayingIndex]
                                            .split('/')
                                            .last;
                                  } else {
                                    _trackName = a['trackName'];
                                  }

                                  if (a['trackArtistNames'][0] == "") {
                                    trackArtistNames = ['Unknown'];
                                  } else {
                                    trackArtistNames = a['trackArtistNames'];
                                  }
                                  imageData = a['albumArt'];
                                });
                              },
                              child: Container(
                                height: 40,
                                width: 40,

                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(56, 56, 59, 1),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.skip_next,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 15),

                      // Container(
                      //   child: AudioFileWaveforms(
                      //     waveformType: WaveformType.long,
                      //     size: Size(MediaQuery.of(context).size.width - 80, 35),
                      //     playerController: playerController,
                      //     playerWaveStyle: PlayerWaveStyle(
                      //       fixedWaveColor: Colors.purple.shade200,
                      //       liveWaveColor: Colors.purple.shade400,
                      //     ),
                      //     enableSeekGesture: true
                      //   ),
                      // ),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.volume_down,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 10),


                            Container(
                              width: 200,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                  thumbColor: Colors.transparent,
                                  overlayColor: Colors.transparent,
                                  trackHeight: 12.5,
                                  thumbShape: SliderComponentShape.noThumb,
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: _volumeValue,
                                  onChanged: (value) {
                                    setState(() {
                                      _volumeValue = value;
                                      player.setVolume(_volumeValue);
                                    });
                                    print(_volumeValue);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.volume_up,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      Row(
                      

                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MouseRegion(
                            onEnter: (_) => setState(() => _isSettingsHovered = true),
                            onExit: (_) => setState(() => _isSettingsHovered = false),
                            child: AnimatedOpacity(
                              opacity: _isSettingsHovered ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 300),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Кнопка плейлиста
                                  Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      onTap: () {},
                                      child: Container(
                                        height: 35,
                                        width: 35,
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(56, 56, 59, 1),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Icon(
                                          Icons.featured_play_list_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 15),

                                  // Кнопка перемешивания
                                  Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _shuffle_enabled = !_shuffle_enabled;
                                        });
                                      },
                                      child: Container(
                                        height: 35,
                                        width: 35,
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(56, 56, 59, 1),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Icon(
                                          _shuffle_enabled ? Icons.shuffle : Icons.shuffle_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 15),

                                  // Кнопка настроек
                                  Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      onTap: () {},
                                      child: Container(
                                        height: 35,
                                        width: 35,
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(56, 56, 59, 1),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Icon(
                                          Icons.settings,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 15),

                                  // Кнопка повтора
                                  Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      onTap: () {},
                                      child: Container(
                                        height: 35,
                                        width: 35,
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(56, 56, 59, 1),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Icon(
                                          Icons.repeat_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 15),

                                  // Кнопка меню
                                  Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      onTap: () {},
                                      child: Container(
                                        height: 35,
                                        width: 35,
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(56, 56, 59, 1),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Icon(
                                          Icons.menu,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
