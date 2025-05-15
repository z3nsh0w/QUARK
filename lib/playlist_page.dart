import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:audiotags/audiotags.dart';


class PlaylistPage extends StatefulWidget {
  final List<String> songs;
  const PlaylistPage({super.key, required this.songs});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  // var songs = widget.songs;
  List<String> songs = [];
  List<String> shuffledPlaylist = [];

  String currentPosition = '0:00';
  String songDurationWidget = '0:00';
  String _trackName = '';

  double songProgress = 0.0;
  double _volumeValue = 0.7;

  int nowPlayingIndex = 0;
  Uint8List imageData = Uint8List.fromList([]);

  bool isRepeatEnable = false;
  bool isSliderActive = true;
  bool _isPlaying = false;
  bool isShuffleEnable = false;
  final player = AudioPlayer();
  final _controller = InteractiveSliderController(0.0);

  // String _trackArtist = '';
  // String _album = '';
  // String _albumArtist = '';
  // int _trackNumber = 0;
  // int _albumLength = 0;
  // int _year = 0;
  // String _genre = '';
  // String _authorName = '';
  // String _writerName = '';
  // int _discNumber = 0;
  // String _mimeType = '';
  // int _trackDuration = 0;
  // int _bitrate = 0;
  List<String>? trackArtistNames = [];

  Future<Map<String, dynamic>> loadTag() async {
    try {
      // final metadata = await MetadataRetriever.fromFile(
      //   File(songs[nowPlayingIndex]),
      // );

      Tag? tag = await AudioTags.read(songs[nowPlayingIndex]);

      // String? trackName = tag?.title;
      // String trackName = tag?.title?.trim() ?? songs[nowPlayingIndex].split(r'\').last;
      // String? artist = tag?.trackArtist;
      // List<String> trackArtistNames = artist != null ? [artist] : [];
      // String? albumName = tag?.album;
      // String? albumArtistName = tag?.albumArtist;
      // int? trackNumber = tag?.trackNumber;
      // int? albumLength = tag?.trackTotal;
      // int? year = tag?.year;
      // String? genre = tag?.genre;
      // int? discNumber = tag?.discNumber;

      
      String trackName = tag?.title?.trim() ?? songs[nowPlayingIndex].split(r'\').last;
      String artist = tag?.trackArtist ?? 'Unknown';
      List<String> trackArtistNames = tag?.trackArtist?.trim().isNotEmpty == true
          ? tag!.trackArtist!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : ['Unknown'];
      String albumName = tag?.album?.trim() ?? 'Unknown';
      String albumArtistName = tag?.albumArtist?.trim() ?? 'Unknown';
      int trackNumber = tag?.trackNumber ?? 0;
      int albumLength = tag?.trackTotal ?? 0;
      int year = tag?.year ?? 0;
      String genre = tag?.genre?.trim() ?? 'Unknown';
      int? discNumber = tag?.discNumber;
      Uint8List albumArt = tag?.pictures?.firstOrNull?.bytes ?? Uint8List(0);

      // String? authorName = metadata.authorName;
      // String? writerName = metadata.writerName;
      // String? mimeType = metadata.mimeType;
      // int? trackDuration = metadata.trackDuration;
      // int? bitrate = metadata.bitrate;      
      // Uint8List? albumArtWork = metadata.albumArt;

      String? authorName = 'metadata.authorName';
      String? writerName = 'metadata.writerName';
      String? mimeType = 'metadata.mimeType';
      int? trackDuration = 0;
      int? bitrate = 0;
      // final List<Picture>? pictures = tag?.pictures;
      // Uint8List? albumArt = pictures?.first.bytes;

      // trackName ??= 'Unknown';
      // trackArtistNames ??= ['Unknown'];
      // albumName ??= 'Unknown';
      // albumArtistName ??= 'Unknown';
      // genre ??= 'Unknown';
      // authorName ??= 'Unknown';
      // writerName ??= 'Unknown';
      // discNumber ??= 0;
      // mimeType ??= 'Unknown';
      // trackDuration ??= 0;
      // bitrate ??= 0;
      // albumArt ??= Uint8List.fromList([]);

      Uint8List albumArt2 = Uint8List(0); // Пустой Uint8List по умолчанию
      if (tag?.pictures != null && tag!.pictures!.isNotEmpty) {
        albumArt2 = tag.pictures!.first.bytes 
        ?? Uint8List(0);
      }


      Map<String, dynamic> allTags = {
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
        'albumArt': albumArt2,
      };

      return allTags;
    } catch (e) {
      return {};
    }
  }

  Future<void> steps({
    bool next_step = false,
    bool previous_step = false,
    bool stop_steps = false,
  }) async {
    if (next_step) {
      setState(() {
        nowPlayingIndex++;
        if (nowPlayingIndex >= songs.length) {
          nowPlayingIndex = 0;
        }
        player.stop();
        if (_isPlaying) {
          player.play(DeviceFileSource(songs[nowPlayingIndex]));
        }
      });

      Map<String, dynamic> a = await loadTag();

      setState(() {
          _trackName = (a['trackName']?.toString().trim().isNotEmpty ?? false)
            ? a['trackName'].toString()
            : songs[nowPlayingIndex].split(r'\').last;

          trackArtistNames = (a['trackArtistNames'] is List && a['trackArtistNames'].isNotEmpty)
            ? List<String>.from(a['trackArtistNames'].where((artist) => artist?.toString().trim().isNotEmpty ?? false))
            : ['Unknown'];

          imageData = (a['albumArt'] is Uint8List) ? a['albumArt'] : Uint8List(0);
      });
    }

    if (previous_step) {
      setState(() {
        nowPlayingIndex--;
        if (nowPlayingIndex < 0) {
          nowPlayingIndex = songs.length - 1;
        }
      });
      player.stop();
      if (_isPlaying) {
        player.play(DeviceFileSource(songs[nowPlayingIndex]));
      }

      Map<String, dynamic> a = await loadTag();

      setState(() {
          _trackName = (a['trackName']?.toString().trim().isNotEmpty ?? false)
            ? a['trackName'].toString()
            : songs[nowPlayingIndex].split(r'\').last;

          trackArtistNames = (a['trackArtistNames'] is List && a['trackArtistNames'].isNotEmpty)
            ? List<String>.from(a['trackArtistNames'].where((artist) => artist?.toString().trim().isNotEmpty ?? false))
            : ['Unknown'];

          imageData = (a['albumArt'] is Uint8List) ? a['albumArt'] : Uint8List(0);
      });
    }

    if (stop_steps) {
      setState(() {
        _isPlaying = !_isPlaying;

        if (!_isPlaying) {
          player.pause();
        } else {
          player.play(DeviceFileSource(songs[nowPlayingIndex]));
        }
      });
    }
  }

  Future<void> createNewShuffledPlaylist(
    {
    bool turnOnShuffle = false,
    bool turnOffShuffle = false
    }
  ) async {
    if (turnOnShuffle == true) {
      print('SHUFFLE ENABLE');
      var songList = widget.songs;

      shuffledPlaylist = [];
      songs = [];
      songs = List.from(songList)..shuffle();

      print(songs);

    } else if (turnOffShuffle == true) {
      print('SHUFFLE ENABLE');

      songs = [];
      var songList = widget.songs;
      for (int i = 0; i < songList.length; i++) {
        songs.add(songList[i]);
      }
      print(songs);

    }
  }

  void _setupPlayerListeners() {
    player.onPlayerComplete.listen((_) async {
        await steps(next_step: true);
    });
  }

  void progressState() {
    player.onPositionChanged.listen((position) async {
      final duration = await player.getDuration();
      String _duration = '';
      var current_pos = 0.0;

      if (duration != null) {
        var time_inminutes = duration.inSeconds ~/ 60;
        var time_inseconds = duration.inSeconds % 60;

        _duration += '$time_inminutes:';

        if (time_inseconds < 10) {
          _duration += '0$time_inseconds';
        } else {
          _duration += '$time_inseconds';
        }

        current_pos = position.inMicroseconds / duration.inMicroseconds * 100.0;
        if (current_pos > 100.0) {
          current_pos = 100.0;
        }
      }

      var time_inminutes = position.inSeconds ~/ 60;
      var time_inseconds = position.inSeconds % 60;

      String timing = '';

      timing += '$time_inminutes:';

      if (time_inseconds < 10) {
        timing += '0$time_inseconds';
      } else {
        timing += '$time_inseconds';
      }

      setState(() {
        currentPosition = timing;
        songDurationWidget = _duration;
        songProgress = current_pos;

        if (isSliderActive) _controller.value = current_pos / 100;
      });
    });
  }

  Future<int> getSecondsByValue(double value) async {
    final duration = await player.getDuration();
    if (duration != null) {
      return ((value / 100.0) * duration.inSeconds).round();
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _setupPlayerListeners();
    progressState();

    var songList = widget.songs;
    for (int i = 0; i < songList.length; i++) {
      songs.add(songList[i]);
    }

    loadTag().then((value) {
      setState(() {
        print(value['trackName']);
        if (value['trackName'] == '') {
          _trackName = songs[nowPlayingIndex].split(r'\').last;
        } else {
          _trackName = value['trackName'];
        }

        if (value['trackArtistNames'][0] == "") {
          trackArtistNames = ['Unknown'];
        } else {
          trackArtistNames = value['trackArtistNames'];
        }
        imageData = value['albumArt'];
      });
    });
  }

  @override
  void dispose() {
    player.dispose();
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
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
            ),
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(24, 24, 26, 1),
                Color.fromRGBO(18, 18, 20, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),

          child: ClipRect(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 750),
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
                        height: 250,
                        width: 250,
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

                      SizedBox(
                        width: 500,

                        child: Text(
                          _trackName.split(r'\').last,
                          textAlign: TextAlign.center,
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentPosition,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                            ),
                          ),

                          SizedBox(
                            width: 325,

                            child: InteractiveSlider(
                              controller: _controller,
                              unfocusedHeight: 5,
                              focusedHeight: 10,
                              min: 0.0,
                              max: 100.0,
                              onProgressUpdated: (value) async {
                                isSliderActive = true;
                                try {
                                  final seconds = await getSecondsByValue(
                                    value,
                                  );
                                  await player.seek(Duration(seconds: seconds));
                                } catch (e) {
                                  print('ERR: $e');
                                }
                              },

                              brightness: Brightness.light,
                              initialProgress: songProgress,
                              iconColor: Colors.white,
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.white],
                              ),
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),

                              onFocused: (value) => {isSliderActive = false},
                            ),
                          ),

                          Text(
                            '$songDurationWidget',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),

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
                                await steps(previous_step: true);
                              },

                              child: Container(
                                height: 40,
                                width: 40,

                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 40, 40, 42),

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
                              onTap: () async {
                                await steps(stop_steps: true);
                              },

                              child: Container(
                                height: 50,
                                width: 50,

                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 40, 40, 42),
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

                          // NEXT SONG BUTTON
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),

                            child: InkWell(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              onTap: () async {
                                await steps(next_step: true);
                              },
                              child: Container(
                                height: 40,
                                width: 40,

                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 40, 40, 42),
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

                      // NEXT SONG BUTTON
                      SizedBox(height: 15),

                      SizedBox(
                        width: 325,

                        child: InteractiveSlider(
                          startIcon: const Icon(Icons.volume_down),
                          endIcon: const Icon(Icons.volume_up),
                          min: 0.0,
                          max: 1.0,
                          brightness: Brightness.light,
                          initialProgress: _volumeValue,
                          iconColor: Colors.white,
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.white],
                          ),
                          onChanged:
                              (value) => setState(() {
                                _volumeValue = value;
                                player.setVolume(_volumeValue);
                              }),
                        ),
                      ),

                      SizedBox(height: 20),

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
                              splashColor: Colors.transparent,
                              highlightColor: Color.fromARGB(255, 40, 40, 42),
                              onTap: () {},
                              child: Container(
                                height: 35,
                                width: 35,

                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 40, 40, 42),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.featured_play_list_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 15),

                          // SHUFFLITAS
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),

                            child: InkWell(
                              splashColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              highlightColor: Color.fromARGB(255, 40, 40, 42),

                              onTap: () async {
                                setState(() {
                                  isShuffleEnable = !isShuffleEnable;
                                });
                                
                                if (isShuffleEnable == true) {
                                  await createNewShuffledPlaylist(turnOnShuffle: true);

                                }
                                if (isShuffleEnable == false) {
                                  await createNewShuffledPlaylist(turnOffShuffle: true);

                                }
                              },

                              child: Container(
                                height: 35,
                                width: 35,

                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 40, 40, 42),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(30),
                                  ),
                                ),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: Duration(milliseconds: 120),
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                      layoutBuilder:
                                          (currentChild, previousChildren) =>
                                              Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  ...previousChildren,
                                                  if (currentChild != null)
                                                    currentChild,
                                                ],
                                              ),
                                      child: Icon(
                                        isShuffleEnable
                                            ? Icons.shuffle
                                            : Icons.shuffle_outlined,
                                        key: ValueKey<bool>(isShuffleEnable),
                                        color:
                                            isShuffleEnable
                                                ? Color.fromRGBO(
                                                  255,
                                                  255,
                                                  255,
                                                  1,
                                                )
                                                : Color.fromRGBO(
                                                  255,
                                                  255,
                                                  255,
                                                  0.5,
                                                ),
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // SHUFFLITAS
                          SizedBox(width: 75),

                          // REPEATER BUTTON
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),

                            child: InkWell(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              splashColor: Colors.transparent,
                              highlightColor: Color.fromARGB(255, 40, 40, 42),
                              onTap: () {
                                setState(() {
                                  isRepeatEnable = !isRepeatEnable;
                                });
                              },
                              child: Container(
                                height: 35,
                                width: 35,

                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 40, 40, 42),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(30),
                                  ),
                                ),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: Duration(milliseconds: 120),
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                      layoutBuilder:
                                          (currentChild, previousChildren) =>
                                              Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  ...previousChildren,
                                                  if (currentChild != null)
                                                    currentChild,
                                                ],
                                              ),

                                      child: Icon(
                                        Icons.repeat_outlined,
                                        color:
                                            isRepeatEnable
                                                ? Color.fromRGBO(
                                                  255,
                                                  255,
                                                  255,
                                                  1,
                                                )
                                                : Color.fromRGBO(
                                                  255,
                                                  255,
                                                  255,
                                                  0.500,
                                                ),
                                        size: 20,
                                        key: ValueKey<bool>(isRepeatEnable),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // REPEATER BUTTON
                          SizedBox(width: 15),

                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),

                            child: InkWell(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              splashColor: Colors.transparent,
                              highlightColor: Color.fromARGB(255, 40, 40, 42),
                              onTap: () {
                                setState(() {});
                              },
                              child: Container(
                                height: 35,
                                width: 35,

                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 40, 40, 42),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.menu,
                                      color: Colors.white,
                                      size: 20,
                                    ), // nu i che tut za huina?
                                  ], // nu i che tut za huina?
                                ), // nu i che tut za huina?
                              ), // nu i che tut za huina?
                            ), // nu i che tut za huina?
                          ), // nu i che tut za huina?
                        ], // nu i che tut za huina?
                      ), // nu i che tut za huina?
                    ], // nu i che tut za huina?
                  ), // nu i che tut za huina?
                ), // nu i che tut za huina?
              ), // nu i che tut za huina?
            ), // nu i che tut za huina?
          ), // nu i che tut za huina?
        ), // nu i che tut za huina?
      ), // nu i che tut za huina?
    ); // nu i che tut za huina?
  } // nu i che tut za huina?
}                 // nu i che tut za huina?
                 // nu i che tut za huina?
