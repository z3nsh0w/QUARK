// import 'package:flutter/material.dart';
// import 'dart:ui';
// import 'dart:io';
// import 'package:audioplayers/audioplayers.dart';
// import 'dart:typed_data';
// import 'package:interactive_slider/interactive_slider.dart';
// import 'package:flutter_media_metadata/flutter_media_metadata.dart';
// import 'dart:math';
// import 'package:easy_sidemenu/easy_sidemenu.dart';
// import 'package:sidebarx/sidebarx.dart';

// PageController pageController = PageController();
// SideMenuController sideMenu = SideMenuController();


// final _controller_sidebar = SidebarXController(selectedIndex: 0, extended: true);
// final _key = GlobalKey<ScaffoldState>();



// const primaryColor = Color(0xFF685BFF);
// const canvasColor = Color(0xFF2E2E48);
// const scaffoldBackgroundColor = Color(0xFF464667);
// const accentCanvasColor = Color(0xFF3E3E61);
// const white = Colors.white;
// final actionColor = const Color(0xFF5F5FA7).withOpacity(0.6);
// final divider = Divider(color: white.withOpacity(0.3), height: 1);

// class ExampleSidebarX extends StatelessWidget {
//   const ExampleSidebarX({
//     Key? key,
//     required SidebarXController controller,
//   })  : _controller_sidebar = controller,
//         super(key: key);

//   final SidebarXController _controller_sidebar;

//   @override
//   Widget build(BuildContext context) {
//     return SidebarX(
//       controller: _controller_sidebar,
//       theme: SidebarXTheme(
//         margin: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: Colors.transparent,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         hoverColor: scaffoldBackgroundColor,
//         textStyle: TextStyle(color: Colors.white),
//         selectedTextStyle: const TextStyle(color: Colors.white),
//         hoverTextStyle: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w500,
//         ),
//         itemTextPadding: const EdgeInsets.only(left: 30),
//         selectedItemTextPadding: const EdgeInsets.only(left: 30),
//         itemDecoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: Colors.transparent),
//         ),
//         selectedItemDecoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: actionColor.withOpacity(0.37),
//           ),
//           gradient: const LinearGradient(
//             colors: [Colors.transparent, Colors.transparent],
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.28),
//               blurRadius: 30,
//             )
//           ],
//         ),
//         iconTheme: IconThemeData(
//           color: Colors.white.withOpacity(0.7),
//           size: 20,
//         ),
//         selectedIconTheme: const IconThemeData(
//           color: Colors.white,
//           size: 20,
//         ),
//       ),
//       extendedTheme: const SidebarXTheme(
//         width: 200,
//         decoration: BoxDecoration(
//           color: canvasColor,
//         ),
//       ),
//       footerDivider: divider,
//       headerBuilder: (context, extended) {
//         return SizedBox(
//           height: 100,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//           ),
//         );
//       },
//       items: [
//         SidebarXItem(
//           icon: Icons.home,
//           label: 'Home',
//           onTap: () {
//             debugPrint('Home');
//           },
//         ),
//         const SidebarXItem(
//           icon: Icons.search,
//           label: 'Search',
//         ),
//         const SidebarXItem(
//           icon: Icons.people,
//           label: 'People',
//         ),
//         SidebarXItem(
//           icon: Icons.favorite,
//           label: 'Favorites',
//           selectable: false,
//           onTap: () => _showDisabledAlert(context),
//         ),
//         const SidebarXItem(
//           iconWidget: FlutterLogo(size: 20),
//           label: 'Flutter',
//         ),
//       ],
//     );
//   }

//   void _showDisabledAlert(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'Item disabled for selecting',
//           style: TextStyle(color: Colors.black),
//         ),
//         backgroundColor: Colors.white,
//       ),
//     );
//   }
// }

// class PlaylistPage extends StatefulWidget {
//   final List<String> songs;
//   const PlaylistPage({super.key, required this.songs});

//   @override
//   State<PlaylistPage> createState() => _PlaylistPageState();
// }

// class _PlaylistPageState extends State<PlaylistPage> {
//   String _current_position = '0:00';
//   String _song_duration_widget = '0:00';
//   String _trackName = '';

//   double _song_progress = 0.0;
//   double _volumeValue = 0.7;

//   int nowPlayingIndex = 0;
//   Uint8List imageData = Uint8List.fromList([]);

//   bool _is_repeater_active = false;
//   bool _is_slider_active = true;
//   bool _isPlaying = false;
//   bool _shuffle_enabled = false;
//   final player = AudioPlayer();
//   final _controller = InteractiveSliderController(0.0);

//   // String _trackArtist = '';
//   // String _album = '';
//   // String _albumArtist = '';
//   // int _trackNumber = 0;
//   // int _albumLength = 0;
//   // int _year = 0;
//   // String _genre = '';
//   // String _authorName = '';
//   // String _writerName = '';
//   // int _discNumber = 0;
//   // String _mimeType = '';
//   // int _trackDuration = 0;
//   // int _bitrate = 0;
//   List<String>? trackArtistNames = [];

//   Future<Map<String, dynamic>> _loadTag_using_dart_tags() async {
//     try {
//       final metadata = await MetadataRetriever.fromFile(
//         File(widget.songs[nowPlayingIndex]),
//       );

//       String? trackName = metadata.trackName;
//       List<String>? trackArtistNames = metadata.trackArtistNames;
//       String? albumName = metadata.albumName;
//       String? albumArtistName = metadata.albumArtistName;
//       int? trackNumber = metadata.trackNumber;
//       int? albumLength = metadata.albumLength;
//       int? year = metadata.year;
//       String? genre = metadata.genre;
//       String? authorName = metadata.authorName;
//       String? writerName = metadata.writerName;
//       int? discNumber = metadata.discNumber;
//       String? mimeType = metadata.mimeType;
//       int? trackDuration = metadata.trackDuration;
//       int? bitrate = metadata.bitrate;
//       Uint8List? albumArt = metadata.albumArt;

//       trackName ??= 'Unknown';
//       trackArtistNames ??= ['Unknown'];
//       albumName ??= 'Unknown';
//       albumArtistName ??= 'Unknown';
//       genre ??= 'Unknown';
//       authorName ??= 'Unknown';
//       writerName ??= 'Unknown';
//       discNumber ??= 0;
//       mimeType ??= 'Unknown';
//       trackDuration ??= 0;
//       bitrate ??= 0;
//       albumArt ??= Uint8List.fromList([]);

//       // final artistTransparentColor = () {
//       //   if (trackArtistNames == 'Unknown')
//       //   {
//       //      Map<String, dynamic> a = await _loadTag_using_dart_tags();
//       //   }
//       // };

//       Map<String, dynamic> all_tags = {
//         'trackName': trackName,
//         'trackArtistNames': trackArtistNames,
//         'albumName': albumName,
//         'albumArtistName': albumArtistName,
//         'trackNumber': trackNumber,
//         'albumLength': albumLength,
//         'year': year,
//         'genre': genre,
//         'authorName': authorName,
//         'writerName': writerName,
//         'discNumber': discNumber,
//         'mimeType': mimeType,
//         'trackDuration': trackDuration,
//         'bitrate': bitrate,
//         'albumArt': albumArt,
//       };

//       return all_tags;
//     } catch (e) {
//       return {};
//     }
//   }

//   void _setupPlayerListeners() {
//     player.onPlayerComplete.listen((_) async {
//       setState(() {
//         if (_is_repeater_active) {
//           nowPlayingIndex = nowPlayingIndex;
//         } else {
//           nowPlayingIndex++;
//         }

//         if (nowPlayingIndex >= widget.songs.length) {
//           nowPlayingIndex = 0;
//         }
//       });

//       if (_isPlaying) {
//         await player.play(DeviceFileSource(widget.songs[nowPlayingIndex]));
//       }

//       Map<String, dynamic> a = await _loadTag_using_dart_tags();
//       setState(() {
//         _trackName =
//             a['trackName']?.isEmpty ?? true
//                 ? widget.songs[nowPlayingIndex].split(r'\').last
//                 : a['trackName'];

//         trackArtistNames =
//             a['trackArtistNames'][0]?.isEmpty ?? true
//                 ? ['Unknown']
//                 : a['trackArtistNames'];
//         imageData = a['albumArt'];
//       });
//     });
//   }

//   void _progress_state() {
//     player.onPositionChanged.listen((position) async {
//       final duration = await player.getDuration();
//       String _duration = '';
//       var current_pos = 0.0;

//       if (duration != null) {
//         var time_inminutes = duration.inSeconds ~/ 60;
//         var time_inseconds = duration.inSeconds % 60;

//         _duration += '$time_inminutes:';

//         if (time_inseconds < 10) {
//           _duration += '0$time_inseconds';
//         } else {
//           _duration += '$time_inseconds';
//         }

//         current_pos = position.inMicroseconds / duration.inMicroseconds * 100.0;
//         if (current_pos > 100.0) {
//           current_pos = 100.0;
//         }
//       }

//       var time_inminutes = position.inSeconds ~/ 60;
//       var time_inseconds = position.inSeconds % 60;

//       String timing = '';

//       timing += '$time_inminutes:';

//       if (time_inseconds < 10) {
//         timing += '0$time_inseconds';
//       } else {
//         timing += '$time_inseconds';
//       }

//       setState(() {
//         _current_position = timing;
//         _song_duration_widget = _duration;
//         _song_progress = current_pos;

//         if (_is_slider_active) _controller.value = current_pos / 100;
//       });
//     });
//   }

//   Future<int> getSecondsByValue(double value) async {
//     final duration = await player.getDuration();
//     if (duration != null) {
//       return ((value / 100.0) * duration.inSeconds).round();
//     }
//     return 0;
//   }

//   // INITA EBLANITA

//   @override
//   void initState() {
//     super.initState();
//     _setupPlayerListeners();
//     _progress_state();

//     // sideMenu.addListener((index) {
//     //   pageController.jumpToPage(index); // comlete later
//     // });

//     _loadTag_using_dart_tags().then((value) {
//       setState(() {
//         print(value['trackName']);
//         if (value['trackName'] == '') {
//           _trackName = widget.songs[nowPlayingIndex].split(r'\').last;
//         } else {
//           _trackName = value['trackName'];
//         }

//         if (value['trackArtistNames'][0] == "") {
//           trackArtistNames = ['Unknown'];
//         } else {
//           trackArtistNames = value['trackArtistNames'];
//         }
//         imageData = value['albumArt'];
//       });
//     });
//   }

//   // INITA EBLANITA

//   @override
//   void dispose() {
//     player.dispose();
//     super.dispose();
//   }



//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _key,
//       backgroundColor: Colors.transparent,
//       drawer: ExampleSidebarX(controller: _controller_sidebar),
//       body: Center(
//         child: Container(
//           height: MediaQuery.of(context).size.height,
//           width: MediaQuery.of(context).size.width,

//           decoration: BoxDecoration(
//             image: DecorationImage(
//               image: MemoryImage(imageData),

//               fit: BoxFit.cover,
//               colorFilter: ColorFilter.mode(
//                 Colors.black.withOpacity(0.5),
//                 BlendMode.darken,
//               ),
//             ),
//             gradient: LinearGradient(
//               colors: [
//                 Color.fromRGBO(24, 24, 26, 1),
//                 Color.fromRGBO(18, 18, 20, 1),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),

//           child: ClipRect(
//             child: AnimatedSwitcher(
//               duration: Duration(milliseconds: 1000),
//               transitionBuilder: (Widget child, Animation<double> animation) {
//                 return FadeTransition(opacity: animation, child: child);
//               },
//               child: BackdropFilter(
//                 key: ValueKey<Uint8List>(imageData),

//                 filter: ImageFilter.blur(sigmaX: 95.0, sigmaY: 95.0),

//                 child: Container(
//                   color: Colors.transparent,

//                   // COL
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,

//                     children: [

//                       // ExampleSidebarX(controller: _controller_sidebar),

//                       Container(
//                         height: 250,
//                         width: 250,
//                         decoration: BoxDecoration(
//                           image: DecorationImage(
//                             image: MemoryImage(imageData),
//                             fit: BoxFit.cover,
//                             colorFilter: ColorFilter.mode(
//                               Colors.black.withOpacity(0),
//                               BlendMode.darken,
//                             ),
//                           ),

//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color.fromARGB(255, 21, 21, 21),
//                               blurRadius: 10,
//                               offset: Offset(5, 10),
//                             ),
//                           ],
//                         ),
//                       ),

//                       SizedBox(height: 35),

//                       SizedBox(
//                         width: 500,

//                         child: Text(
//                           _trackName.split(r'\').last,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),

//                       // ARTIST NAME TEXT
//                       Text(
//                         trackArtistNames?.join(', ') ?? 'Unknown',

//                         style: TextStyle(
//                           color: Colors.white,

//                           fontSize: 18,
//                           fontWeight: FontWeight.w300,
//                         ),
//                       ),

//                       SizedBox(height: 25),

//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             _current_position,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w300,
//                             ),
//                           ),

//                           SizedBox(
//                             width: 325,

//                             child: InteractiveSlider(
//                               controller: _controller,
//                               unfocusedHeight: 5,
//                               focusedHeight: 10,
//                               min: 0.0,
//                               max: 100.0,
//                               onProgressUpdated: (value) async {
//                                 _is_slider_active = true;
//                                 try {
//                                   final seconds = await getSecondsByValue(
//                                     value,
//                                   );
//                                   await player.seek(Duration(seconds: seconds));
//                                 } catch (e) {
//                                   print('ERR: $e');
//                                 }
//                               },

//                               brightness: Brightness.light,
//                               initialProgress: _song_progress,
//                               iconColor: Colors.white,
//                               gradient: LinearGradient(
//                                 colors: [Colors.white, Colors.white],
//                               ),
//                               shapeBorder: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.all(
//                                   Radius.circular(8),
//                                 ),
//                               ),

//                               onFocused: (value) => {_is_slider_active = false},
//                             ),
//                           ),

//                           Text(
//                             '$_song_duration_widget',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w300,
//                             ),
//                           ),
//                         ],
//                       ),

//                       SizedBox(height: 25),

//                       // PREVIOUS SONG BUTTON
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Material(
//                             color: Colors.transparent,
//                             borderRadius: BorderRadius.all(Radius.circular(20)),

//                             child: InkWell(
//                               borderRadius: BorderRadius.all(
//                                 Radius.circular(10),
//                               ),
//                               onTap: () async {
//                                 setState(() {
//                                   nowPlayingIndex--;
//                                   if (nowPlayingIndex < 0) {
//                                     nowPlayingIndex = widget.songs.length - 1;
//                                   }
//                                 });
//                                 player.stop();
//                                 if (_isPlaying) {
//                                   player.play(
//                                     DeviceFileSource(
//                                       widget.songs[nowPlayingIndex],
//                                     ),
//                                   );
//                                 }

//                                 Map<String, dynamic> a =
//                                     await _loadTag_using_dart_tags();

//                                 setState(() {
//                                   print(a['trackName']);
//                                   if (a['trackName'] == '') {
//                                     _trackName =
//                                         widget.songs[nowPlayingIndex]
//                                             .split(r'\')
//                                             .last;
//                                   } else {
//                                     _trackName = a['trackName'];
//                                   }

//                                   if (a['trackArtistNames'][0] == "") {
//                                     trackArtistNames = ['Unknown'];
//                                   } else {
//                                     trackArtistNames = a['trackArtistNames'];
//                                   }
//                                   imageData = a['albumArt'];
//                                 });
//                               },

//                               child: Container(
//                                 height: 40,
//                                 width: 40,

//                                 decoration: BoxDecoration(
//                                   color: const Color.fromARGB(255, 40, 40, 42),

//                                   borderRadius: BorderRadius.all(
//                                     Radius.circular(30),
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.skip_previous,
//                                       color: Colors.white,
//                                       size: 24,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),

//                           SizedBox(width: 15),

//                           // PREVIOUS SONG BUTTON
//                           Material(
//                             color: Colors.transparent,
//                             borderRadius: BorderRadius.all(Radius.circular(20)),

//                             child: InkWell(
//                               borderRadius: BorderRadius.all(
//                                 Radius.circular(10),
//                               ),
//                               onTap: () {
//                                 setState(() {
//                                   _isPlaying = !_isPlaying;

//                                   if (!_isPlaying) {
//                                     player.pause();
//                                   } else {
//                                     player.play(
//                                       DeviceFileSource(
//                                         widget.songs[nowPlayingIndex],
//                                       ),
//                                     );
//                                   }
//                                 });
//                               },

//                               child: Container(
//                                 height: 50,
//                                 width: 50,

//                                 decoration: BoxDecoration(
//                                   color: const Color.fromARGB(255, 40, 40, 42),
//                                   borderRadius: BorderRadius.all(
//                                     Radius.circular(30),
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       _isPlaying
//                                           ? Icons.pause
//                                           : Icons.play_arrow,
//                                       color: Colors.white,
//                                       size: 28,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),

//                           SizedBox(width: 15),

//                           // NEXT SONG BUTTON
//                           Material(
//                             color: Colors.transparent,
//                             borderRadius: BorderRadius.all(Radius.circular(20)),

//                             child: InkWell(
//                               borderRadius: BorderRadius.all(
//                                 Radius.circular(10),
//                               ),
//                               onTap: () async {
//                                 setState(() {
//                                   final _random = new Random();

//                                   if (_shuffle_enabled) {
//                                     nowPlayingIndex = _random.nextInt(
//                                       widget.songs.length.toInt(),
//                                     );
//                                   } else {
//                                     nowPlayingIndex++;
//                                   }

//                                   if (nowPlayingIndex >= widget.songs.length) {
//                                     nowPlayingIndex = 0;
//                                   }
//                                   player.stop();
//                                   if (_isPlaying) {
//                                     player.play(
//                                       DeviceFileSource(
//                                         widget.songs[nowPlayingIndex],
//                                       ),
//                                     );
//                                   }
//                                 });

//                                 Map<String, dynamic> a =
//                                     await _loadTag_using_dart_tags();

//                                 setState(() {
//                                   print(a['trackName']);
//                                   if (a['trackName'] == '') {
//                                     _trackName =
//                                         widget.songs[nowPlayingIndex]
//                                             .split(r'\')
//                                             .last;
//                                   } else {
//                                     _trackName = a['trackName'];
//                                   }

//                                   if (a['trackArtistNames'][0] == "") {
//                                     trackArtistNames = ['Unknown'];
//                                   } else {
//                                     trackArtistNames = a['trackArtistNames'];
//                                   }
//                                   imageData = a['albumArt'];
//                                 });
//                               },
//                               child: Container(
//                                 height: 40,
//                                 width: 40,

//                                 decoration: BoxDecoration(
//                                   color: const Color.fromARGB(255, 40, 40, 42),
//                                   borderRadius: BorderRadius.all(
//                                     Radius.circular(30),
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.skip_next,
//                                       color: Colors.white,
//                                       size: 24,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       // NEXT SONG BUTTON

//                       // PLAYLIST WIDOW AUUUUUGHHH
//                       SizedBox(
//                         width: 325,

//                         child: InteractiveSlider(
//                           startIcon: const Icon(Icons.volume_down),
//                           endIcon: const Icon(Icons.volume_up),
//                           min: 0.0,
//                           max: 1.0,
//                           brightness: Brightness.light,
//                           initialProgress: _volumeValue,
//                           iconColor: Colors.white,
//                           gradient: LinearGradient(
//                             colors: [Colors.white, Colors.white],
//                           ),
//                           onChanged:
//                               (value) => setState(() {
//                                 _volumeValue = value;
//                                 player.setVolume(_volumeValue);
//                               }),
//                         ),
//                       ),

//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Material(
//                             color: Colors.transparent,
//                             borderRadius: BorderRadius.all(Radius.circular(20)),

//                             child: InkWell(
//                               borderRadius: BorderRadius.all(
//                                 Radius.circular(10),
//                               ),
//                               splashColor: Colors.transparent,
//                               highlightColor: Color.fromARGB(255, 40, 40, 42),
//                               onTap: () {
//                                  _key.currentState?.openDrawer(); 
//                                  },
//                               child: Container(
//                                 height: 35,
//                                 width: 35,

//                                 decoration: BoxDecoration(
//                                   color: const Color.fromARGB(255, 40, 40, 42),
//                                   borderRadius: BorderRadius.all(
//                                     Radius.circular(30),
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.featured_play_list_outlined,
//                                       color: Colors.white,
//                                       size: 20,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),

//                           // PLAYLIST WIDOW AUUUUUGHHH
//                           SizedBox(width: 15),

//                           // SHUFFLITAS
//                           Material(
//                             color: Colors.transparent,
//                             borderRadius: BorderRadius.all(Radius.circular(20)),

//                             child: InkWell(
//                               splashColor: Colors.transparent,
//                               borderRadius: BorderRadius.circular(10),
//                               highlightColor: Color.fromARGB(255, 40, 40, 42),

//                               onTap: () {
//                                 setState(() {
//                                   _shuffle_enabled = !_shuffle_enabled;
//                                 });
//                               },

//                               child: Container(
//                                 height: 35,
//                                 width: 35,

//                                 decoration: BoxDecoration(
//                                   color: Color.fromARGB(255, 40, 40, 42),
//                                   borderRadius: BorderRadius.all(
//                                     Radius.circular(30),
//                                   ),
//                                 ),

//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     AnimatedSwitcher(
//                                       duration: Duration(milliseconds: 120),
//                                       transitionBuilder: (child, animation) {
//                                         return FadeTransition(
//                                           opacity: animation,
//                                           child: child,
//                                         );
//                                       },
//                                       layoutBuilder:
//                                           (currentChild, previousChildren) =>
//                                               Stack(
//                                                 alignment: Alignment.center,
//                                                 children: [
//                                                   ...previousChildren,
//                                                   if (currentChild != null)
//                                                     currentChild,
//                                                 ],
//                                               ),
//                                       child: Icon(
//                                         _shuffle_enabled
//                                             ? Icons.shuffle
//                                             : Icons.shuffle_outlined,
//                                         key: ValueKey<bool>(_shuffle_enabled),
//                                         color:
//                                             _shuffle_enabled
//                                                 ? Color.fromRGBO(
//                                                   255,
//                                                   255,
//                                                   255,
//                                                   1,
//                                                 )
//                                                 : Color.fromRGBO(
//                                                   255,
//                                                   255,
//                                                   255,
//                                                   0.5,
//                                                 ),
//                                         size: 20,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),

//                           // SHUFFLITAS
//                           SizedBox(width: 75),

//                           // REPEATER BUTTON
//                           Material(
//                             color: Colors.transparent,
//                             borderRadius: BorderRadius.all(Radius.circular(20)),

//                             child: InkWell(
//                               borderRadius: BorderRadius.all(
//                                 Radius.circular(10),
//                               ),
//                               splashColor: Colors.transparent,
//                               highlightColor: Color.fromARGB(255, 40, 40, 42),
//                               onTap: () {
//                                 setState(() {
//                                   _is_repeater_active = !_is_repeater_active;
//                                 });
//                               },
//                               child: Container(
//                                 height: 35,
//                                 width: 35,

//                                 decoration: BoxDecoration(
//                                   color: const Color.fromARGB(255, 40, 40, 42),
//                                   borderRadius: BorderRadius.all(
//                                     Radius.circular(30),
//                                   ),
//                                 ),

//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     AnimatedSwitcher(
//                                       duration: Duration(milliseconds: 120),
//                                       transitionBuilder: (child, animation) {
//                                         return FadeTransition(
//                                           opacity: animation,
//                                           child: child,
//                                         );
//                                       },
//                                       layoutBuilder:
//                                           (currentChild, previousChildren) =>
//                                               Stack(
//                                                 alignment: Alignment.center,
//                                                 children: [
//                                                   ...previousChildren,
//                                                   if (currentChild != null)
//                                                     currentChild,
//                                                 ],
//                                               ),

//                                       child: Icon(
//                                         Icons.repeat_outlined,
//                                         color:
//                                             _is_repeater_active
//                                                 ? Color.fromRGBO(
//                                                   255,
//                                                   255,
//                                                   255,
//                                                   1,
//                                                 )
//                                                 : Color.fromRGBO(
//                                                   255,
//                                                   255,
//                                                   255,
//                                                   0.500,
//                                                 ),
//                                         size: 20,
//                                         key: ValueKey<bool>(
//                                           _is_repeater_active,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),

//                           // REPEATER BUTTON
//                           SizedBox(width: 15),

//                           Material(
//                             color: Colors.transparent,
//                             borderRadius: BorderRadius.all(Radius.circular(20)),

//                             child: InkWell(
//                               borderRadius: BorderRadius.all(
//                                 Radius.circular(10),
//                               ),
//                               splashColor: Colors.transparent,
//                               highlightColor: Color.fromARGB(255, 40, 40, 42),
//                               onTap: () {
//                                 setState(() {});
//                               },
//                               child: Container(
//                                 height: 35,
//                                 width: 35,

//                                 decoration: BoxDecoration(
//                                   color: const Color.fromARGB(255, 40, 40, 42),
//                                   borderRadius: BorderRadius.all(
//                                     Radius.circular(30),
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.menu,
//                                       color: Colors.white,
//                                       size: 20,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
