import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:audiotags/audiotags.dart';
import 'package:http/http.dart' as http;
import 'database.dart' as db;

class PlaylistPage extends StatefulWidget {
  final List<String> songs;
  const PlaylistPage({super.key, required this.songs});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage>
    with TickerProviderStateMixin {
  void _showPlaylistOverlay() {
    if (isPlaylistOpened == false) {
      isPlaylistOpened = true;

      playlistOverlayEntry = OverlayEntry(
        builder:
            (context) => Positioned(
              left: 0,
              child: SlideTransition(
                position: playlistOffsetAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! > 100) {
                        _hidePlaylistOverlay();
                      }
                    },

                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                        child: Container(
                          width: 400,
                          height: MediaQuery.of(context).size.height,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
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
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 50),
                                child: FutureBuilder(
                                  future: getAllTrackWithMetadata(),
                                  builder: (context, snapshot) {
                                    final tracks = snapshot.data ?? [];

                                    return ListView.builder(
                                      itemCount: tracks.length,
                                      itemBuilder: (context, index) {
                                        var name = tracks[index]['trackName'];
                                        var artist =
                                            tracks[index]['trackArtistNames'][0];
                                        return ListTile(
                                          title: Row(
                                            children: [
                                              Container(
                                                height: 55,
                                                width: 55,
                                                decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                    image: MemoryImage(
                                                      tracks[index]['albumArt'],
                                                    ),
                                                    fit: BoxFit.cover,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                          Colors.black
                                                              .withOpacity(0),
                                                          BlendMode.darken,
                                                        ),
                                                  ),

                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          const Color.fromARGB(
                                                            255,
                                                            21,
                                                            21,
                                                            21,
                                                          ),
                                                      blurRadius: 10,
                                                      offset: Offset(5, 10),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              SizedBox(width: 10),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '$name',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Text(
                                                      '$artist',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            getAllTrackWithMetadata();
                                            setState(
                                              () => nowPlayingIndex = index - 1,
                                            );
                                            steps(next_step: true);
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              Positioned(
                                top: 10,
                                right: 10,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  onPressed: _hidePlaylistOverlay,
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
      );

      Overlay.of(context).insert(playlistOverlayEntry!);
      playlistAnimationController.forward();
    }
  }

  void _hidePlaylistOverlay() {
    if (isPlaylistOpened == true) {
      isPlaylistOpened = false;
      playlistAnimationController.reverse().then((_) {
        playlistOverlayEntry?.remove();
        playlistOverlayEntry = null;
      });
    }
  }

  void _showWarningMetadataOverlay() {
    warningMetadataOverlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            right: 15,
            top: 15,
            child: SlideTransition(
              position: warningMetadataOffsetAnimation,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 100) {
                      _hideWarningMetadataOverlay();
                    }
                  },

                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                      child: Container(
                        width: 350,
                        height: 100,
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
                            Container(
                              child: Text(
                                'Is that correct metadata?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              padding: EdgeInsets.only(left: 15, top: 15),
                            ),
                            SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: _hideWarningMetadataOverlay,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.done, color: Colors.green),
                                      Text(
                                        'Accept',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 30),
                                InkWell(
                                  onTap: () {
                                    _hideWarningMetadataOverlay();
                                    _trackName = songs[nowPlayingIndex];
                                    trackArtistNames = ['Unknown'];
                                    imageData = Uint8List(0);
                                  },
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.close,
                                        color: const Color.fromARGB(
                                          172,
                                          146,
                                          43,
                                          36,
                                        ),
                                      ),
                                      Text(
                                        'Decline',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
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
          ),
    );

    Overlay.of(context).insert(warningMetadataOverlayEntry!);
    warningMetadataAnimationController.forward(); // Запускаем анимацию
  }

  void _hideWarningMetadataOverlay() {
    warningMetadataAnimationController.reverse().then((_) {
      warningMetadataOverlayEntry?.remove();
      warningMetadataOverlayEntry = null;
    });
  }

  late AnimationController warningMetadataAnimationController;
  late Animation<Offset> warningMetadataOffsetAnimation;
  OverlayEntry? warningMetadataOverlayEntry;

  late AnimationController playlistAnimationController;
  late Animation<Offset> playlistOffsetAnimation;
  OverlayEntry? playlistOverlayEntry;

  // IF WE CAN MAKE SHIT, WE WILL

  List<String> songs = [];
  List<String> shuffledPlaylist = [];

  List<String> fetched_songs = [];

  String currentPosition = '0:00';
  String songDurationWidget = '0:00';
  String _trackName = '';

  double songProgress = 0.0;
  double _volumeValue = 0.7;

  int nowPlayingIndex = 0;
  Uint8List imageData = Uint8List.fromList([]);

  bool isRepeatEnable = false;
  bool isSliderActive = true;
  bool isPlaylistOpened = false;
  bool _isPlaying = false;
  bool isShuffleEnable = false;
  final player = AudioPlayer();
  final _controller = InteractiveSliderController(0.0);

  final String serverApiURL = '127.0.0.1:5678';

  List<String>? trackArtistNames = [];

  // LOADING METADATA FROM AUDIOFILE

  Future<Map<String, dynamic>> loadTag() async {
    var trackName = songs[nowPlayingIndex].split(r'\').last.split(r'/').last;
    try {
      Tag? tag = await AudioTags.read(songs[nowPlayingIndex]);
      String trackName =
          tag?.title?.trim() ?? songs[nowPlayingIndex].split(r'\').last;
      tag?.title?.trim() ?? songs[nowPlayingIndex].split(r'/').last;

      List<String> trackArtistNames =
          tag?.trackArtist?.trim().isNotEmpty == true
              ? tag!.trackArtist!
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
              : ['Unknown'];
      String albumName = tag?.album?.trim() ?? 'Unknown';
      String albumArtistName = tag?.albumArtist?.trim() ?? 'Unknown';
      int trackNumber = tag?.trackNumber ?? 0;
      int albumLength = tag?.trackTotal ?? 0;
      int year = tag?.year ?? 0;
      String genre = tag?.genre?.trim() ?? 'Unknown';
      int? discNumber = tag?.discNumber;

      String? authorName = 'metadata.authorName';
      String? writerName = 'metadata.writerName';
      String? mimeType = 'metadata.mimeType';
      int? trackDuration = 0;
      int? bitrate = 0;

      Uint8List albumArt2 = Uint8List(0);
      if (tag?.pictures != null && tag!.pictures!.isNotEmpty) {
        albumArt2 = tag.pictures!.first.bytes ?? Uint8List(0);
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
      return {
        'trackName': trackName,
        'trackArtistNames': ['Unknown'],
        'albumArt': Uint8List(0),
      };
    }
  }

  Future<Uint8List> urlImageToUint8List(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      return Uint8List(0);
    }
  }
  // // LOADING METADATA FROM AUDIOFILE

  // Functional programming rules! Handling next, play, previous buttons

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
      });
      player.stop();
      if (_isPlaying) {
        player.play(DeviceFileSource(songs[nowPlayingIndex]));
      } else {
        currentPosition = '0:00';
        songDurationWidget = '0:00';
      }

      Map<String, dynamic> a = await loadTag();

      setState(() {
        _trackName =
            (a['trackName']?.toString().trim().isNotEmpty ?? false)
                ? a['trackName'].toString()
                : songs[nowPlayingIndex].split(r'\').last;

        trackArtistNames =
            (a['trackArtistNames'] is List && a['trackArtistNames'].isNotEmpty)
                ? List<String>.from(
                  a['trackArtistNames'].where(
                    (artist) => artist?.toString().trim().isNotEmpty ?? false,
                  ),
                )
                : ['Unknown'];

        imageData = (a['albumArt'] is Uint8List) ? a['albumArt'] : Uint8List(0);
      });

      if (!fetched_songs.contains(songs[nowPlayingIndex])) {
        Map metadata = await recognizeMetadata(songs[nowPlayingIndex]);
        print(metadata);
        if (metadata.isNotEmpty) {
          Uint8List coverart = await urlImageToUint8List(
            metadata['coverarturl'],
          );
          // var coverart = metadata['coverarturl'];
          imageData = coverart;
          _trackName = metadata['trackname'];
          trackArtistNames = [metadata['artist']];
          _showWarningMetadataOverlay();
        }
      }
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
      } else {
        currentPosition = '0:00';
        songDurationWidget = '0:00';
      }

      Map<String, dynamic> a = await loadTag();

      setState(() {
        _trackName =
            (a['trackName']?.toString().trim().isNotEmpty ?? false)
                ? a['trackName'].toString()
                : songs[nowPlayingIndex].split(r'\').last;

        trackArtistNames =
            (a['trackArtistNames'] is List && a['trackArtistNames'].isNotEmpty)
                ? List<String>.from(
                  a['trackArtistNames'].where(
                    (artist) => artist?.toString().trim().isNotEmpty ?? false,
                  ),
                )
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

  // //

  // WORKING WITH SHUFFLE

  Future<void> createNewShuffledPlaylist({
    bool turnOnShuffle = false,
    bool turnOffShuffle = false,
  }) async {
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

  // //

  void _setupPlayerListeners() {
    player.onPlayerComplete.listen((_) async {
      await steps(next_step: true);
    });
  }

  // PROCESSING TRACK PLAYBACK

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

  // //

  Future<int> getSecondsByValue(double value) async {
    final duration = await player.getDuration();
    if (duration != null) {
      return ((value / 100.0) * duration.inSeconds).round();
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getAllTrackWithMetadata() async {
    List<Map<String, dynamic>> result = [];
    for (var song in songs) {
      var trackName = song.split(r'/').last.split(r'\').last;
      try {
        Tag? tag = await AudioTags.read(song);
        String trackName =
            tag?.title?.trim() ?? song.split(r'/').last.split(r'\').last;

        List<String> trackArtistNames =
            tag?.trackArtist?.trim().isNotEmpty == true
                ? tag!.trackArtist!
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList()
                : ['Unknown'];
        String albumName = tag?.album?.trim() ?? 'Unknown';
        String albumArtistName = tag?.albumArtist?.trim() ?? 'Unknown';
        int trackNumber = tag?.trackNumber ?? 0;
        int albumLength = tag?.trackTotal ?? 0;
        int year = tag?.year ?? 0;
        String genre = tag?.genre?.trim() ?? 'Unknown';
        int? discNumber = tag?.discNumber;

        String? authorName = 'metadata.authorName';
        String? writerName = 'metadata.writerName';
        String? mimeType = 'metadata.mimeType';
        int? trackDuration = 0;
        int? bitrate = 0;

        Uint8List albumArt2 = Uint8List(0);
        if (tag?.pictures != null && tag!.pictures!.isNotEmpty) {
          albumArt2 = tag.pictures!.first.bytes ?? Uint8List(0);
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

        trackName =
            (allTags['trackName']?.toString().trim().isNotEmpty ?? false)
                ? allTags['trackName'].toString()
                : song.split(r'\').last.split(r'/').last;

        trackArtistNames =
            (allTags['trackArtistNames'] is List &&
                    allTags['trackArtistNames'].isNotEmpty)
                ? List<String>.from(
                  allTags['trackArtistNames'].where(
                    (artist) => artist?.toString().trim().isNotEmpty ?? false,
                  ),
                )
                : ['Unknown'];

        albumArt2 =
            (allTags['albumArt'] is Uint8List)
                ? allTags['albumArt']
                : Uint8List(0);

        Map<String, dynamic> filetag = {
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

        result.add(filetag);
      } catch (e) {
        result.add({
          'trackName': trackName,
          'trackArtistNames': ['Unknown'],
          'albumArt': Uint8List(0),
        });
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> recognizeMetadata(String track) async {
    var filename = track.split(r'/').last.split(r'\').last;
    var query = 'FILENAME:$filename';
    try {
      final response = await http.get(
        Uri.parse('http://$serverApiURL/get_metadata?data=$query'),
      );

      var rsp = jsonDecode(response.body) as Map<String, dynamic>;

      var trackname = rsp['title'];
      var artist = rsp['artists'][0]['name'];
      var coverarturl = rsp['cover_art_url'];

      Map<String, dynamic> output = {
        'trackname': '$trackname',
        'artist': '$artist',
        'coverarturl': '$coverarturl',
      };
      print(output);
      return Future.value(output);
    } catch (e) {
      return Future.value({});
    }
  }

  // HANDLING PAGE LOADING

  @override
  void initState() {
    super.initState();
    _setupPlayerListeners();
    progressState();

    warningMetadataAnimationController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    warningMetadataOffsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: warningMetadataAnimationController,
        curve: Curves.ease,
      ),
    );

    playlistAnimationController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    playlistOffsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: playlistAnimationController, curve: Curves.ease),
    );

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

  // //

  // brrr

  @override
  void dispose() {
    player.dispose();
    super.dispose();
    playlistAnimationController.dispose();
    playlistOverlayEntry?.remove();
    warningMetadataAnimationController.dispose();
    warningMetadataOverlayEntry?.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Row(
        children: [
          Container(
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
                                    await player.seek(
                                      Duration(seconds: seconds),
                                    );
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
                            // PREVIOUS BUTTON
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),

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
                                    color: const Color.fromARGB(
                                      255,
                                      40,
                                      40,
                                      42,
                                    ),

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

                            // // PREVIOUS BUTTON
                            SizedBox(width: 15),

                            // PLAY BUTTON
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),

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
                                    color: const Color.fromARGB(
                                      255,
                                      40,
                                      40,
                                      42,
                                    ),
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

                            // // PLAY BUTTON
                            SizedBox(width: 15),

                            // NEXT SONG BUTTON
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),

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
                                    color: const Color.fromARGB(
                                      255,
                                      40,
                                      40,
                                      42,
                                    ),
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

                        // // NEXT SONG BUTTON
                        SizedBox(height: 15),

                        // VOLUME SLIDER
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

                        // // VOLUME SLIDER
                        SizedBox(height: 20),

                        // BUTTONS ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // PLAYLIST BUTTON
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),

                              child: InkWell(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                splashColor: Colors.transparent,
                                highlightColor: Color.fromARGB(255, 40, 40, 42),
                                onTap:
                                    isPlaylistOpened
                                        ? _hidePlaylistOverlay
                                        : _showPlaylistOverlay,
                                child: Container(
                                  height: 35,
                                  width: 35,

                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      40,
                                      40,
                                      42,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(30),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.featured_play_list_outlined,
                                        color:
                                            isPlaylistOpened
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
                                        key: ValueKey<bool>(isPlaylistOpened),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // //PLAYLIST BUTTON
                            SizedBox(width: 15),

                            // SHUFFLITAS
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),

                              child: InkWell(
                                splashColor: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                highlightColor: Color.fromARGB(255, 40, 40, 42),

                                onTap: () async {
                                  setState(() {
                                    isShuffleEnable = !isShuffleEnable;
                                  });

                                  if (isShuffleEnable == true) {
                                    await createNewShuffledPlaylist(
                                      turnOnShuffle: true,
                                    );
                                  }
                                  if (isShuffleEnable == false) {
                                    await createNewShuffledPlaylist(
                                      turnOffShuffle: true,
                                    );
                                  }
                                  _hidePlaylistOverlay();
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

                            // // SHUFFLITAS
                            SizedBox(width: 75),

                            // REPEATER BUTTON
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),

                              child: InkWell(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                splashColor: Colors.transparent,
                                highlightColor: Color.fromARGB(255, 40, 40, 42),
                                onTap: () async {
                                  await db.saveVariables([
                                    {'42': 42},
                                  ]);
                                  // print(db.getVariable('42'));
                                  db.getVariable('42').then((value) {
                                    print(
                                      value,
                                    ); // Напечатает значение, когда оно будет доступно
                                  });
                                  setState(() {
                                    isRepeatEnable = !isRepeatEnable;
                                  });
                                },
                                child: Container(
                                  height: 35,
                                  width: 35,

                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      40,
                                      40,
                                      42,
                                    ),
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

                            // // REPEATER BUTTON
                            SizedBox(width: 15),

                            // MENU BUTTON
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),

                              child: InkWell(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                splashColor: Colors.transparent,
                                highlightColor: Color.fromARGB(255, 40, 40, 42),
                                onTap: () async {
                                  await steps(stop_steps: true);
                                  await player.stop();
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  height: 35,
                                  width: 35,

                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      40,
                                      40,
                                      42,
                                    ),
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

                            // // MENU BUTTON
                          ],
                        ),
                        // // BUTTONS ROW
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
