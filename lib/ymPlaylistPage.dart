import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:http/http.dart' as http;
import 'package:quark/yMusic.dart';
// import 'package:smtc_windows/smtc_windows.dart';
import 'package:quark/database.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

// some classes

class PathManager {
  static String getFileName(String filePath) {
    return path.basename(path.normalize(filePath));
  }

  static Future<bool> checkfileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  static String getnormalizePath(String filePath) {
    return path.normalize(filePath);
  }
}

class FileTags {
  static Future<Map<String, dynamic>> getTagsFromFile(String filePath) async {
    try {
      final track = File(filePath);

      final tagsFromFile = readMetadata(track, getImage: true);

      if (tagsFromFile == null) {
        return {
          'trackName': PathManager.getFileName(filePath),
          'trackArtistNames': ['Unknown'],
          'albumArt': Uint8List(0),
        };
      }

      return {
        'trackName':
            tagsFromFile?.title?.trim() ?? PathManager.getFileName(filePath),
        'trackArtistNames':
            tagsFromFile?.artist?.trim().isNotEmpty == true
                ? tagsFromFile!.artist!
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList()
                : ['Unknown'],
        'albumName': tagsFromFile.album?.trim() ?? 'Unknown',
        'albumArtistName': tagsFromFile.album?.trim() ?? 'Unknown',
        'trackNumber': tagsFromFile.trackNumber ?? 0,
        'albumLength': tagsFromFile.trackTotal ?? 0,
        'year': tagsFromFile.year ?? 0,
        'genre': tagsFromFile.genres ?? 'Unknown',
        'discNumber': tagsFromFile.discNumber,
        'authorName': 'metadata.authorName',
        'writerName': 'metadata.writerName',
        'mimeType': 'metadata.mimeType',
        'trackDuration': 0,
        'bitrate': 0,
        'albumArt':
            tagsFromFile.pictures.isNotEmpty
                ? tagsFromFile.pictures.first.bytes ?? Uint8List(0)
                : Uint8List(0),
        'albumArtPNG': tagsFromFile.pictures.first.pictureType,
      };
    } catch (e) {
      return {
        'trackName': PathManager.getFileName(filePath),
        'trackArtistNames': ['Unknown'],
        'albumArt': Uint8List(0),
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getAllTracksMetadata(
    List<String> filePaths,
  ) async {
    final List<Map<String, dynamic>> results = [];
    for (final file in filePaths) {
      final tags = await getTagsFromFile(PathManager.getnormalizePath(file));
      results.add(tags);
    }
    return results;
  }
}

class RecognizerService {
  static void saveRecognizedData(
    filename,
    coverArtUint8,
    artistName,
    trackName,
  ) {
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

  static Future<Map<String, dynamic>> recognizeMetadata(
    String track,
    String apiURL,
  ) async {
    var filename = PathManager.getFileName(track);
    var query = 'FILENAME:$filename'; // Make a request in free format
    try {
      final response = await http.get(
        Uri.parse(
          'http://$apiURL/get_metadata?data=$query',
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
      return Future.value(trackData);
    } catch (e) {
      return Future.value({}); // If we don't find anything, we rest.
    }
  }

  static Future<Uint8List> urlImageToUint8List(String imageUrl) async {
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
}

class ymPlaylistPage extends StatefulWidget {
  final List<String> songs;
  final List ymTracksInfo;
  final String ymToken;
  final String ymUid;
  const ymPlaylistPage({
    super.key,
    required this.songs,
    required this.ymTracksInfo,
    required this.ymToken,
    required this.ymUid,
  });

  @override
  State<ymPlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<ymPlaylistPage>
    with TickerProviderStateMixin {
  void _showPlaylistOverlay() {
    if (isPlaylistAnimating) {
      playerPadding = 0.0;

      return;
    }
    if (isPlaylistOpened) {
      playlistAnimationController.reverse().then((_) {
        playlistOverlayEntry?.remove();
        playlistOverlayEntry = null;
      });
      if (mounted) {
        setState(() {
          playerPadding = 0.0;

          isPlaylistOpened = false;
        });
      }
      return;
    }

    if (isPlaylistOpened == false) {
      if (mounted) {
        setState(() {
          isPlaylistOpened = true;
          if (MediaQuery.of(context).size.width > 800) {
            playerPadding = 400.0;
          }
        });
      }

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
                      if (details.primaryVelocity!.abs() > 500) {
                        if (details.primaryVelocity! < -500 ||
                            details.primaryVelocity! > 500) {
                          _hidePlaylistOverlay();
                        }
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
                                  future: FileTags.getAllTracksMetadata(
                                    widget.songs,
                                  ),
                                  builder: (context, snapshot) {
                                    final tracks = snapshot.data ?? [];

                                    return ListView.builder(
                                      itemCount: tracks.length,
                                      itemBuilder: (context, index) {
                                        String trackID =
                                            PathManager.getFileName(
                                              widget.songs[index],
                                            ).replaceAll(
                                              RegExp(
                                                r'^quarkaudiotemptrack|\.mp3$',
                                              ),
                                              '',
                                            );

                                        Map? foundMap = widget.ymTracksInfo
                                            .firstWhere(
                                              (map) => map['id'] == trackID,
                                              orElse: () => null,
                                            );

                                        var name = 'Unknown';
                                        var artist = 'Unknown';
                                        var nowTrack = widget.songs[index];
                                        var image1 =
                                            'https://d1csarkz8obe9u.cloudfront.net/posterpreviews/unknown-cd-album-mixtape-cover-design-templat-template-a0089f026a71f9722a55157364f22590_screen.jpg?ts=1644153606';

                                        if (foundMap != null) {
                                          name = foundMap['title'];
                                          artist = foundMap['artists'];
                                          nowTrack = widget.songs[index];
                                          image1 =
                                              'https://${foundMap['cover']}';
                                        }

                                        return ListTile(
                                          title: Row(
                                            children: [
                                              Container(
                                                height: 55,
                                                width: 55,
                                                decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                    image: NetworkImage(image1),
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

                                              ValueListenableBuilder<int>(
                                                valueListenable:
                                                    nowPlayingIndexNotifier,
                                                builder: (
                                                  context,
                                                  currentIndex,
                                                  child,
                                                ) {
                                                  return AnimatedOpacity(
                                                    opacity:
                                                        (currentIndex == index)
                                                            ? 1.0
                                                            : 0.0,
                                                    duration: Duration(
                                                      milliseconds:
                                                          (650 * transitionSpeed)
                                                              .round(),
                                                    ),
                                                    curve: Curves.easeInOut,
                                                    child: Icon(
                                                      Icons.play_arrow_sharp,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            FileTags.getAllTracksMetadata(
                                              widget.songs,
                                            );
                                            if (mounted) {
                                              setState(() {
                                                if (nowPlayingIndex != index &&
                                                    index > 0) {
                                                  nowPlayingIndex = index - 1;
                                                  nowPlayingIndexNotifier
                                                      .value = nowPlayingIndex;

                                                  steps(nextStep: true);
                                                } else if (index == 0) {
                                                  nowPlayingIndex = index;
                                                  nowPlayingIndexNotifier
                                                      .value = nowPlayingIndex;

                                                  steps(replayStep: true);
                                                }
                                              });
                                            }
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
                              Positioned(
                                top: 15,
                                left: 150,
                                child: Text(
                                  'Playlist',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
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
      );

      Overlay.of(context).insert(playlistOverlayEntry!);
      playlistAnimationController.forward();
    }
  }

  void _hidePlaylistOverlay() {
    playlistAnimationController.reverse().then((_) {
      playlistOverlayEntry?.remove();
      playlistOverlayEntry = null;
    });
    setState(() {
      playerPadding = 0.0;
    });
    if (isPlaylistOpened) {
      if (mounted) {
        setState(() {
          playerPadding = 0.0;
          isPlaylistOpened = false;
          isPlaylistAnimating = false;
        });
      }
    }
  }

  void _showWarningMetadataOverlay(String errorMessage) {
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
                  // onHorizontalDragEnd: (details) {
                  //   if (details.primaryVelocity! > 100) {
                  //     _hideWarningMetadataOverlay();
                  //   }
                  // },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                      child: Container(
                        width: 350,
                        height: 80,
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
                        child: Stack(
                          children: [
                            Positioned(
                              top: 5,
                              left: 300,
                              child: IconButton(
                                onPressed: _hideWarningMetadataOverlay,
                                icon: Icon(Icons.close),
                                color: Colors.white,
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.only(left: 15, top: 15),
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
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
          (context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setOverlayState) {
              return Stack(
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
                              filter: ImageFilter.blur(
                                sigmaX: 175,
                                sigmaY: 175,
                              ),
                              child: Container(
                                width: min(
                                  MediaQuery.of(context).size.width * 0.92,
                                  600,
                                ),
                                height: min(
                                  MediaQuery.of(context).size.height * 0.92,
                                  715,
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
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 675,
                                      left: 290,
                                      child: Text(
                                        "made by Penises DG. No rights reserved.",
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Column(
                                        children: [
                                          SizedBox(height: 15),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 45,
                                                width: 150,

                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(10),
                                                      ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(width: 35),
                                                    Icon(
                                                      Icons.interests,
                                                      color: Colors.grey[300],
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      'Main',
                                                      style: TextStyle(
                                                        color: Colors.grey[300],
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w100,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 50),
                                              Container(
                                                height: 45,
                                                width: 150,
                                                decoration: BoxDecoration(
                                                  // color: themeColor,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(10),
                                                      ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(width: 35),
                                                    Icon(
                                                      Icons.cloud_sync_sharp,
                                                      color: Colors.grey[300],
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      'Server',
                                                      style: TextStyle(
                                                        color: Colors.grey[300],
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w100,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              IconButton(
                                                onPressed: _hideSettingsOverlay,
                                                icon: Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 25),
                                          Row(
                                            children: [
                                              SizedBox(width: 50),
                                              Text(
                                                'Playlist',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    EdgeInsetsGeometry.only(
                                                      left: 10,
                                                      right: 10,
                                                    ),
                                                child: Container(
                                                  width: 500,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    // color: themeColor,
                                                    border: Border.all(
                                                      width: 0.2,
                                                      color: Colors.grey,
                                                    ),

                                                    borderRadius:
                                                        BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {},
                                                    child: Row(
                                                      children: [
                                                        SizedBox(width: 15),
                                                        Text(
                                                          'Add songs',
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
                                              SizedBox(height: 5),
                                              Padding(
                                                padding:
                                                    EdgeInsetsGeometry.only(
                                                      left: 10,
                                                      right: 10,
                                                    ),
                                                child: Container(
                                                  width: 500,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    // color: themeColor,
                                                    border: Border.all(
                                                      width: 0.2,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      addFolderToSongs();
                                                      // var oldlist = widget.songs;

                                                      // setState(() {
                                                      //   widget.songs = oldlist
                                                      // });

                                                      Database.setValue(
                                                        'lastPlaylist',
                                                        widget.songs,
                                                      ); // After initializing the playlist, we add it to the table as the last one
                                                    },
                                                    child: Row(
                                                      children: [
                                                        SizedBox(width: 15),
                                                        Text(
                                                          'Add Folder',
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
                                              SizedBox(height: 5),
                                              Padding(
                                                padding:
                                                    EdgeInsetsGeometry.only(
                                                      left: 10,
                                                      right: 10,
                                                    ),
                                                child: Container(
                                                  width: 500,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    // color: themeColor,
                                                    border: Border.all(
                                                      width: 0.2,
                                                      color: Colors.grey,
                                                    ),

                                                    borderRadius:
                                                        BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                          bottomRight:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      // player.stop();
                                                      // _hidePlaylistOverlay();
                                                      // _hideWarningMetadataOverlay();
                                                      // _hideSettingsOverlay();

                                                      Navigator.pop(context);
                                                    },
                                                    child: Row(
                                                      children: [
                                                        SizedBox(width: 15),
                                                        Text(
                                                          'Clear',
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
                                            ],
                                          ),

                                          SizedBox(height: 25),
                                          Row(
                                            children: [
                                              SizedBox(width: 50),
                                              Text(
                                                'UI',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    EdgeInsetsGeometry.only(
                                                      left: 10,
                                                      right: 10,
                                                    ),
                                                child: Container(
                                                  width: 500,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    // color: themeColor,
                                                    border: Border.all(
                                                      width: 0.2,
                                                      color: Colors.grey,
                                                    ),

                                                    borderRadius:
                                                        BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(width: 15),
                                                      Expanded(
                                                        child: Text(
                                                          'White theme (beta ;d)',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsGeometry.only(
                                                              right: 15,
                                                            ),
                                                        child: Switch(
                                                          value: isWhiteTheme,
                                                          onChanged: (
                                                            bool value,
                                                          ) {
                                                            if (mounted) {
                                                              setState(() {
                                                                isWhiteTheme =
                                                                    value;
                                                              });
                                                              setOverlayState(
                                                                () {
                                                                  isWhiteTheme =
                                                                      value;
                                                                },
                                                              );

                                                              if (isWhiteTheme &&
                                                                  mounted) {
                                                                setState(() {
                                                                  themeColor =
                                                                      Color.fromARGB(
                                                                        255,
                                                                        197,
                                                                        197,
                                                                        197,
                                                                      );
                                                                  backgroundGradientColor =
                                                                      Color.fromRGBO(
                                                                        68,
                                                                        67,
                                                                        67,
                                                                        1,
                                                                      );
                                                                  backgroundSecondGradientColor =
                                                                      Color.fromRGBO(
                                                                        201,
                                                                        201,
                                                                        201,
                                                                        1,
                                                                      );
                                                                  albumArtShadowColor =
                                                                      Color.fromARGB(
                                                                        255,
                                                                        66,
                                                                        66,
                                                                        66,
                                                                      );
                                                                  alternativeThemeColor =
                                                                      Color.fromARGB(
                                                                        255,
                                                                        34,
                                                                        34,
                                                                        34,
                                                                      );
                                                                  Database.setValue(
                                                                    "isWhiteTheme",
                                                                    true,
                                                                  );
                                                                });
                                                              }

                                                              if (!isWhiteTheme &&
                                                                  mounted) {
                                                                themeColor =
                                                                    Color.fromARGB(
                                                                      255,
                                                                      34,
                                                                      34,
                                                                      34,
                                                                    );
                                                                backgroundGradientColor =
                                                                    Color.fromRGBO(
                                                                      24,
                                                                      24,
                                                                      26,
                                                                      1,
                                                                    );
                                                                backgroundSecondGradientColor =
                                                                    Color.fromRGBO(
                                                                      18,
                                                                      18,
                                                                      20,
                                                                      1,
                                                                    );
                                                                albumArtShadowColor =
                                                                    Color.fromARGB(
                                                                      255,
                                                                      21,
                                                                      21,
                                                                      21,
                                                                    );
                                                                alternativeThemeColor =
                                                                    Color.fromARGB(
                                                                      255,
                                                                      197,
                                                                      197,
                                                                      197,
                                                                    );
                                                                Database.setValue(
                                                                  "isWhiteTheme",
                                                                  false,
                                                                );
                                                              }
                                                            }

                                                            // if (isWhiteTheme) {
                                                            // setState(() {
                                                            //   themeColor = const Color.fromARGB(255, 220, 220, 220);
                                                            // });
                                                            // setOverlayState(() {
                                                            //   themeColor = const Color.fromARGB(255, 220, 220, 220);
                                                            // });
                                                            // }
                                                          },
                                                          activeColor:
                                                              const Color.fromARGB(
                                                                255,
                                                                34,
                                                                34,
                                                                34,
                                                              ),
                                                          activeTrackColor:
                                                              Colors.grey[300],
                                                          inactiveThumbColor:
                                                              Colors.grey[300],
                                                          inactiveTrackColor:
                                                              const Color.fromARGB(
                                                                255,
                                                                34,
                                                                34,
                                                                34,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Padding(
                                                padding:
                                                    EdgeInsetsGeometry.only(
                                                      left: 10,
                                                      right: 10,
                                                    ),
                                                child: Container(
                                                  width: 500,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    // color: themeColor,
                                                    border: Border.all(
                                                      width: 0.2,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(width: 15),
                                                      Expanded(
                                                        child: Text(
                                                          'Album art as background',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),

                                                      Padding(
                                                        padding:
                                                            EdgeInsetsGeometry.only(
                                                              right: 15,
                                                            ),

                                                        child: Switch(
                                                          value:
                                                              isBackgroudArtEnable,
                                                          onChanged: (
                                                            bool value,
                                                          ) {
                                                            if (mounted) {
                                                              setState(() {
                                                                isBackgroudArtEnable =
                                                                    value;
                                                              });
                                                              setOverlayState(() {
                                                                isBackgroudArtEnable =
                                                                    value;
                                                              });
                                                            }

                                                            if (!value) {
                                                              coverArtData =
                                                                  Uint8List(0);
                                                              Database.setValue(
                                                                "isBackgroudArtEnable",
                                                                false,
                                                              );
                                                            } else {
                                                              FileTags.getTagsFromFile(
                                                                widget
                                                                    .songs[nowPlayingIndex],
                                                              ).then((value) {
                                                                if (mounted) {
                                                                  setState(() {
                                                                    coverArtData =
                                                                        value['albumArt'];
                                                                  });
                                                                }
                                                              });
                                                              Database.setValue(
                                                                "isBackgroudArtEnable",
                                                                true,
                                                              );
                                                            }
                                                          },
                                                          activeColor:
                                                              const Color.fromARGB(
                                                                255,
                                                                34,
                                                                34,
                                                                34,
                                                              ),
                                                          activeTrackColor:
                                                              Colors.grey[300],
                                                          inactiveThumbColor:
                                                              Colors.grey[300],
                                                          inactiveTrackColor:
                                                              const Color.fromARGB(
                                                                255,
                                                                34,
                                                                34,
                                                                34,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // SizedBox(height: 5),
                                              // Container(
                                              //   width: 500,
                                              //   height: 50,
                                              //   decoration: BoxDecoration(
                                              //     // color: themeColor,
                                              //     border: Border.all(
                                              //       width: 0.2,
                                              //       color: Colors.grey,
                                              //     ),
                                              //   ),
                                              //   child: Row(
                                              //     children: [
                                              //       SizedBox(width: 15),
                                              //       Text(
                                              //         'Custom accent color',
                                              //         style: TextStyle(
                                              //           color: Colors.white,
                                              //           fontSize: 16,
                                              //         ),
                                              //       ),
                                              //       SizedBox(width: 175),
                                              //       // TextField(

                                              //       // ),
                                              //       Text(
                                              //         'COLORPICKER...',
                                              //         style: TextStyle(
                                              //           color: Colors.white,
                                              //         ),
                                              //       ),
                                              //     ],
                                              //   ),
                                              // ),
                                              SizedBox(height: 5),
                                              Padding(
                                                padding:
                                                    EdgeInsetsGeometry.only(
                                                      left: 10,
                                                      right: 10,
                                                    ),
                                                child: Container(
                                                  width: 500,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    // color: themeColor,
                                                    border: Border.all(
                                                      width: 0.2,
                                                      color: Colors.grey,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                          bottomRight:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(width: 15),
                                                      Expanded(
                                                        child: Text(
                                                          'Transition speed',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),

                                                      Padding(
                                                        padding:
                                                            EdgeInsetsGeometry.only(
                                                              right: 15,
                                                            ),
                                                        child: Slider(
                                                          min: 0.0,

                                                          max: 2.0,
                                                          // overlayColor: Color.fromARGB(1, 218, 218, 218),
                                                          activeColor:
                                                              Color.fromARGB(
                                                                255,
                                                                218,
                                                                218,
                                                                218,
                                                              ),
                                                          inactiveColor:
                                                              Color.fromARGB(
                                                                255,
                                                                218,
                                                                218,
                                                                218,
                                                              ),
                                                          value:
                                                              transitionSpeed,
                                                          onChanged: (value) {
                                                            if (mounted) {
                                                              setOverlayState(() {
                                                                transitionSpeed =
                                                                    value;
                                                              });
                                                              setState(() {
                                                                transitionSpeed =
                                                                    value;
                                                              });
                                                            }
                                                            Database.setValue(
                                                              "transitionSpeed",
                                                              value,
                                                            );
                                                          },
                                                          thumbColor:
                                                              Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 25),

                                          Row(
                                            children: [
                                              SizedBox(width: 50),
                                              Text(
                                                'Functional',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 15),
                                          Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    EdgeInsetsGeometry.only(
                                                      left: 10,
                                                      right: 10,
                                                    ),
                                                child: Container(
                                                  width: 500,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    // color: themeColor,
                                                    border: Border.all(
                                                      width: 0.2,
                                                      color: Colors.grey,
                                                    ),

                                                    borderRadius:
                                                        BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(width: 15),
                                                      Expanded(
                                                        child: Text(
                                                          'Automatic sorting of tracks',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),

                                                      Padding(
                                                        padding:
                                                            EdgeInsetsGeometry.only(
                                                              right: 15,
                                                            ),

                                                        child: Switch(
                                                          value:
                                                              autoTrackSorting,
                                                          onChanged: (
                                                            bool value,
                                                          ) {
                                                            if (mounted) {
                                                              setState(() {
                                                                autoTrackSorting =
                                                                    value;
                                                              });
                                                              setOverlayState(() {
                                                                autoTrackSorting =
                                                                    value;
                                                              });
                                                            }

                                                            if (autoTrackSorting) {
                                                              Database.setValue(
                                                                'autoTrackSorting',
                                                                true,
                                                              );
                                                            } else {
                                                              Database.setValue(
                                                                'autoTrackSorting',
                                                                false,
                                                              );
                                                            }
                                                          },
                                                          activeColor:
                                                              const Color.fromARGB(
                                                                255,
                                                                34,
                                                                34,
                                                                34,
                                                              ),
                                                          activeTrackColor:
                                                              Colors.grey[300],
                                                          inactiveThumbColor:
                                                              Colors.grey[300],
                                                          inactiveTrackColor:
                                                              const Color.fromARGB(
                                                                255,
                                                                34,
                                                                34,
                                                                34,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Padding(
                                                padding:
                                                    EdgeInsetsGeometry.only(
                                                      left: 10,
                                                      right: 10,
                                                    ),
                                                child: Container(
                                                  width: 500,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    // color: themeColor,
                                                    border: Border.all(
                                                      width: 0.2,
                                                      color: Colors.grey,
                                                    ),

                                                    borderRadius:
                                                        BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                          bottomRight:
                                                              Radius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      // player.stop();
                                                      // _hidePlaylistOverlay();
                                                      // _hideWarningMetadataOverlay();
                                                      // _hideSettingsOverlay();
                                                      Database.clear();
                                                      Navigator.pop(context);
                                                    },
                                                    child: Row(
                                                      children: [
                                                        SizedBox(width: 15),
                                                        Text(
                                                          'Reset settings to default',
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
                                            ],
                                          ),
                                        ],
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
              );
            },
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

  // List<String> songs = [];
  List<String> notShuffledPlaylist = [];
  List<String>? trackArtistNames = [];
  List<String> files = [];
  List<String> selectedFiles = [];
  List<String> fetchedSongs = [];

  String currentPosition = '0:00';
  String songDurationWidget = '0:00';
  String trackName = '';
  String lastSong = '';
  String? selectedFolderPath;
  String logPath = '';
  String albumArtUri =
      'https://d1csarkz8obe9u.cloudfront.net/posterpreviews/unknown-cd-album-mixtape-cover-design-templat-template-a0089f026a71f9722a55157364f22590_screen.jpg?ts=1644153606';
  String downloadDirectory = '';

  double songProgress = 0.0;
  double volumeValue = 0.7;
  double transitionSpeed = 1.0;
  double playerPadding = 0.0;

  int nowPlayingIndex = 0;
  Uint8List coverArtData = Uint8List.fromList([]);

  // Setting default settings (u know). They will be replaced with user settings upon initialization.

  bool isWhiteTheme = false;
  bool isRepeatEnable = false;
  bool isSliderActive = true;
  bool isPlaylistOpened = false;
  bool isPlayling = false;
  bool isShuffleEnable = false;
  bool isMetadataRecognizeEnable = true;
  bool isBackgroudArtEnable = true;
  bool isPlaylistAnimating = false;
  bool autoTrackSorting = true;

  final player = AudioPlayer();
  final ValueNotifier<int> nowPlayingIndexNotifier = ValueNotifier<int>(0);

  final volumeController = InteractiveSliderController(0.0);

  Color themeColor = Color.fromARGB(255, 34, 34, 34);
  Color backgroundGradientColor = Color.fromRGBO(24, 24, 26, 1);
  Color backgroundSecondGradientColor = Color.fromRGBO(18, 18, 20, 1);
  Color albumArtShadowColor = Color.fromARGB(255, 21, 21, 21);
  Color alternativeThemeColor = Color.fromARGB(255, 197, 197, 197);

  Color pickerColor = Colors.blue;

  final String serverApiURL = '127.0.0.1:5678';
  CancelToken? _currentToken;

  final logger = Logger('mainlogger');
  File? filePath;

  List<Map<String, dynamic>>? cachedPlaylist;
  // SMTCWindows smtc = SMTCWindows();

  // Working with additiongal songs that we can take from settings
  Future<void> addFolderToSongs() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        var files2 = await getFilesFromDirectory(selectedDirectory);
        if (files2.isNotEmpty) {
          for (var i in files2) {
            if (mounted) {
              setState(() {
                widget.songs.add(PathManager.getnormalizePath(i));
              });
            }
          }
        }
      }
    } catch (e) {
      logger.warning(
        'An error occurred while retrieving the selected multiple file: $e',
      );
    }
  }

  // Working with additiongal directories that we can take from settings
  Future<List<String>> getFilesFromDirectory(String directoryPath) async {
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
      files = fileNames.map((path) => path.split('/').last).toList();
      selectedFiles = fileNames;

      return fileNames;
    } catch (e) {
      logger.warning(
        'An error occurred while retrieving the selected multiple file: $e',
      );
      return [];
    }
  }

  // Applying existing tag to page

  Future<void> applyTagToPage(Map<String, dynamic> tag) async {
    setState(() {
      trackName =
          (tag['trackName']?.toString().trim().isNotEmpty ?? false)
              ? tag['trackName'].toString()
              : PathManager.getFileName(widget.songs[nowPlayingIndex]);

      trackArtistNames =
          (tag['trackArtistNames'] is List &&
                  tag['trackArtistNames'].isNotEmpty)
              ? List<String>.from(
                tag['trackArtistNames'].where(
                  (artist) => artist?.toString().trim().isNotEmpty ?? false,
                ),
              )
              : ['Unknown'];

      if (isBackgroudArtEnable) {
        coverArtData =
            (tag['albumArt'] is Uint8List) ? tag['albumArt'] : Uint8List(0);
      } else {
        coverArtData = Uint8List(0);
      }
      // smtc.updateMetadata(
      //   MusicMetadata(
      //     title: trackName,
      //     album: 'almbu',
      //     albumArtist: trackArtistNames?.join(', ') ?? 'Unknown',
      //     artist: trackArtistNames?.join(', ') ?? 'Unknown',
      //   ),
      // );
    });
  }

  // Future<void>

  void updatePageTag() async {
    // print(widget.songs);
    String trackID = PathManager.getFileName(
      widget.songs[nowPlayingIndex],
    ).replaceAll(RegExp(r'^quarkaudiotemptrack|\.mp3$'), '');
    // _showWarningMetadataOverlay('Warning! There is no connection to YMusic service!');

    Map? foundMap = widget.ymTracksInfo.firstWhere(
      (map) => map['id'] == trackID,
      orElse: () => null,
    );

    if (foundMap != null) {
      // var coverArt = await RecognizerService.urlImageToUint8List('https://${foundMap['cover']}');
      print('https://${foundMap['cover']}');
      setState(() {
        print('States');
        trackName = foundMap['title'];
        trackArtistNames = [foundMap['artists']];
        albumArtUri = 'https://${foundMap['cover']}';
        coverArtData = Uint8List(0);
      });
      updateSMTC();
    } else {
      setState(() {
        trackName = 'Unknown';
        trackArtistNames = ['Unknown'];
        albumArtUri =
            'https://d1csarkz8obe9u.cloudfront.net/posterpreviews/unknown-cd-album-mixtape-cover-design-templat-template-a0089f026a71f9722a55157364f22590_screen.jpg?ts=1644153606';
        coverArtData = Uint8List(0);
      });
      updateSMTC();
    }
  }

  Future<void> downloadNowTrackCauseItDoesntExists() async {
    String trackID = PathManager.getFileName(
      widget.songs[nowPlayingIndex],
    ).replaceAll(RegExp(r'^quarkaudiotemptrack|\.mp3$'), '');
    setState(() {
      trackName = 'Loading...';
    });
    print('---' * 78);
    print(trackID);
    print('---' * 78);

    YandexMusicAPI.getTrackDownloadLink(trackID, widget.ymToken, widget.ymUid)
        .then((link) async {
          print('Download link: $link');
          player.stop();
          player.setSource(UrlSource(link));
          player.play(UrlSource(link));
          return YandexMusicAPI.downloadTrack(
            '$downloadDirectory/quarkaudiotemptrack$trackID.mp3',
            link,
          );
        })
        .then((onValue) {
          print(
            'Track downloaded successfully24896983425890283904879023478932789328794',
          );
          // setState(() {
          Map? foundMap = widget.ymTracksInfo.firstWhere(
            (map) => map['id'] == trackID,
            orElse: () => null,
          );

          if (foundMap != null) {
            setState(() {
              print('States');
              trackName = foundMap['title'];
              trackArtistNames = [foundMap['artists']];
              albumArtUri = 'https://${foundMap['cover']}';
            });
            updateSMTC();
          } else {
            print('UNKNOWN');
            setState(() {
              trackName = 'Unknown';
              trackArtistNames = ['Unknown'];
              albumArtUri =
                  'https://d1csarkz8obe9u.cloudfront.net/posterpreviews/unknown-cd-album-mixtape-cover-design-templat-template-a0089f026a71f9722a55157364f22590_screen.jpg?ts=1644153606';
            });
            updateSMTC();
          }
          // });
        })
        .catchError((error) {
          print('Error: $error');
        });
  }

  // I was too lazy to make a class with an audio player, so we live like this for now
  Future<void> steps({
    // Ну не надо, ну не стукай
    bool nextStep = false,
    bool previousStep = false,
    bool stopSteps = false,
    bool replayStep = false,
  }) async {
    _hideWarningMetadataOverlay();

    if (nextStep) {
      print(nowPlayingIndex);

      _currentToken?.cancel();
      final token = CancelToken();
      _currentToken = token;
      if (mounted) {
        setState(() {
          nowPlayingIndex++;

          if (nowPlayingIndex >= widget.songs.length) {
            nowPlayingIndex = 0;
          }
          nowPlayingIndexNotifier.value = nowPlayingIndex;
        });
      }

      player.stop();
      var trackfile = File(widget.songs[nowPlayingIndex]);
      var exists = await trackfile.exists();

      if (!exists) {
        await downloadNowTrackCauseItDoesntExists();
      } else {
        if (isPlayling) {
          await Future.delayed(Duration(milliseconds: 50));
          player.play(DeviceFileSource(widget.songs[nowPlayingIndex]));
        } else {
          currentPosition = '0:00';
          songDurationWidget = '0:00';
        }
      }

      updatePageTag();

      Database.setValue('lastPlaylistTrack', widget.songs[nowPlayingIndex]);
      updateSMTC();
    }

    if (previousStep) {
      if (mounted) {
        setState(() {
          _currentToken?.cancel();
          nowPlayingIndex--;
          if (nowPlayingIndex < 0) {
            nowPlayingIndex = widget.songs.length - 1;
          }
          nowPlayingIndexNotifier.value = nowPlayingIndex;
        });
      }

      player.stop();
      var trackfile = File(widget.songs[nowPlayingIndex]);
      var exists = await trackfile.exists();

      if (!exists) {
        await downloadNowTrackCauseItDoesntExists();
      } else {
        if (isPlayling) {
          print(111111);
          await Future.delayed(Duration(milliseconds: 50));
          player.play(DeviceFileSource(widget.songs[nowPlayingIndex]));
        } else {
          currentPosition = '0:00';
          songDurationWidget = '0:00';
        }
      }

      updatePageTag();

      Database.setValue('lastPlaylistTrack', widget.songs[nowPlayingIndex]);

      updateSMTC();
    }

    if (stopSteps) {
      if (mounted) {
        setState(() {
          isPlayling = !isPlayling;

          if (!isPlayling) {
            player.pause();
            // smtc.setPlaybackStatus(PlaybackStatus.paused);
          } else {
            // smtc.setPlaybackStatus(PlaybackStatus.playing);
            player.play(DeviceFileSource(widget.songs[nowPlayingIndex]));
            Database.setValue(
              'lastPlaylistTrack',
              widget.songs[nowPlayingIndex],
            );
          }
        });
      }
    }

    if (replayStep) {
      _currentToken?.cancel();
      final token = CancelToken();
      _currentToken = token;
      // This function is intended for when we have designated index outside this class and want to reproduce it.
      player.stop();
      if (isPlayling) {
        print('it should be playing');
        player.setSource(DeviceFileSource(widget.songs[nowPlayingIndex + 1]));
        player.stop();

        Future.delayed(Duration(milliseconds: 100), () {
          player.play(DeviceFileSource(widget.songs[nowPlayingIndex]));
        });
      } else {
        currentPosition = '0:00';
        songDurationWidget = '0:00';
      }
      String trackID = PathManager.getFileName(
        widget.songs[nowPlayingIndex],
      ).replaceAll(RegExp(r'^quarkaudiotemptrack|\.mp3$'), '');
      Map? foundMap = widget.ymTracksInfo.firstWhere(
        (map) => map['id'] == trackID,
        orElse: () => null,
      );

      if (foundMap != null) {
        setState(() {
          trackName = foundMap['title'];
          trackArtistNames = [foundMap['artists']];
          albumArtUri = 'https://${foundMap['cover']}';
        });
      }

      Database.setValue('lastPlaylistTrack', widget.songs[nowPlayingIndex]);
      updateSMTC();
    }

    try {
      String trackID2 = PathManager.getFileName(
        nowPlayingIndex - 1 < widget.songs.length
            ? widget.songs[0]
            : widget.songs[nowPlayingIndex],
      ).replaceAll(RegExp(r'^quarkaudiotemptrack|\.mp3$'), '');

      String trackID3 = PathManager.getFileName(
        nowPlayingIndex + 1 > widget.songs.length
            ? widget.songs[0]
            : widget.songs[nowPlayingIndex + 2],
      ).replaceAll(RegExp(r'^quarkaudiotemptrack|\.mp3$'), '');

      var trackfile2 = File(
        nowPlayingIndex - 1 < widget.songs.length
            ? widget.songs[0]
            : widget.songs[nowPlayingIndex],
      );
      var exists2 = await trackfile2.exists();
      var trackfile3 = File(
        nowPlayingIndex + 1 > widget.songs.length
            ? widget.songs[0]
            : widget.songs[nowPlayingIndex + 2],
      );
      var exists3 = await trackfile3.exists();

      Future.delayed(Duration(milliseconds: 50), () {
        print(exists2);
        if (!exists2) {
          print('download -1');

          YandexMusicAPI.getTrackDownloadLink(
                trackID2,
                widget.ymToken,
                widget.ymUid,
              )
              .then((link) async {
                print('Download link: $link');
                return YandexMusicAPI.downloadTrack(
                  '$downloadDirectory/quarkaudiotemptrack$trackID2.mp3',
                  link,
                );
              })
              .then((onValue) async {
                print('Track downloaded successfully');
              })
              .catchError((error) {
                print('Error: $error');
              });
        }

        if (!exists3) {
          print('download +1');
          YandexMusicAPI.getTrackDownloadLink(
                trackID3,
                widget.ymToken,
                widget.ymUid,
              )
              .then((link) async {
                print('Download link: $link');
                return YandexMusicAPI.downloadTrack(
                  '$downloadDirectory/quarkaudiotemptrack$trackID3.mp3',
                  link,
                );
              })
              .then((onValue) async {
                print('Track downloaded successfully');
              })
              .catchError((error) {
                print('Error: $error');
              });
        }
      });
    } catch (e) {}
  }

  // Working with shuffle
  Future<void> createNewShuffledPlaylist({
    bool turnOnShuffle = false,
    bool turnOffShuffle = false,
  }) async {
      print('________________________________________________________________________________\n$notShuffledPlaylist');

    if (turnOnShuffle == true) {
      Database.setValue('shuffle', true);

      List<String> shuffledPlaylist = [];

      shuffledPlaylist = List.from(notShuffledPlaylist)..shuffle();
      widget.songs.clear();
      widget.songs.addAll(shuffledPlaylist);
      print(widget.songs);

    } else if (turnOffShuffle == true) {

      Database.setValue('shuffle', false);
      widget.songs.clear();
      widget.songs.addAll(notShuffledPlaylist);
      print(widget.songs);

      
    }
  }

  // Setup track complete listener
  void _setupPlayerListeners() {
    player.onPlayerComplete.listen((_) async {
      if (isRepeatEnable == false) {
        await steps(nextStep: true);
      } else {
        await steps(replayStep: true);
      }
    });
  }

  // Progressing track playback
  void progressState() {
    player.onPositionChanged.listen((position) async {
      final duration = await player.getDuration();
      String durationLocal = '';
      var currentPos = 0.0;

      if (duration != null) {
        var timeInMinutes = duration.inSeconds ~/ 60;
        var timeInSeconds = duration.inSeconds % 60;

        durationLocal += '$timeInMinutes:';

        if (timeInSeconds < 10) {
          durationLocal += '0$timeInSeconds';
        } else {
          durationLocal += '$timeInSeconds';
        }

        currentPos = position.inMicroseconds / duration.inMicroseconds * 100.0;
        if (currentPos > 100.0) {
          currentPos = 100.0;
        }
      }

      var timeInMinutes = position.inSeconds ~/ 60;
      var timeInSeconds = position.inSeconds % 60;

      String timing = '';

      timing += '$timeInMinutes:';

      if (timeInSeconds < 10) {
        timing += '0$timeInSeconds';
      } else {
        timing += '$timeInSeconds';
      }

      if (mounted) {
        setState(() {
          currentPosition = timing;
          songDurationWidget = durationLocal;
          songProgress = currentPos;

          if (isSliderActive) volumeController.value = currentPos / 100;
        });
      }
    });
  }

  // Changing volume
  void changeVolume(volume) {
    if (mounted) {
      setState(() {
        volumeValue = volume;
        player.setVolume(volumeValue);
      });
    }

    Database.setValue('volume', volumeValue);
  }

  // Get track timing by 0-100 value from timeline slider
  Future<int> getSecondsByValue(double value) async {
    final duration = await player.getDuration();
    if (duration != null) {
      return ((value / 100.0) * duration.inSeconds).round();
    }
    return 0;
  }

  // Logger init function
  Future<void> initLogger(String filePath2) async {
    filePath = File(filePath2);
    if (await filePath!.exists()) {
      await filePath!.delete();
    }
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final logLine =
          '${DateTime.now()} - ${record.level.name}: ${record.message}';
      filePath?.writeAsStringSync('$logLine\n', mode: FileMode.append);
    });
  }

  // Updating native media information
  Future<void> updateSMTC() async {
    // smtc.updateMetadata(
    //   MusicMetadata(
    //     title: trackName,
    //     albumArtist: trackArtistNames?.join(', ') ?? 'Unknown',
    //     artist: trackArtistNames?.join(', ') ?? 'Unknown',
    //     thumbnail: albumArtUri,
    //   ),
    // );
  }

  @override
  void initState() {
    // print(widget.lastSong);
    getApplicationDocumentsDirectory().then((value) {
      final logPath = '${value.path}/latestquarkaudio.log';
      initLogger(logPath).then((_) {});
    });

    getApplicationCacheDirectory().then((direct) {
      setState(() {
        downloadDirectory = direct.path;
      });
    });

    super.initState();
    _setupPlayerListeners();
    logger.info("setupPlayerListeners initalizing...");
    progressState();
    logger.info("Progress state initalizing...");

    Database.init();
    logger.info("Database initalizing...");

    // INITIALIZING PLAYLIST, INFO MESSAGE AND SETTINGS .... YOU KNOW

    warningMetadataAnimationController = AnimationController(
      duration: Duration(milliseconds: (650 * transitionSpeed).round()),
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
      duration: Duration(milliseconds: (650 * transitionSpeed).round()),
      vsync: this,
    );

    playlistOffsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: playlistAnimationController, curve: Curves.ease),
    );
    settingsAnimationController = AnimationController(
      duration: Duration(milliseconds: (850 * transitionSpeed).round()),
      vsync: this,
    );

    settingsOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: settingsAnimationController, curve: Curves.ease),
    );


    Future.delayed(Duration(milliseconds: 200), () {
      _precacheImages();
      String trackID = PathManager.getFileName(
        widget.songs[nowPlayingIndex],
      ).replaceAll(RegExp(r'^quarkaudiotemptrack|\.mp3$'), '');
      Map? foundMap = widget.ymTracksInfo.firstWhere(
        (map) => map['id'] == trackID,
        orElse: () => null,
      );

      if (foundMap != null) {
        // var coverArt = await RecognizerService.urlImageToUint8List('https://${foundMap['cover']}');
        print('https://${foundMap['cover']}');
        setState(() {
          print('States');
          trackName = foundMap['title'];
          trackArtistNames = [foundMap['artists']];
          albumArtUri = 'https://${foundMap['cover']}';
          coverArtData = Uint8List(0);
        });
        updateSMTC();
      } else {
        setState(() {
          trackName = 'Unknown';
          trackArtistNames = ['Unknown'];
          albumArtUri =
              'https://d1csarkz8obe9u.cloudfront.net/posterpreviews/unknown-cd-album-mixtape-cover-design-templat-template-a0089f026a71f9722a55157364f22590_screen.jpg?ts=1644153606';
          coverArtData = Uint8List(0);
        });
      }
    });

    Database.getKeys().then((value) {
      logger.info("Get keys from database...");

      // If the application starts for the first time, we set some standard values
      if (value.isEmpty) {
        logger.info("Putting in database...");

        Database.setValue('shuffle', false);
        Database.setValue('volume', 0.7);
        Database.setValue('metadataRecognize', true);
        Database.setValue('autoTrackSorting', true);
        Database.setValue("isBackgroudArtEnable", true);
        Database.setValue("isWhiteTheme", false);
        Database.setValue('transitionSpeed', 1.0);
      }
    });

    Database.getKeys().then(
      (value) => logger.info("Database loaded. Variables: $value"),
    ); // For debugging, we display all database values

    // Database.setValue(
    //   'lastPlaylist',
    //   songList,
    // ); // After initializing the playlist, we add it to the table as the last one

    Database.getValue('lastPlaylist').then(
      (value) => logger.info("Last playlist: $value"),
    ); // Getting data from the table and set the values

    Database.getValue('volume').then(
      (volume) => {
        if (volume != null && mounted)
          {
            setState(() {
              volumeValue = volume;
              player.setVolume(volume);
            }),
          },
      },
    );

    Database.getValue("isBackgroudArtEnable").then((value) {
      if (value != null && mounted) {
        isBackgroudArtEnable = value;
      }
    });

    Database.getValue("isWhiteTheme").then((value) {
      if (value != null && mounted) {
        setState(() {
          isWhiteTheme = value;

          if (isWhiteTheme) {
            themeColor = Color.fromARGB(255, 197, 197, 197);
            backgroundGradientColor = Color.fromRGBO(68, 67, 67, 1);
            backgroundSecondGradientColor = Color.fromRGBO(201, 201, 201, 1);
            albumArtShadowColor = Color.fromARGB(255, 66, 66, 66);
            alternativeThemeColor = Color.fromARGB(255, 34, 34, 34);
          }
        });
      }
    });

    Database.getValue('metadataRecognize').then((value) {
      if (value != null && mounted) {
        setState(() {
          isMetadataRecognizeEnable = value;
        });
      }
      if (value == null && mounted) {
        Database.setValue('metadataRecognize', true).then(
          (value) => {
            setState(() {
              isMetadataRecognizeEnable = true;
            }),
          },
        );
      }
    });

    Database.getValue("transitionSpeed").then((value) {
      if (value != null && mounted) {
        setState(() {
          transitionSpeed = value;
        });
      }
    });

    // smtc = SMTCWindows(
    //   metadata: MusicMetadata(
    //     title: trackName,
    //     album: 'almbu',
    //     albumArtist: trackArtistNames?.join(', ') ?? 'Unknown',
    //     artist: trackArtistNames?.join(', ') ?? 'Unknown',
    //     // thumbnail: albumArtUri,
    //   ),
    //   // Which buttons to show in the OS media player
    //   config: const SMTCConfig(
    //     fastForwardEnabled: true,
    //     nextEnabled: true,
    //     pauseEnabled: true,
    //     playEnabled: true,
    //     rewindEnabled: true,
    //     prevEnabled: true,
    //     stopEnabled: true,
    //   ),
    // );

    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   try {
    //     smtc.buttonPressStream.listen((event) {
    //       switch (event) {
    //         case PressedButton.play:
    //           steps(stopSteps: true);
    //           break;
    //         case PressedButton.pause:
    //           steps(stopSteps: true);
    //           break;
    //         case PressedButton.next:
    //           steps(nextStep: true);
    //           break;
    //         case PressedButton.previous:
    //           steps(previousStep: true);
    //           break;
    //         case PressedButton.stop:
    //           smtc.disableSmtc();
    //           break;
    //         default:
    //           break;
    //       }
    //     });
    //   } catch (e) {
    //     debugPrint("Error: $e");
    //   }
    // });
  }

  Future<void> _precacheImages() async {
    // Future.delayed(Duration(seconds: 10));
    List<Future> precacheFutures = [];

    for (int index = 0; index < widget.songs.length; index++) {
      String trackID = PathManager.getFileName(
        widget.songs[index],
      ).replaceAll(RegExp(r'^quarkaudiotemptrack|\.mp3$'), '');

      Map? foundMap = widget.ymTracksInfo.firstWhere(
        (map) => map['id'] == trackID,
        orElse: () => null,
      );

      if (foundMap != null) {
        String imageUrl = 'https://${foundMap['cover']}';
        // Предварительное кеширование
        precacheFutures.add(
          precacheImage(NetworkImage(imageUrl), context).catchError((error) {
            print('Ошибка кеширования изображения: $error');
          }),
        );
      }
    }
  }

  // Handling exit from player
  @override
  void dispose() {
    _currentToken?.cancel();

    player.dispose();
    playlistAnimationController.dispose();

    playlistOverlayEntry?.remove();
    warningMetadataOverlayEntry?.remove();
    settingsOverlayEntry?.remove();
    // smtc.disableSmtc();
    // smtc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: (750 * transitionSpeed).round()),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(albumArtUri),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.5),
                      BlendMode.darken,
                    ),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      backgroundGradientColor,
                      backgroundSecondGradientColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: Duration(
                      milliseconds: (650 * transitionSpeed).round(),
                    ),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: BackdropFilter(
                      key: ValueKey<Uint8List>(coverArtData),
                      filter: ImageFilter.blur(sigmaX: 95.0, sigmaY: 95.0),
                      child: AnimatedPadding(
                        duration: Duration(
                          milliseconds: (750 * transitionSpeed).round(),
                        ),
                        curve: Curves.ease,
                        padding: EdgeInsets.only(left: playerPadding),
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
                                    image: NetworkImage(albumArtUri),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withOpacity(0),
                                      BlendMode.darken,
                                    ),
                                  ),

                                  boxShadow: [
                                    BoxShadow(
                                      color: albumArtShadowColor,
                                      blurRadius: 10,
                                      offset: Offset(5, 10),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 35),

                              SizedBox(
                                width: 500,

                                child: SizedBox(
                                  height: 45,
                                  child: Text(
                                    PathManager.getFileName(trackName),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                          final seconds =
                                              await getSecondsByValue(value);
                                          await player.seek(
                                            Duration(seconds: seconds),
                                          );
                                        } catch (e) {
                                          logger.warning(
                                            "Error while seeking duration: $e",
                                          );
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

                                      onFocused:
                                          (value) => {isSliderActive = false},
                                    ),
                                  ),

                                  Text(
                                    songDurationWidget,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 5),

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
                                          color: themeColor,

                                          // color: const Color.fromARGB(
                                          //   255,
                                          //   40,
                                          //   40,
                                          //   42,
                                          // ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(30),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.skip_previous,

                                              color:
                                                  isWhiteTheme
                                                      ? alternativeThemeColor
                                                      : Colors.white,
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
                                          color: themeColor,
                                          // color: const Color.fromARGB(
                                          //   255,
                                          //   40,
                                          //   40,
                                          //   42,
                                          // ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(30),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isPlayling
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color:
                                                  isWhiteTheme
                                                      ? alternativeThemeColor
                                                      : Colors.white,

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
                                          color: themeColor,

                                          // color: const Color.fromARGB(
                                          //   255,
                                          //   40,
                                          //   40,
                                          //   42,
                                          // ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(30),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.skip_next,
                                              color:
                                                  isWhiteTheme
                                                      ? alternativeThemeColor
                                                      : Colors.white,

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
                              SizedBox(height: 5),

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
                                      highlightColor: Color.fromARGB(
                                        255,
                                        40,
                                        40,
                                        42,
                                      ),
                                      onTap: _showPlaylistOverlay,
                                      child: Container(
                                        height: 35,
                                        width: 35,

                                        decoration: BoxDecoration(
                                          color: themeColor,

                                          // color: const Color.fromARGB(
                                          //   255,
                                          //   40,
                                          //   40,
                                          //   42,
                                          // ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(30),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                              key: ValueKey<bool>(
                                                isPlaylistOpened,
                                              ),
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
                                      highlightColor: Color.fromARGB(
                                        255,
                                        40,
                                        40,
                                        42,
                                      ),

                                      onTap: () async {
                                        if (mounted) {
                                          setState(() {
                                            isShuffleEnable = !isShuffleEnable;
                                          });
                                        }

                                        // if (isShuffleEnable) {
                                        //   await createNewShuffledPlaylist(
                                        //     turnOnShuffle: true,
                                        //   );
                                        // }
                                        // if (!isShuffleEnable) {
                                        //   await createNewShuffledPlaylist(
                                        //     turnOffShuffle: true,
                                        //   );
                                        // }
                                        _hidePlaylistOverlay();
                                      },

                                      child: Container(
                                        height: 35,
                                        width: 35,

                                        decoration: BoxDecoration(
                                          color: themeColor,

                                          // color: Color.fromARGB(255, 40, 40, 42),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(30),
                                          ),
                                        ),

                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AnimatedSwitcher(
                                              duration: Duration(
                                                milliseconds: 120,
                                              ),
                                              transitionBuilder: (
                                                child,
                                                animation,
                                              ) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                );
                                              },
                                              layoutBuilder:
                                                  (
                                                    currentChild,
                                                    previousChildren,
                                                  ) => Stack(
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
                                                key: ValueKey<bool>(
                                                  isShuffleEnable,
                                                ),
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
                                      highlightColor: Color.fromARGB(
                                        255,
                                        40,
                                        40,
                                        42,
                                      ),
                                      onTap: () {
                                        if (mounted) {
                                          setState(() {
                                            isRepeatEnable = !isRepeatEnable;
                                          });
                                        }
                                      },
                                      child: Container(
                                        height: 35,
                                        width: 35,

                                        decoration: BoxDecoration(
                                          color: themeColor,

                                          // color: const Color.fromARGB(
                                          //   255,
                                          //   40,
                                          //   40,
                                          //   42,
                                          // ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(30),
                                          ),
                                        ),

                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AnimatedSwitcher(
                                              duration: Duration(
                                                milliseconds: 120,
                                              ),
                                              transitionBuilder: (
                                                child,
                                                animation,
                                              ) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                );
                                              },
                                              layoutBuilder:
                                                  (
                                                    currentChild,
                                                    previousChildren,
                                                  ) => Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      ...previousChildren,
                                                      if (currentChild != null)
                                                        currentChild,
                                                    ],
                                                  ),

                                              child: Icon(
                                                Icons.repeat_one_outlined,
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
                                                key: ValueKey<bool>(
                                                  isRepeatEnable,
                                                ),
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
                                      highlightColor: Color.fromARGB(
                                        255,
                                        40,
                                        40,
                                        42,
                                      ),
                                      onTap: _showSettingsOverlay,
                                      child: Container(
                                        height: 35,
                                        width: 35,

                                        decoration: BoxDecoration(
                                          color: themeColor,

                                          // color: const Color.fromARGB(
                                          //   255,
                                          //   40,
                                          //   40,
                                          //   42,
                                          // ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(30),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.menu,
                                              color:
                                                  isWhiteTheme
                                                      ? alternativeThemeColor
                                                      : Colors.white,

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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
