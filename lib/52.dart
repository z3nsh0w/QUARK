import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import 'playlist_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const SlidingOverlay(),
    );
  }
}

class SlidingOverlay extends StatefulWidget {
  const SlidingOverlay({super.key});

  @override
  State<SlidingOverlay> createState() => _SlidingOverlayState();
}

class _SlidingOverlayState extends State<SlidingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController warningMetadataAnimationController;
  late Animation<Offset> warningMetadataOffsetAnimation;
  OverlayEntry? warningMetadataOverlayEntry;

  @override
  void initState() {
    super.initState();
    warningMetadataAnimationController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    warningMetadataOffsetAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: warningMetadataAnimationController,
            curve: Curves.ease,
          ),
        );
  }

  void _showWarningMetadataOverlay() {
    warningMetadataOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
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
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
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
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          padding: EdgeInsets.only(left: 15, top: 15),
                        ),
                        SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {},
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
                              onTap: () {},
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

  @override
  void dispose() {
    warningMetadataAnimationController.dispose();
    warningMetadataOverlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 600),
          ElevatedButton(
            onPressed: _showWarningMetadataOverlay,
            child: const Text('Показать выезжающий виджет'),
          ),
          ElevatedButton(
            onPressed: _hideWarningMetadataOverlay,
            child: const Text('Спрятать виджет'),
          ),
        ],
      ),
    );
  }
}














































// class PlaylistPage extends StatefulWidget {
//   final List<String> songs;
//   const PlaylistPage({super.key, required this.songs});

//   @override
//   State<PlaylistPage> createState() => _PlaylistPageState();
// }

// class _PlaylistPageState extends State<PlaylistPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: AudioPlayerWidget(songs: widget.songs),
//     );
//   }
// }

// // Основной виджет аудиоплеера
// class AudioPlayerWidget extends StatefulWidget {
//   final List<String> songs;
//   const AudioPlayerWidget({super.key, required this.songs});

//   @override
//   State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
// }

// class _AudioPlayerWidgetState extends State<AudioPlayerWidget> 
//     with TickerProviderStateMixin {
  
//   // Все переменные состояния здесь
  
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         // Основной UI
//         _buildMainPlayerUI(),
        
//         // Оверлеи можно вынести в отдельные методы или виджеты
//         if (isPlaylistOpened) _buildPlaylistOverlay(),
//         if (warningMetadataOverlayEntry != null) _buildWarningOverlay(),
//       ],
//     );
//   }
  
//   Widget _buildMainPlayerUI() {
//     return Container(
//       // Основной UI плеера
//     );
//   }
  
//   Widget _buildPlaylistOverlay() {
//     return PlaylistOverlay(
//       songs: widget.songs,
//       onClose: _hidePlaylistOverlay,
//       onTrackSelected: (index) {
//         setState(() => nowPlayingIndex = index);
//         steps(next_step: true);
//       },
//     );
//   }
  
//   Widget _buildWarningOverlay() {
//     return MetadataWarningOverlay(
//       onAccept: _hideWarningMetadataOverlay,
//       onDecline: () {
//         _hideWarningMetadataOverlay();
//         // Логика отклонения метаданных
//       },
//     );
//   }
// }

// // Отдельные виджеты для оверлеев
// class PlaylistOverlay extends StatelessWidget {
//   final List<String> songs;
//   final VoidCallback onClose;
//   final Function(int) onTrackSelected;
  
//   const PlaylistOverlay({
//     super.key,
//     required this.songs,
//     required this.onClose,
//     required this.onTrackSelected,
//   });
  
//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       left: 0,
//       child: GestureDetector(
//         onHorizontalDragEnd: (details) {
//           if (details.primaryVelocity! > 100) {
//             onClose();
//           }
//         },
//         child: Container(
//           // UI плейлиста
//         ),
//       ),
//     );
//   }
// }

// class MetadataWarningOverlay extends StatelessWidget {
//   final VoidCallback onAccept;
//   final VoidCallback onDecline;
  
//   const MetadataWarningOverlay({
//     super.key,
//     required this.onAccept,
//     required this.onDecline,
//   });
  
//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       right: 15,
//       top: 15,
//       child: Container(
//         // UI предупреждения о метаданных
//       ),
//     );
//   }
// }
















































































// class AudioPlayerService {
//   final AudioPlayer _player = AudioPlayer();
  
//   Stream<Duration> get positionStream => _player.onPositionChanged;
//   Stream<void> get onComplete => _player.onPlayerComplete;
  
//   Future<void> play(String path) async {
//     await _player.play(DeviceFileSource(path));
//   }
  
//   Future<void> pause() async {
//     await _player.pause();
//   }
  
//   Future<void> stop() async {
//     await _player.stop();
//   }
  
//   Future<void> seek(Duration position) async {
//     await _player.seek(position);
//   }
  
//   Future<void> setVolume(double volume) async {
//     await _player.setVolume(volume);
//   }
  
//   Future<Duration?> getDuration() async {
//     return await _player.getDuration();
//   }
  
//   void dispose() {
//     _player.dispose();
//   }
// }

// class MetadataService {
//   Future<Map<String, dynamic>> loadTrackMetadata(String filePath) async {
//     var trackName = filePath.split(r'\').last.split(r'/').last;
    
//     try {
//       Tag? tag = await AudioTags.read(filePath);
      
//       return {
//         'trackName': tag?.title?.trim() ?? trackName,
//         'trackArtistNames': _parseArtists(tag?.trackArtist),
//         'albumName': tag?.album?.trim() ?? 'Unknown',
//         'albumArt': _extractAlbumArt(tag),
//         // ... другие поля
//       };
//     } catch (e) {
//       return {
//         'trackName': trackName,
//         'trackArtistNames': ['Unknown'],
//         'albumArt': Uint8List(0),
//       };
//     }
//   }
  
//   List<String> _parseArtists(String? artistString) {
//     if (artistString?.trim().isNotEmpty == true) {
//       return artistString!
//           .split(',')
//           .map((e) => e.trim())
//           .where((e) => e.isNotEmpty)
//           .toList();
//     }
//     return ['Unknown'];
//   }
  
//   Uint8List _extractAlbumArt(Tag? tag) {
//     if (tag?.pictures != null && tag!.pictures!.isNotEmpty) {
//       return tag.pictures!.first.bytes ?? Uint8List(0);
//     }
//     return Uint8List(0);
//   }
// }

// // Сервис для работы с внешним API
// class MusicRecognitionService {
//   final String serverApiURL = '127.0.0.1:5678';
  
//   Future<Map<String, dynamic>> recognizeTrack(String filePath) async {
//     var filename = filePath.split(r'/').last.split(r'\').last;
//     var query = 'FILENAME:$filename';
    
//     try {
//       final response = await http.get(
//         Uri.parse('http://$serverApiURL/get_metadata?data=$query'),
//       );
      
//       if (response.statusCode == 200) {
//         var data = jsonDecode(response.body) as Map<String, dynamic>;
        
//         return {
//           'trackname': data['title'],
//           'artist': data['artists'][0]['name'],
//           'coverarturl': data['cover_art_url'],
//         };
//       }
//     } catch (e) {
//       print('Recognition error: $e');
//     }
    
//     return {};
//   }
  
//   Future<Uint8List> downloadCoverArt(String imageUrl) async {
//     try {
//       final response = await http.get(Uri.parse(imageUrl));
//       if (response.statusCode == 200) {
//         return response.bodyBytes;
//       }
//     } catch (e) {
//       print('Cover art download error: $e');
//     }
//     return Uint8List(0);
//   }
// }

// // Контроллер состояния плейлиста
// class PlaylistController extends ChangeNotifier {
//   final AudioPlayerService _audioService;
//   final MetadataService _metadataService;
//   final MusicRecognitionService _recognitionService;
  
//   PlaylistController(
//     this._audioService,
//     this._metadataService,
//     this._recognitionService,
//   );
  
//   // Состояние
//   List<String> _songs = [];
//   int _currentIndex = 0;
//   bool _isPlaying = false;
//   bool _isShuffleEnabled = false;
//   bool _isRepeatEnabled = false;
//   double _volume = 0.7;
  
//   String _trackName = '';
//   List<String> _artistNames = [];
//   Uint8List _albumArt = Uint8List(0);
  
//   Duration _position = Duration.zero;
//   Duration _duration = Duration.zero;
  
//   // Геттеры
//   List<String> get songs => _songs;
//   int get currentIndex => _currentIndex;
//   bool get isPlaying => _isPlaying;
//   bool get isShuffleEnabled => _isShuffleEnabled;
//   bool get isRepeatEnabled => _isRepeatEnabled;
//   double get volume => _volume;
  
//   String get trackName => _trackName;
//   List<String> get artistNames => _artistNames;
//   Uint8List get albumArt => _albumArt;
  
//   Duration get position => _position;
//   Duration get duration => _duration;
//   double get progress => _duration.inMilliseconds > 0 
//       ? _position.inMilliseconds / _duration.inMilliseconds 
//       : 0.0;
  
//   // Методы управления
//   Future<void> initialize(List<String> songs) async {
//     _songs = List.from(songs);
    
//     // Подписываемся на события аудиоплеера
//     _audioService.positionStream.listen((position) {
//       _position = position;
//       notifyListeners();
//     });
    
//     _audioService.onComplete.listen((_) {
//       next();
//     });
    
//     await _loadCurrentTrackMetadata();
//   }
  
//   Future<void> play() async {
//     if (_songs.isEmpty) return;
    
//     await _audioService.play(_songs[_currentIndex]);
//     _isPlaying = true;
//     notifyListeners();
//   }
  
//   Future<void> pause() async {
//     await _audioService.pause();
//     _isPlaying = false;
//     notifyListeners();
//   }
  
//   Future<void> togglePlayPause() async {
//     if (_isPlaying) {
//       await pause();
//     } else {
//       await play();
//     }
//   }
  
//   Future<void> next() async {
//     _currentIndex = (_currentIndex + 1) % _songs.length;
//     await _audioService.stop();
    
//     if (_isPlaying) {
//       await play();
//     }
    
//     await _loadCurrentTrackMetadata();
//     notifyListeners();
//   }
  
//   Future<void> previous() async {
//     _currentIndex = _currentIndex > 0 ? _currentIndex - 1 : _songs.length - 1;
//     await _audioService.stop();
    
//     if (_isPlaying) {
//       await play();
//     }
    
//     await _loadCurrentTrackMetadata();
//     notifyListeners();
//   }
  
//   Future<void> seekTo(double progress) async {
//     final duration = await _audioService.getDuration();
//     if (duration != null) {
//       final position = Duration(
//         milliseconds: (progress * duration.inMilliseconds).round(),
//       );
//       await _audioService.seek(position);
//     }
//   }
  
//   Future<void> setVolume(double volume) async {
//     _volume = volume;
//     await _audioService.setVolume(volume);
//     notifyListeners();
//   }
  
//   void toggleShuffle() {
//     _isShuffleEnabled = !_isShuffleEnabled;
//     if (_isShuffleEnabled) {
//       _songs.shuffle();
//     }
//     notifyListeners();
//   }
  
//   void toggleRepeat() {
//     _isRepeatEnabled = !_isRepeatEnabled;
//     notifyListeners();
//   }
  
//   Future<void> _loadCurrentTrackMetadata() async {
//     if (_songs.isEmpty) return;
    
//     final metadata = await _metadataService.loadTrackMetadata(_songs[_currentIndex]);
    
//     _trackName = metadata['trackName'];
//     _artistNames = metadata['trackArtistNames'];
//     _albumArt = metadata['albumArt'];
    
//     // Попытка распознать трек через API
//     final recognitionData = await _recognitionService.recognizeTrack(_songs[_currentIndex]);
//     if (recognitionData.isNotEmpty) {
//       final coverArt = await _recognitionService.downloadCoverArt(recognitionData['coverarturl']);
//       if (coverArt.isNotEmpty) {
//         _albumArt = coverArt;
//         _trackName = recognitionData['trackname'];
//         _artistNames = [recognitionData['artist']];
//         // Здесь можно показать диалог подтверждения метаданных
//       }
//     }
    
//     notifyListeners();
//   }
  
//   void dispose() {
//     _audioService.dispose();
//     super.dispose();
//   }
// }

// // Виджет плеера теперь только отображает UI и реагирует на действия пользователя
// class AudioPlayerWidget extends StatelessWidget {
//   final PlaylistController controller;
  
//   const AudioPlayerWidget({super.key, required this.controller});
  
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider.value(
//       value: controller,
//       child: Consumer<PlaylistController>(
//         builder: (context, controller, child) {
//           return Scaffold(
//             backgroundColor: Colors.transparent,
//             body: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Обложка альбома
//                 _buildAlbumArt(controller),
                
//                 // Информация о треке
//                 _buildTrackInfo(controller),
                
//                 // Слайдер прогресса
//                 _buildProgressSlider(controller),
                
//                 // Кнопки управления
//                 _buildControlButtons(controller),
                
//                 // Слайдер громкости
//                 _buildVolumeSlider(controller),
                
//                 // Дополнительные кнопки
//                 _buildAdditionalButtons(controller),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
  
//   // Методы для построения отдельных частей UI
//   Widget _buildAlbumArt(PlaylistController controller) {
//     return Container(
//       height: 250,
//       width: 250,
//       decoration: BoxDecoration(
//         image: controller.albumArt.isNotEmpty
//             ? DecorationImage(
//                 image: MemoryImage(controller.albumArt),
//                 fit: BoxFit.cover,
//               )
//             : null,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.3),
//             blurRadius: 10,
//             offset: Offset(0, 5),
//           ),
//         ],
//       ),
//     );
//   }
  
//   // ... остальные методы для построения UI
// }
