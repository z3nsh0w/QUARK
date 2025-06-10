// import 'package:flutter/material.dart';
// import 'dart:ui';
// import 'dart:io';
// import 'package:file_picker/file_picker.dart';

// Future<void> main() async {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'test build',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }



// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }




// class _MyHomePageState extends State<MyHomePage> {
//   String? selectedFolderPath;
//   List<String> files = [];
//   List<String> selectedFiles = [];

//   Future<void> pickFolder() async {
//     try {
//       String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
//       if (selectedDirectory != null) {
//         setState(() {
//           selectedFolderPath = selectedDirectory;
//           files = [];
//         });
//         await getFilesFromDirectory(selectedDirectory);
//       }
//     } catch (e) {
//       print('Ошибка при выборе папки: $e');
//     }
//   }

//   Future<void> pickFiles() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         allowMultiple: true,
//         type: FileType.audio,
//       );

//       if (result != null) {
//         setState(() {
//           selectedFiles = result.paths.map((path) => path!).toList();
//         });
//       }
//     } catch (e) {
//       print('Ошибка при выборе файлов: $e');
//     }
//   }

//   Future<void> getFilesFromDirectory(String directoryPath) async {
//     try {
//       final dir = Directory(directoryPath);
//       final List<String> fileNames = [];
      
//       await for (final entity in dir.list()) {
//         if (entity is File) {
//           fileNames.add(entity.path.split('/').last);
//         }
//       }
      
//       setState(() {
//         files = fileNames;
//       });
//     } catch (e) {
//       print('Ошибка при получении списка файлов: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//     backgroundColor: Colors.transparent,
  
//     body: Center(


//       child: Container(
//         // MAIN CONTAINER THAT CONTAINS MAIN PAGE
//         height: MediaQuery.of(context).size.height,
//         width: MediaQuery.of(context).size.width,
//         decoration: BoxDecoration(
//           image: DecorationImage(
//               image: AssetImage('assets/background.png'),
//               fit: BoxFit.cover,
//               colorFilter: ColorFilter.mode(
//                 Colors.black.withOpacity(0.2),
//                 BlendMode.darken,
//               ),
//             ),
//           gradient: LinearGradient(
            
//             // 
//             // BASIC GRADIENT WITHOUT ALBUM IMAGE
//             //   

//             colors: [
//               Color.fromRGBO(40, 40, 40, 1),
//               Color.fromRGBO(127, 127, 143, 1),
//             ],
//             begin: Alignment.topLeft, end: Alignment.bottomRight
//                 ),
              
//           color: Color.fromRGBO(40, 40, 40, 1),),

//           child: ClipRect(

       
//             child: BackdropFilter(
//               filter: ImageFilter.blur(
//                 sigmaX: 95.0,
//                 sigmaY: 95.0,
//               ),
//               child: Container(



//                 color: Colors.transparent,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     if (selectedFolderPath != null) ...[



//                       Padding(
//                         padding: EdgeInsets.only(bottom: 20),
//                         child: Text(
//                           'Выбранная папка:\n$selectedFolderPath',
//                           style: TextStyle(color: Colors.white, fontSize: 16),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                       if (files.isNotEmpty) ...[



//                         Text(
//                           'Файлы в папке:',
//                           style: TextStyle(color: Colors.white, fontSize: 20),
//                         ),
//                         SizedBox(height: 10),
//                         Container(
//                           height: 200,
//                           width: 300,
//                           decoration: BoxDecoration(
//                             color: Colors.black.withOpacity(0.3),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: ListView.builder(
//                             itemCount: files.length,
//                             itemBuilder: (context, index) {
//                               return Padding(
//                                 padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                                 child: Text(
//                                   files[index],
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ]
                      
                      
//                        else
//                         Text(
//                           'В папке нет файлов',
//                           style: TextStyle(color: Colors.white, fontSize: 16),
//                         ),
//                     ]
                    
                    
                    
//                      else
//                       Text(
//                         'Папка не выбрана',
//                         style: TextStyle(color: Colors.white, fontSize: 24)
//                       ),

                      
//                     SizedBox(height: 50),
//                     Material(
//                       color: Colors.transparent,
//                       borderRadius: BorderRadius.all(Radius.circular(20)),
                      
//                       child: InkWell(
//                         borderRadius: BorderRadius.all(Radius.circular(10)),
//                         onTap: pickFolder,
//                         child: Container(
//                           height: 50,
//                           width: 150,

//                           decoration: BoxDecoration(
//                             color: Colors.blueAccent,
//                             borderRadius: BorderRadius.all(Radius.circular(20)),
//                           ),
//                           child: Center(child: Text('Add folder', style: TextStyle(color: Colors.white, fontSize: 18,)),
                          
                          
//                           )

//                         ),
                    
//                     ),
//                     ),



//                     SizedBox(height: 15),



//                     Material(
//                       color: Colors.transparent,
//                       borderRadius: BorderRadius.all(Radius.circular(20)),
                      
//                       child: InkWell(
//                         borderRadius: BorderRadius.all(Radius.circular(10)),
//                         onTap: pickFiles,
//                         child: Container(
//                           height: 50,
//                           width: 150,

//                           decoration: BoxDecoration(
//                             color: const Color.fromRGBO(56, 56, 59, 1),
//                             borderRadius: BorderRadius.all(Radius.circular(20)),
//                           ),
//                           child: Center(child: Text('Add song', style: TextStyle(color: Colors.white, fontSize: 18,)),
                          
                          
//                           )

//                         ),
                    
//                     ),
//                     ),

                    
//                   ],





//                 ),
//               ),
//             ),





//           ),
//         ),
//       ),
//     );
//   }
// }








// // BANK 

//   //   Material(
//   //   color: Colors.transparent,
//   //   child: InkWell(
//   //     borderRadius: BorderRadius.circular(8),
//   //     // onTap: () => exit(0),
//   //     child: Container(
//   //       padding: EdgeInsets.all(12),
//   //       child: Icon(
//   //         Icons.close,
//   //         size: 36,
//   //         color: Colors.grey[400],
//   //       ),
//   //     ),
//   //   ),
//   // ),
















