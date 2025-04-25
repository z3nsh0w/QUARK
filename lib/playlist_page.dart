import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

class PlaylistPage extends StatefulWidget {
  final List<String> songs;
  const PlaylistPage({super.key, required this.songs});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  String _current_position = '0:00';
  String _song_duration_widget = '0:00';
  String _trackName = '';

  double _song_progress = 0.0;
  double _volumeValue = 0.7;

  int nowPlayingIndex = 0;
  Uint8List imageData = Uint8List.fromList([]);

  bool _is_slider_active = true;
  bool _isPlaying = false;
  bool _shuffle_enabled = false;
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

      trackName ??= 'Unknown';
      trackArtistNames ??= ['Unknown'];
      albumName ??= 'Unknown';
      albumArtistName ??= 'Unknown';
      genre ??= 'Unknown';
      authorName ??= 'Unknown';
      writerName ??= 'Unknown';
      discNumber ??= 0;
      mimeType ??= 'Unknown';
      trackDuration ??= 0;
      bitrate ??= 0;
      albumArt ??= Uint8List.fromList([]);

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
        await player.play(DeviceFileSource(widget.songs[nowPlayingIndex]));
      }

      Map<String, dynamic> a = await _loadTag_using_dart_tags();
      setState(() {
        _trackName =
            a['trackName']?.isEmpty ?? true
                ? widget.songs[nowPlayingIndex].split(r'\').last
                : a['trackName'];

        trackArtistNames =
            a['trackArtistNames'][0]?.isEmpty ?? true
                ? ['Unknown']
                : a['trackArtistNames'];
        imageData = a['albumArt'];
      });
    });
  }

  void _progress_state() {
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
        _current_position = timing;
        _song_duration_widget = _duration;
        _song_progress = current_pos;

        if (_is_slider_active) _controller.value = current_pos / 100;
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
    _progress_state();

    _loadTag_using_dart_tags().then((value) {
      setState(() {
        print(value['trackName']);
        if (value['trackName'] == '') {
          _trackName = widget.songs[nowPlayingIndex].split(r'\').last;
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
            child: BackdropFilter(
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
                          _current_position,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                          ),
                        ),

                        SizedBox(
                          width: 325,

                          child: InteractiveSlider(
                            controller: _controller,

                            min: 0.0,
                            max: 100.0,
                            onProgressUpdated: (value) async {
                              _is_slider_active = true;
                              try {
                                final seconds = await getSecondsByValue(value);
                                await player.seek(Duration(seconds: seconds));
                              } catch (e) {
                                print('ERR: $e');
                              }
                            },

                            brightness: Brightness.light,
                            initialProgress: _song_progress,
                            iconColor: Colors.white,
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ),
                            shapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),

                            onFocused: (value) => {_is_slider_active = false},
                          ),
                        ),

                        Text(
                          '$_song_duration_widget',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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
                                          .split(r'\')
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
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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
                                color: const Color.fromARGB(255, 40, 40, 42),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
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
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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
                                          .split(r'\')
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
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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

                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.all(Radius.circular(20)),

                          child: InkWell(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            onTap: () {
                              setState(() {
                                _shuffle_enabled = !_shuffle_enabled;
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
                                  Icon(
                                    _shuffle_enabled
                                        ? Icons.shuffle
                                        : Icons.shuffle_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 75),

                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.all(Radius.circular(20)),

                          child: InkWell(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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
                                    Icons.repeat_outlined,
                                    color: Colors.white,
                                    size: 20,
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
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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
                                  ),
                                ],
                              ),
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
    );
  }
}
