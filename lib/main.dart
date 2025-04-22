import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'playlist_page.dart';

Future<void> main() async {

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




class _MyHomePageState extends State<MyHomePage> {
  String? selectedFolderPath;
  List<String> files = [];
  List<String> selectedFiles = [];

  void navigateToPlaylist() {
    if (selectedFiles.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistPage(songs: selectedFiles),
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
      print('Ошибка при выборе папки: $e');
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
      print('Ошибка при выборе файлов: $e');
    }
  }

  Future<void> getFilesFromDirectory(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      final List<String> fileNames = [];
      
      await for (final entity in dir.list()) {
        if (entity is File) {
          if (entity.path.toLowerCase().endsWith('.mp3')  ||
              entity.path.toLowerCase().endsWith('.wav')  ||
              entity.path.toLowerCase().endsWith('.flac') ||
              entity.path.toLowerCase().endsWith('.aac')  ||
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
      print('Ошибка при получении списка файлов: $e');
    }
  }

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
          // image: DecorationImage(
          //     image: AssetImage('assets/background.png'),
          //     fit: BoxFit.cover,
          //     colorFilter: ColorFilter.mode(
          //       Colors.black.withOpacity(0.2),
          //       BlendMode.darken,
          //     ),
          //   ),
          gradient: LinearGradient(
            
            // 
            // BASIC GRADIENT WITHOUT ALBUM IMAGE
            //   

            // colors: [
            //   Color.fromRGBO(44, 44, 48, 1),          OLD DESIGN
            //   Color.fromRGBO(34, 34, 38, 1),
            // ],            
            
            colors: [
              Color.fromRGBO(24, 24, 26, 1),
              Color.fromRGBO(18, 18, 20, 1),
            ],
            begin: Alignment.topLeft, end: Alignment.bottomRight
                ),
              
          color: Color.fromRGBO(40, 40, 40, 1),),

          child: ClipRect(

       
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 95.0,
                sigmaY: 95.0,
              ),
              child: Container(



                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icon.png', width: 150, height: 150),
                    SizedBox(height: 25),


                    // SizedBox(
                    //   width: 400,
                    //   child: Text(
                    //     'There is no songs.', 
                    //     style: TextStyle(color: Colors.white, fontSize: 24), 
                    //     textAlign: TextAlign.center
                    //   ),
                    // ),                    
                    SizedBox(
                      width: 400,
                      child: Text(
                        'QUARK', 
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700), 
                        textAlign: TextAlign.center
                      ),
                    ),



                    // SizedBox(height: 10),
                    SizedBox(height: 30),




                    SizedBox(

                      
                      width: 400,
                      child: Text(
                        'Select a file or folder, or drag files from the file manager into the application window to add songs to the playlist.', 
                        style: TextStyle(color: Colors.white, fontSize: 16), 
                        textAlign: TextAlign.center
                      ),
                    ),





                    SizedBox(height: 20),


                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      
                      child: InkWell(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        onTap: pickFolder,
                        child: Container(
                          height: 45,
                          width: 350,

                          decoration: BoxDecoration(
                            // color: const Color.fromRGBO(56, 56, 59, 1),
                            color: const Color.fromARGB(255, 39, 48, 59),
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Center(child: Text('Restore playlist', style: TextStyle(color: Colors.white, fontSize: 18,)),
                          
                          
                          )

                        ),
                    
                    ),
                    ),


                    SizedBox(height: 15),



                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      
                      child: InkWell(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        onTap: pickFolder,
                        child: Container(
                          height: 45,
                          width: 350,

                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 40, 40, 42),
                            // color: Colors.blueAccent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Center(child: Text('Add folder', style: TextStyle(color: Colors.white, fontSize: 18,)),
                          
                          
                          )

                        ),
                    
                    ),
                    ),



                    SizedBox(height: 15),



                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      
                      child: InkWell(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        onTap: pickFiles,
                        child: Container(
                          height: 45,
                          width: 350,

                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 40, 40, 42),
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Center(child: Text('Add song', style: TextStyle(color: Colors.white, fontSize: 18,)),
                          
                          
                          )

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








// BANK 

  //   Material(
  //   color: Colors.transparent,
  //   child: InkWell(
  //     borderRadius: BorderRadius.circular(8),
  //     // onTap: () => exit(0),
  //     child: Container(
  //       padding: EdgeInsets.all(12),
  //       child: Icon(
  //         Icons.close,
  //         size: 36,
  //         color: Colors.grey[400],
  //       ),
  //     ),
  //   ),
  // ),