import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:http/http.dart' as http;
import 'package:smtc_windows/smtc_windows.dart';
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
                ? tagsFromFile.pictures.first.bytes?? Uint8List(0)
                : Uint8List(0),
        'albumArtPNG': tagsFromFile.pictures.first.pictureType
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
    if (isPlaylistAnimating) {return;}
    if (isPlaylistOpened) {
      playlistAnimationController.reverse().then((_) {
        playlistOverlayEntry?.remove();
        playlistOverlayEntry = null;
      });
      if (mounted) {
        setState(() {
          isPlaylistOpened = false;
        });
      }
      return;
    }

    if (isPlaylistOpened == false) {
      if (mounted) {
        setState(() {
          isPlaylistOpened = true;
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
                                  future: FileTags.getAllTracksMetadata(songs),
                                  builder: (context, snapshot) {
                                    final tracks = snapshot.data ?? [];

                                    return ListView.builder(
                                      itemCount: tracks.length,
                                      itemBuilder: (context, index) {
                                        var name = tracks[index]['trackName'];
                                        var artist =
                                            tracks[index]['trackArtistNames'][0];
                                        var nowTrack = songs[index];
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

                                              Icon(
                                                Icons.play_arrow_sharp,
                                                color:
                                                    (songs[nowPlayingIndex] ==
                                                            nowTrack)
                                                        ? Colors.grey
                                                        : Colors.transparent,
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            FileTags.getAllTracksMetadata(
                                              songs,
                                            );
                                            if (mounted) {
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
    if (isPlaylistOpened) {
      if (mounted) {
        setState(() {
          isPlaylistOpened = false;
          isPlaylistAnimating = false;
        });
      }
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
                              padding: EdgeInsets.only(left: 15, top: 15),
                              child: Text(
                                'Is that correct metadata?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    RecognizerService.saveRecognizedData(
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
                                width: 600,
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
                                            borderRadius: BorderRadius.all(
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
                                                  fontWeight: FontWeight.w100,
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
                                            borderRadius: BorderRadius.all(
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
                                                  fontWeight: FontWeight.w100,
                                                ),
                                              ),
                                            ],
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
                                        Container(
                                          width: 500,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            // color: themeColor,
                                            border: Border.all(
                                              width: 0.2,
                                              color: Colors.grey,
                                            ),

                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              topRight: Radius.circular(10),
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
                                        SizedBox(height: 5),
                                        Container(
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
                                                songs,
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
                                        SizedBox(height: 5),
                                        Container(
                                          width: 500,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            // color: themeColor,
                                            border: Border.all(
                                              width: 0.2,
                                              color: Colors.grey,
                                            ),

                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(10),
                                              bottomRight: Radius.circular(10),
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
                                        Container(
                                          width: 500,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            // color: themeColor,
                                            border: Border.all(
                                              width: 0.2,
                                              color: Colors.grey,
                                            ),

                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              topRight: Radius.circular(10),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(width: 15),
                                              Text(
                                                'White theme (beta ;d)',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              // SizedBox(width: 305),
                                              SizedBox(width: 237),
                                              Switch(
                                                value: isWhiteTheme,
                                                onChanged: (bool value) {
                                                  if (mounted) {
                                                    setState(() {
                                                      isWhiteTheme = value;
                                                    });
                                                    setOverlayState(() {
                                                      isWhiteTheme = value;
                                                    });

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
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Container(
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
                                              Text(
                                                'Album art as background',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(width: 215),
                                              Switch(
                                                value: isBackgroudArtEnable,
                                                onChanged: (bool value) {
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
                                                    coverArtData = Uint8List(0);
                                                    Database.setValue(
                                                      "isBackgroudArtEnable",
                                                      false,
                                                    );
                                                  } else {
                                                    FileTags.getTagsFromFile(
                                                      songs[nowPlayingIndex],
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
                                            ],
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
                                        Container(
                                          width: 500,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            // color: themeColor,
                                            border: Border.all(
                                              width: 0.2,
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(10),
                                              bottomRight: Radius.circular(10),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(width: 15),
                                              Text(
                                                'Transition speed',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(width: 165),
                                              Slider(
                                                min: 0.0,

                                                max: 2.0,
                                                // overlayColor: Color.fromARGB(1, 218, 218, 218),
                                                activeColor: Color.fromARGB(
                                                  255,
                                                  218,
                                                  218,
                                                  218,
                                                ),
                                                inactiveColor: Color.fromARGB(
                                                  255,
                                                  218,
                                                  218,
                                                  218,
                                                ),
                                                value: transitionSpeed,
                                                onChanged: (value) {
                                                  if (mounted) {
                                                    setOverlayState(() {
                                                      transitionSpeed = value;
                                                    });
                                                    setState(() {
                                                      transitionSpeed = value;
                                                    });
                                                  }
                                                  Database.setValue(
                                                    "transitionSpeed",
                                                    value,
                                                  );
                                                },
                                                thumbColor: Colors.white,
                                              ),
                                            ],
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
                                        Container(
                                          width: 500,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            // color: themeColor,
                                            border: Border.all(
                                              width: 0.2,
                                              color: Colors.grey,
                                            ),

                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              topRight: Radius.circular(10),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(width: 15),
                                              Text(
                                                'Automatic sorting of tracks',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(width: 200),
                                              Switch(
                                                value: autoTrackSorting,
                                                onChanged: (bool value) {
                                                  if (mounted) {
                                                    setState(() {
                                                      autoTrackSorting = value;
                                                    });
                                                    setOverlayState(() {
                                                      autoTrackSorting = value;
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
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Container(
                                          width: 500,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            // color: themeColor,
                                            border: Border.all(
                                              width: 0.2,
                                              color: Colors.grey,
                                            ),

                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(10),
                                              bottomRight: Radius.circular(10),
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
                                        // Container(
                                        //   width: 500,
                                        //   height: 50,
                                        //   decoration: BoxDecoration(
                                        //     // color: themeColor,
                                        //     border: Border.all(
                                        //       width: 0.2,
                                        //       color: Colors.grey,
                                        //     ),

                                        //     borderRadius: BorderRadius.only(
                                        //       topLeft: Radius.circular(10),
                                        //       topRight: Radius.circular(10),
                                        //       bottomLeft: Radius.circular(10),
                                        //       bottomRight: Radius.circular(10),
                                        //     ),
                                        //   ),
                                        //   child: Row(
                                        //     children: [
                                        //       SizedBox(width: 15),
                                        //       Text(
                                        //         'Metadata recognize',
                                        //         style: TextStyle(
                                        //           color: Colors.white,
                                        //           fontSize: 16,
                                        //         ),
                                        //       ),
                                        //       SizedBox(width: 255),
                                        //       Switch(
                                        //         value:
                                        //             isMetadataRecognizeEnable,
                                        //         onChanged: (bool value) {
                                        //           if (mounted) {
                                        //             setState(() {
                                        //               isMetadataRecognizeEnable =
                                        //                   value;
                                        //             });
                                        //             setOverlayState(() {
                                        //               isMetadataRecognizeEnable =
                                        //                   value;
                                        //             });
                                        //           }

                                        //           if (isMetadataRecognizeEnable) {
                                        //             Database.setValue(
                                        //               'metadataRecognize',
                                        //               true,
                                        //             );
                                        //           } else {
                                        //             Database.setValue(
                                        //               'metadataRecognize',
                                        //               false,
                                        //             );
                                        //           }
                                        //         },
                                        //         activeColor:
                                        //             const Color.fromARGB(
                                        //               255,
                                        //               34,
                                        //               34,
                                        //               34,
                                        //             ),
                                        //         activeTrackColor:
                                        //             Colors.grey[300],
                                        //         inactiveThumbColor:
                                        //             Colors.grey[300],
                                        //         inactiveTrackColor:
                                        //             const Color.fromARGB(
                                        //               255,
                                        //               34,
                                        //               34,
                                        //               34,
                                        //             ),
                                        //       ),
                                        //     ],
                                        //   ),
                                        // ),
                                        Positioned(top: 0, left: 100, child: Text("made by Penises DG. No rights reserved.", style: TextStyle(color: Colors.grey[500]),), )
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

  List<String> songs = [];
  List<String> shuffledPlaylist = [];
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

  double songProgress = 0.0;
  double volumeValue = 0.7;
  double transitionSpeed = 1.0;

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
  late SMTCWindows smtc;
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
                songs.add(PathManager.getnormalizePath(i));
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
              : PathManager.getFileName(songs[nowPlayingIndex]);

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
      smtc.updateMetadata(
        MusicMetadata(
        title: trackName,
        album: 'almbu',
        albumArtist: trackArtistNames?.join(', ') ?? 'Unknown',
        artist: trackArtistNames?.join(', ') ?? 'Unknown',
        ),
      );
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
      _currentToken?.cancel();
      final token = CancelToken();
      _currentToken = token;
      if (mounted) {
        setState(() {
          nowPlayingIndex++;
          if (nowPlayingIndex >= songs.length) {
            nowPlayingIndex = 0;
          }
        });
      }

      player.stop();
      if (isPlayling) {
        player.play(DeviceFileSource(songs[nowPlayingIndex]));
      } else {
        currentPosition = '0:00';
        songDurationWidget = '0:00';
      }

      Map<String, dynamic> a = await FileTags.getTagsFromFile(
        songs[nowPlayingIndex],
      );

      await applyTagToPage(a);

      if (!fetchedSongs.contains(songs[nowPlayingIndex]) &&
          coverArtData.isEmpty &&
          isMetadataRecognizeEnable == true) {
        bool founded = false;

        final onValue = await Database.getValue('recognizedTracks');
        if (onValue != null) {
          for (var i in onValue) {
            final filename1 = PathManager.getFileName(i['filename']);
            final filename2 = PathManager.getFileName(songs[nowPlayingIndex]);

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
            Map metadata = await RecognizerService.recognizeMetadata(
              songs[nowPlayingIndex],
              serverApiURL,
            );

            if (token.isCancelled) return;

            if (metadata.isNotEmpty) {
              Uint8List coverart = await RecognizerService.urlImageToUint8List(
                metadata['coverarturl'],
              );

              if (token.isCancelled) return;
              if (mounted) {
                setState(() {
                  coverArtData = coverart;
                  trackName = metadata['trackname'];
                  trackArtistNames = [metadata['artist']];
                });
              }

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
      smtc.updateMetadata(
        MusicMetadata(
        title: trackName,
        album: 'almbu',
        albumArtist: trackArtistNames?.join(', ') ?? 'Unknown',
        artist: trackArtistNames?.join(', ') ?? 'Unknown',
        ),
      );
    }

    if (previousStep) {
      if (mounted) {
        setState(() {
          _currentToken?.cancel();
          nowPlayingIndex--;
          if (nowPlayingIndex < 0) {
            nowPlayingIndex = songs.length - 1;
          }
        });
      }

      player.stop();
      if (isPlayling) {
        player.play(DeviceFileSource(songs[nowPlayingIndex]));
      } else {
        currentPosition = '0:00';
        songDurationWidget = '0:00';
      }

      Map<String, dynamic> a = await FileTags.getTagsFromFile(
        songs[nowPlayingIndex],
      );

      await applyTagToPage(a);

      if (!fetchedSongs.contains(songs[nowPlayingIndex]) &&
          coverArtData.isEmpty &&
          isMetadataRecognizeEnable == true) {
        final onValue = await Database.getValue('recognizedTracks');
        if (onValue != null) {
          for (var i in onValue) {
            final filename1 = PathManager.getFileName(i['filename']);
            final filename2 = PathManager.getFileName(songs[nowPlayingIndex]);

            if (filename1 == filename2) {
              coverArtData = i['coverArt'];
              trackName = i['trackName'];
              trackArtistNames = [i['artistName'].toString()];
            }
          }
        }
      }

      Database.setValue('lastPlaylistTrack', songs[nowPlayingIndex]);

      smtc.updateMetadata(
          MusicMetadata(
          title: trackName,
          album: 'almbu',
          albumArtist: trackArtistNames?.join(', ') ?? 'Unknown',
          artist: trackArtistNames?.join(', ') ?? 'Unknown',
          ),
        );
    }

    if (stopSteps) {
      if (mounted) {
        setState(() {
          isPlayling = !isPlayling;

          if (!isPlayling) {
            player.pause();
            smtc.setPlaybackStatus(PlaybackStatus.paused);
          } else {
            smtc.setPlaybackStatus(PlaybackStatus.playing);
            player.play(DeviceFileSource(songs[nowPlayingIndex]));
            Database.setValue('lastPlaylistTrack', songs[nowPlayingIndex]);
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
        player.play(DeviceFileSource(songs[nowPlayingIndex]));
      } else {
        currentPosition = '0:00';
        songDurationWidget = '0:00';
      }

      Map<String, dynamic> a = await FileTags.getTagsFromFile(
        songs[nowPlayingIndex],
      );

      await applyTagToPage(a);

      if (!fetchedSongs.contains(songs[nowPlayingIndex]) &&
          coverArtData.isEmpty &&
          isMetadataRecognizeEnable == true) {
        bool founded = false;

        final onValue = await Database.getValue('recognizedTracks');
        if (onValue != null) {
          for (var i in onValue) {
            final filename1 = PathManager.getFileName(i['filename']);
            final filename2 = PathManager.getFileName(songs[nowPlayingIndex]);

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
            Map metadata = await RecognizerService.recognizeMetadata(
              songs[nowPlayingIndex],
              serverApiURL,
            );

            if (token.isCancelled) return;

            if (metadata.isNotEmpty) {
              Uint8List coverart = await RecognizerService.urlImageToUint8List(
                metadata['coverarturl'],
              );

              if (token.isCancelled) return;
              if (mounted) {
                setState(() {
                  coverArtData = coverart;
                  trackName = metadata['trackname'];
                  trackArtistNames = [metadata['artist']];
                });
              }

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
      smtc.updateMetadata(
        MusicMetadata(
        title: trackName,
        album: 'almbu',
        albumArtist: trackArtistNames?.join(', ') ?? 'Unknown',
        artist: trackArtistNames?.join(', ') ?? 'Unknown',
        ),
      );
    }
  }

  // Working with shuffle
  Future<void> createNewShuffledPlaylist({
    bool turnOnShuffle = false,
    bool turnOffShuffle = false,
  }) async {
    if (turnOnShuffle == true) {
      Database.setValue('shuffle', true);
      var songList = widget.songs;

      shuffledPlaylist = [];
      songs = [];
      songs = List.from(songList)..shuffle();
    } else if (turnOffShuffle == true) {
      Database.setValue('shuffle', false);

      songs = [];
      var songList = widget.songs;
      for (int i = 0; i < songList.length; i++) {
        songs.add(songList[i]);
      }
      if (autoTrackSorting) {
        songs.sort();
      }
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

  // Handling page loading
  @override
  void initState() {
    // print(widget.lastSong);
    getApplicationDocumentsDirectory().then((value) {
      final logPath = '${value.path}/latestquarkaudio.log';
      initLogger(logPath).then((_) {});
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

    // //

    var songList = widget.songs;

    for (int i = 0; i < songList.length; i++) {
      logger.info("Updating songs list...");

      // As a crutch, we fill in an alternative playlist variable instead of the main widget.songs variable
      songs.add(PathManager.getnormalizePath(songList[i]));
    }

    
    Database.getValue('autoTrackSorting').then((value) {
      if (value != null && mounted) {
        setState(() {
          autoTrackSorting = value;
          if (value) {
            songs.sort();
            // nowPlayingIndex = 0;
            FileTags.getTagsFromFile(songs[nowPlayingIndex]).then((tags) {
              applyTagToPage(tags);
            });
          }
        });
      }
    });

    if (PathManager.getnormalizePath(widget.lastSong) != '') {
      // Get the last listened track from the previous page
      var lastIndex = songs.indexWhere(
        (path) => path.endsWith(PathManager.getnormalizePath(widget.lastSong)),
      );
          print(lastIndex);
          print(widget.lastSong);
          print(PathManager.getnormalizePath(widget.lastSong));
          print(songs);



      if (lastIndex != -1) {
        if (mounted) {
          setState(() {
            print('4242');
            nowPlayingIndex = lastIndex;
          });
        }
      }
    //   if (nowPlayingIndex < 0 || nowPlayingIndex >= songs.length) {
    //   logger.info("Last song initalizing...");

    //   if (mounted) {
    //     setState(() {
    //       print(nowPlayingIndex);
    //       nowPlayingIndex = 0;
    //     });
    //   }
    // }
    }

    FileTags.getTagsFromFile(songs[nowPlayingIndex]).then((tags) {
      // Loading the cover of the active track
      logger.info("Getting tag from song...");

      if (mounted) {
        setState(() {
          if (tags['trackName'] == '') {
            trackName = PathManager.getFileName(songs[nowPlayingIndex]);
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

    Database.setValue(
      'lastPlaylist',
      songList,
    ); // After initializing the playlist, we add it to the table as the last one

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

    FileTags.getAllTracksMetadata(songs).then((value) {
      setState(() {
        cachedPlaylist = value;
      });
    });

    smtc = SMTCWindows(
      metadata: MusicMetadata(
        title: trackName,
        album: 'almbu',
        albumArtist: trackArtistNames?.join(', ') ?? 'Unknown',
        artist: trackArtistNames?.join(', ') ?? 'Unknown',
      ),
      // Which buttons to show in the OS media player
      config: const SMTCConfig(
        fastForwardEnabled: true,
        nextEnabled: true,
        pauseEnabled: true,
        playEnabled: true,
        rewindEnabled: true,
        prevEnabled: true,
        stopEnabled: true,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        smtc.buttonPressStream.listen((event) {
          switch (event) {
            case PressedButton.play:
              steps(stopSteps: true);
              break;
            case PressedButton.pause:
              steps(stopSteps: true);
              break;
            case PressedButton.next:
              steps(nextStep: true);
              break;
            case PressedButton.previous:
              steps(previousStep: true);
              break;
            case PressedButton.stop:
              smtc.disableSmtc();
              break;
            default:
              break;
          }
        });
      } catch (e) {
        debugPrint("Error: $e");
      }
    });
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
    smtc.disableSmtc();
    smtc.dispose();
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
                    image: MemoryImage(coverArtData),

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
                      milliseconds: (750 * transitionSpeed).round(),
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
                              )),
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
            ],
          ),
        ),
      ),
    );
  }
}
