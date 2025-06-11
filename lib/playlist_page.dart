import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:audiotags/audiotags.dart';
import 'package:http/http.dart' as http;
import 'package:QUARK/database.dart';
import 'package:dio/dio.dart';

class PlaylistPage extends StatefulWidget {
  final List<String> songs;
  final String lastSong;
  const PlaylistPage({super.key, required this.songs, required this.lastSong});

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
                                            setState(() {
                                              if (nowPlayingIndex != index &&
                                                  index > 0) {
                                                nowPlayingIndex = index - 1;
                                                steps(nextStep: true);
                                              } else if (index == 0) {
                                                nowPlayingIndex = index;
                                                steps(replayStep: true);
                                              }
                                            });
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
                                  onTap: () {
                                    saveRecognizedData(
                                      songs[nowPlayingIndex],
                                      coverArtData,
                                      trackArtistNames.toString(),
                                      trackName,
                                    );

                                    _hideWarningMetadataOverlay();
                                  },
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
                                    trackName = songs[nowPlayingIndex];
                                    trackArtistNames = ['Unknown'];
                                    coverArtData = Uint8List(0);
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
    warningMetadataAnimationController.forward();
  }

  void _hideWarningMetadataOverlay() {
    warningMetadataAnimationController.reverse().then((_) {
      warningMetadataOverlayEntry?.remove();
      warningMetadataOverlayEntry = null;
    });
  }

  void _showSettingsOverlay() {
    settingsOverlayEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _hideSettingsOverlay,
                  child: Container(color: Colors.black.withOpacity(0.05)),
                ),
              ),

              Positioned(
                child: SlideTransition(
                  position: settingsOffsetAnimation,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,

                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(15),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 175, sigmaY: 175),
                          child: Container(
                            width: 464 - 50,
                            height: 815 - 100,
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
                                  width: 464 - 50,
                                  child: Positioned(
                                    top: 25,
                                    // right: -600,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      onPressed: _hideSettingsOverlay,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 40),
                                Text(
                                  '        at the moment this is the debugging menu. need to make user"s settings. penis',
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(height: 40),

                                InkWell(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                  onTap: _hideSettingsOverlay,
                                  child: Container(
                                    height: 40,
                                    width: 300,
                                    color: Color.fromRGBO(77, 77, 77, 0.498),
                                    child: Text(
                                      'Close menu',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 15),

                                InkWell(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                  onTap: () async {
                                    setState(() {
                                      nowPlayingIndex = 0;
                                    });
                                    await steps(stopSteps: true);
                                    await player.stop();
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    height: 40,
                                    width: 300,
                                    color: Color.fromRGBO(77, 77, 77, 0.498),
                                    child: Text(
                                      'Exit playlist',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 15),

                                InkWell(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                  onTap:
                                      () => Database.setValue(
                                        'metadataRecognize',
                                        false,
                                      ).then(
                                        (a) => setState(() {
                                          isMetadataRecognizeEnable = false;
                                        }),
                                      ),
                                  child: Container(
                                    height: 40,
                                    width: 300,
                                    color: Color.fromRGBO(77, 77, 77, 0.498),
                                    child: Text(
                                      'Disable metadataRecognition (will be done)',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                  onTap:
                                      () => Database.setValue(
                                        'metadataRecognize',
                                        true,
                                      ).then(
                                        (a) => setState(() {
                                          isMetadataRecognizeEnable = true;
                                        }),
                                      ),
                                  child: Container(
                                    height: 40,
                                    width: 300,
                                    color: Color.fromRGBO(77, 77, 77, 0.498),
                                    child: Text(
                                      'Enable metadataRecognition (will be done)',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 15),
                                InkWell(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                  onTap: () async {
                                    await steps(stopSteps: true);
                                    await player.stop();
                                    Navigator.pop(context);
                                    Database.clear();
                                  },
                                  child: Container(
                                    height: 40,
                                    width: 300,
                                    color: Color.fromRGBO(77, 77, 77, 0.498),
                                    child: Text(
                                      'Delete database (there will be a button to reset the application settings)',
                                      style: TextStyle(
                                        color: const Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 50),

                                InkWell(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                  onTap:
                                      () => saveRecognizedData(
                                        '42',
                                        Uint8List(0),
                                        '42',
                                        '42',
                                      ),
                                  child: Container(
                                    height: 40,
                                    width: 300,
                                    color: Color.fromRGBO(77, 77, 77, 0.498),
                                    child: Text(
                                      'Save example track to recognizedDatabase (will be deleted)',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                  onTap:
                                      () => Database.getValue(
                                        'recognizedTracks',
                                      ).then((tracks) {
                                        print(tracks);
                                      }),
                                  child: Container(
                                    height: 40,
                                    width: 300,
                                    color: Color.fromRGBO(77, 77, 77, 0.498),
                                    child: Text(
                                      'Get recognizedDatabase (will be deleted)',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                  onTap:
                                      () =>
                                          Database.getDirectory().then((value) {
                                            print(value);
                                          }),
                                  child: Container(
                                    height: 40,
                                    width: 300,
                                    color: Color.fromRGBO(77, 77, 77, 0.498),
                                    child: Text(
                                      'Get database path (maybe it will be done in the about window or something like that)',
                                      style: TextStyle(color: Colors.red),
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
                ),
              ),
            ],
          ),
    );

    Overlay.of(context).insert(settingsOverlayEntry!);
    settingsAnimationController.forward();
  }

  void _hideSettingsOverlay() {
    settingsAnimationController.reverse().then((_) {
      settingsOverlayEntry?.remove();
      settingsOverlayEntry = null;
    });
  }

  late AnimationController warningMetadataAnimationController;
  late Animation<Offset> warningMetadataOffsetAnimation;
  OverlayEntry? warningMetadataOverlayEntry;

  late AnimationController playlistAnimationController;
  late Animation<Offset> playlistOffsetAnimation;
  OverlayEntry? playlistOverlayEntry;

  late AnimationController settingsAnimationController;
  late Animation<Offset> settingsOffsetAnimation;
  OverlayEntry? settingsOverlayEntry;

  // IF WE CAN MAKE SHIT, WE WILL

  List<String> songs = [];
  List<String> shuffledPlaylist = [];

  List<String> fetchedSongs = [];
  CancelToken? _currentToken;
  String currentPosition = '0:00';
  String songDurationWidget = '0:00';
  String trackName = '';

  double songProgress = 0.0;
  double volumeValue = 0.7;

  int nowPlayingIndex = 0;

  Uint8List coverArtData = Uint8List.fromList([]);

  bool isRepeatEnable = false;
  bool isSliderActive = true;
  bool isPlaylistOpened = false;
  bool isPlayling = false;
  bool isShuffleEnable = false;
  bool isMetadataRecognizeEnable = true;

  final player = AudioPlayer();
  final volumeController = InteractiveSliderController(0.0);

  // var buttonsColor =

  final String serverApiURL = '127.0.0.1:5678';

  List<String>? trackArtistNames = [];

  // Loading metadata from nowplaying track
  Future<Map<String, dynamic>> loadTag() async {
    var trackFilename =
        songs[nowPlayingIndex].split(r'\').last.split(r'/').last;
    try {
      Tag? tagsFromFile = await AudioTags.read(songs[nowPlayingIndex]);
      String trackName =
          tagsFromFile?.title?.trim() ??
          songs[nowPlayingIndex].split(r'\').last;
      tagsFromFile?.title?.trim() ?? songs[nowPlayingIndex].split(r'/').last;

      List<String> trackArtistNames =
          tagsFromFile?.trackArtist?.trim().isNotEmpty == true
              ? tagsFromFile!.trackArtist!
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
              : ['Unknown'];
      String albumName = tagsFromFile?.album?.trim() ?? 'Unknown';
      String albumArtistName = tagsFromFile?.albumArtist?.trim() ?? 'Unknown';
      int trackNumber = tagsFromFile?.trackNumber ?? 0;
      int albumLength = tagsFromFile?.trackTotal ?? 0;
      int year = tagsFromFile?.year ?? 0;
      String genre = tagsFromFile?.genre?.trim() ?? 'Unknown';
      int? discNumber = tagsFromFile?.discNumber;

      String? authorName = 'metadata.authorName';
      String? writerName = 'metadata.writerName';
      String? mimeType = 'metadata.mimeType';
      int? trackDuration = 0;
      int? bitrate = 0;

      Uint8List albumArt2 = Uint8List(0);
      if (tagsFromFile?.pictures != null &&
          tagsFromFile!.pictures!.isNotEmpty) {
        albumArt2 = tagsFromFile.pictures!.first.bytes ?? Uint8List(0);
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
        'trackName': trackFilename,
        'trackArtistNames': ['Unknown'],
        'albumArt': Uint8List(0),
      };
    }
  }

  // //

  // Decode JPG to Uing8List
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

  // //

  // Functional programming class for player management
  Future<void> steps({
    bool nextStep = false,
    bool previousStep = false,
    bool stopSteps = false,
    bool replayStep = false,
  }) async {
    _hideWarningMetadataOverlay();
    loadTag();

    if (nextStep) {
      _currentToken?.cancel();
      final token = CancelToken();
      _currentToken = token;

      setState(() {
        nowPlayingIndex++;
        if (nowPlayingIndex >= songs.length) {
          nowPlayingIndex = 0;
        }
      });

      player.stop();
      if (isPlayling) {
        player.play(DeviceFileSource(songs[nowPlayingIndex]));
      } else {
        currentPosition = '0:00';
        songDurationWidget = '0:00';
      }

      Map<String, dynamic> a = await loadTag();

      setState(() {
        trackName =
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

        coverArtData =
            (a['albumArt'] is Uint8List) ? a['albumArt'] : Uint8List(0);
      });

      if (!fetchedSongs.contains(songs[nowPlayingIndex]) &&
          coverArtData.isEmpty &&
          isMetadataRecognizeEnable == true) {
        bool founded = false;

        final onValue = await Database.getValue('recognizedTracks');
        if (onValue != null) {
          for (var i in onValue) {
            final filename1 = i['filename'].split(r'/').last.split(r'\').last;
            final filename2 =
                songs[nowPlayingIndex].split(r'/').last.split(r'\').last;

            if (filename1 == filename2) {
              coverArtData = i['coverArt'];
              trackName = i['trackName'];
              trackArtistNames = [i['artistName'].toString()];
              founded = true;
            }
          }
        }

        if (!founded) {
          try {
            Map metadata = await recognizeMetadata(songs[nowPlayingIndex]);

            if (token.isCancelled) return;

            if (metadata.isNotEmpty) {
              Uint8List coverart = await urlImageToUint8List(
                metadata['coverarturl'],
              );

              if (token.isCancelled) return;

              setState(() {
                coverArtData = coverart;
                trackName = metadata['trackname'];
                trackArtistNames = [metadata['artist']];
              });

              _showWarningMetadataOverlay();
            }
          } catch (e) {
            if (token.isCancelled) {
              return;
            }
            rethrow;
          }
        }
      }

      Database.setValue('lastPlaylistTrack', songs[nowPlayingIndex]);
    }

    if (previousStep) {
      setState(() {
        _currentToken?.cancel();
        nowPlayingIndex--;
        if (nowPlayingIndex < 0) {
          nowPlayingIndex = songs.length - 1;
        }
      });
      player.stop();
      if (isPlayling) {
        player.play(DeviceFileSource(songs[nowPlayingIndex]));
      } else {
        currentPosition = '0:00';
        songDurationWidget = '0:00';
      }

      Map<String, dynamic> a = await loadTag();

      setState(() {
        trackName =
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

        coverArtData =
            (a['albumArt'] is Uint8List) ? a['albumArt'] : Uint8List(0);
      });

      if (!fetchedSongs.contains(songs[nowPlayingIndex]) &&
          coverArtData.isEmpty &&
          isMetadataRecognizeEnable == true) {
        final onValue = await Database.getValue('recognizedTracks');
        if (onValue != null) {
          for (var i in onValue) {
            final filename1 = i['filename'].split(r'/').last.split(r'\').last;
            final filename2 =
                songs[nowPlayingIndex].split(r'/').last.split(r'\').last;

            if (filename1 == filename2) {
              coverArtData = i['coverArt'];
              trackName = i['trackName'];
              trackArtistNames = [i['artistName'].toString()];
            }
          }
        }
      }

      Database.setValue('lastPlaylistTrack', songs[nowPlayingIndex]);
    }

    if (stopSteps) {
      setState(() {
        isPlayling = !isPlayling;

        if (!isPlayling) {
          player.pause();
        } else {
          player.play(DeviceFileSource(songs[nowPlayingIndex]));
          Database.setValue('lastPlaylistTrack', songs[nowPlayingIndex]);
        }
      });
    }

    if (replayStep) {
      _currentToken?.cancel();
      final token = CancelToken();
      _currentToken = token;
      // This function is intended for when we have designated index outside this class and want to reproduce it.
      player.stop();
      if (isPlayling) {
        player.play(DeviceFileSource(songs[nowPlayingIndex]));
      } else {
        currentPosition = '0:00';
        songDurationWidget = '0:00';
      }

      Map<String, dynamic> a = await loadTag();

      setState(() {
        
        trackName =
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

        coverArtData =
            (a['albumArt'] is Uint8List) ? a['albumArt'] : Uint8List(0);
      });

      if (!fetchedSongs.contains(songs[nowPlayingIndex]) &&
          coverArtData.isEmpty &&
          isMetadataRecognizeEnable == true) {
        bool founded = false;

        final onValue = await Database.getValue('recognizedTracks');
        if (onValue != null) {
          for (var i in onValue) {
            final filename1 = i['filename'].split(r'/').last.split(r'\').last;
            final filename2 =
                songs[nowPlayingIndex].split(r'/').last.split(r'\').last;

            if (filename1 == filename2) {
              coverArtData = i['coverArt'];
              trackName = i['trackName'];
              trackArtistNames = [i['artistName'].toString()];
              founded = true;
            }
          }
        }

        if (!founded) {
          try {
            Map metadata = await recognizeMetadata(songs[nowPlayingIndex]);

            if (token.isCancelled) return;

            if (metadata.isNotEmpty) {
              Uint8List coverart = await urlImageToUint8List(
                metadata['coverarturl'],
              );

              if (token.isCancelled) return;

              setState(() {
                coverArtData = coverart;
                trackName = metadata['trackname'];
                trackArtistNames = [metadata['artist']];
              });

              _showWarningMetadataOverlay();
            }
          } catch (e) {
            if (token.isCancelled) {
              return;
            }
            rethrow;
          }
        }
      }


      Database.setValue('lastPlaylistTrack', songs[nowPlayingIndex]);
    }
  }

  // //

  // WORKING WITH SHUFFLE
  Future<void> createNewShuffledPlaylist({
    bool turnOnShuffle = false,
    bool turnOffShuffle = false,
  }) async {
    if (turnOnShuffle == true) {
      Database.setValue('shuffle', true);
      print('SHUFFLE Endbled');
      var songList = widget.songs;

      shuffledPlaylist = [];
      songs = [];
      songs = List.from(songList)..shuffle();

      print(songs);
    } else if (turnOffShuffle == true) {
      Database.setValue('shuffle', false);

      print('SHUFFLE Disabled');

      songs = [];
      var songList = widget.songs;
      for (int i = 0; i < songList.length; i++) {
        songs.add(songList[i]);
      }
      print(songs);
    }
  }

  // //

  // Setup track complete listener
  void _setupPlayerListeners() {
    player.onPlayerComplete.listen((_) async {
      await steps(nextStep: true);
    });
  }

  // //

  // Progressing track playback
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

        if (isSliderActive) volumeController.value = current_pos / 100;
      });
    });
  }

  // //

  // CHANGING VOLUME
  void changeVolume(volume) {
    setState(() {
      volumeValue = volume;
      player.setVolume(volumeValue);
    });
    Database.setValue('volume', volumeValue);
  }

  // //

  // Save recognized data to database
  void saveRecognizedData(filename, coverArtUint8, artistName, trackName) {
    Database.getValue('recognizedTracks').then((recognizedTracksList) {
      List<Map<String, dynamic>> tracksList = [];

      if (recognizedTracksList != null) {
        for (var track in recognizedTracksList) {
          final convertedTrack = track.cast<String, dynamic>();
          tracksList.add(convertedTrack);
        }
      }

      Map<String, dynamic> addToList = {
        'filename': filename,
        'coverArt': coverArtUint8,
        'artistName': artistName,
        'trackName': trackName,
      };

      tracksList.add(addToList);

      Database.setValue('recognizedTracks', tracksList);
    });
  }

  // Get track timing by 0-100 value from timeline slider
  Future<int> getSecondsByValue(double value) async {
    final duration = await player.getDuration();
    if (duration != null) {
      return ((value / 100.0) * duration.inSeconds).round();
    }
    return 0;
  }

  // //

  // Getting all tracks in Map list
  Future<List<Map<String, dynamic>>> getAllTrackWithMetadata() async {
    // eto pizdec...
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

  // //

  // Recognizing metadata from audio using api
  Future<Map<String, dynamic>> recognizeMetadata(String track) async {
    var filename = track.split(r'/').last.split(r'\').last;
    var query = 'FILENAME:$filename'; // Make a request in free format
    try {
      final response = await http.get(
        Uri.parse(
          'http://$serverApiURL/get_metadata?data=$query',
        ), // Make a request in free format
      );

      var jsonResponseFromAPI =
          jsonDecode(response.body) as Map<String, dynamic>;

      var trackname = jsonResponseFromAPI['title'];
      var artist = jsonResponseFromAPI['artists'][0]['name'];
      var coverarturl = jsonResponseFromAPI['cover_art_url'];

      Map<String, dynamic> trackData = {
        'trackname': '$trackname',
        'artist': '$artist',
        'coverarturl': '$coverarturl',
      };
      print(trackData);
      return Future.value(trackData);
    } catch (e) {
      return Future.value({}); // If we don't find anything, we rest.
    }
  }

  // //

  // Handling page loading
  @override
  void initState() {
    super.initState();
    _setupPlayerListeners();
    progressState();
    Database.init();
    if (nowPlayingIndex < 0 || nowPlayingIndex >= songs.length) {
      setState(() {
        nowPlayingIndex = 0;
      });
    }

    // INITIALIZING PLAYLIST, INFO MESSAGE AND SETTINGS .... YOU KNOW

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
    settingsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );

    settingsOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: settingsAnimationController, curve: Curves.ease),
    );

    // //

    var songList = widget.songs;

    for (int i = 0; i < songList.length; i++) {
      // As a crutch, we fill in an alternative playlist variable instead of the main widget.songs variable
      songs.add(songList[i]);
    }

    if (widget.lastSong != '') {
      // Get the last listened track from the previous page
      var lastIndex = songs.indexWhere(
        (path) => path.endsWith(widget.lastSong),
      );

      if (lastIndex != -1) {
        setState(() {
          nowPlayingIndex = lastIndex;
        });
      }
    }

    loadTag().then((tags) {
      // Loading the cover of the active track
      setState(() {
        print(tags['trackName']);
        if (tags['trackName'] == '') {
          trackName = songs[nowPlayingIndex].split(r'\').last;
        } else {
          trackName = tags['trackName'];
        }

        if (tags['trackArtistNames'][0] == "") {
          trackArtistNames = ['Unknown'];
        } else {
          trackArtistNames = tags['trackArtistNames'];
        }
        coverArtData = tags['albumArt'];
      });
    });

    Database.getKeys().then((value) {
      // If the application starts for the first time, we set some standard values
      if (value.isEmpty) {
        Database.setValue('shuffle', false);
        Database.setValue('volume', 0.7);
        Database.setValue('metadataRecognize', true);
      }
    });

    Database.getKeys().then(
      (value) => print(value),
    ); // For debugging, we display all database values

    Database.setValue(
      'lastPlaylist',
      songList,
    ); // After initializing the playlist, we add it to the table as the last one

    Database.getValue('lastPlaylist').then(
      (value) => print(value),
    ); // Getting data from the table and set the values
    Database.getValue('volume').then(
      (volume) => {
        if (volume != null)
          {
            setState(() {
              volumeValue = volume;
              player.setVolume(volume);
            }),
          },
      },
    );
    Database.getValue('metadataRecognize').then((value) {
      if (value != null) {
        setState(() {
          isMetadataRecognizeEnable = value;
        });
      }
      if (value == null) {
        Database.setValue('metadataRecognize', true).then(
          (value) => {
            setState(() {
              isMetadataRecognizeEnable = true;
            }),
          },
        );
      }
    });
  }

  // //

  // brrr

  // Handling exit from player
  @override
  void dispose() {
    player.dispose();
    super.dispose();
    playlistAnimationController.dispose();
    playlistOverlayEntry?.remove();
    warningMetadataAnimationController.dispose();
    warningMetadataOverlayEntry?.remove();
    settingsAnimationController.dispose();
    settingsOverlayEntry?.remove();
  }

  // //
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
                image: MemoryImage(coverArtData),

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
                  key: ValueKey<Uint8List>(coverArtData),

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
                              image: MemoryImage(coverArtData),
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
                            trackName.split(r'\').last,
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
                                controller: volumeController,
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
                                  await steps(previousStep: true);
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
                                  await steps(stopSteps: true);
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
                                        isPlayling
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
                                  await steps(nextStep: true);
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
                            initialProgress: volumeValue,
                            iconColor: Colors.white,
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ),
                            onChanged: (value) => changeVolume(value),
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
                                onTap: () {
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
                                onTap: _showSettingsOverlay,
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
