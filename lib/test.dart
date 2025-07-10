// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_inappwebview_windows/flutter_inappwebview_windows.dart';

// void main() {
//   runApp(
//     MaterialApp(
//       theme: ThemeData(useMaterial3: true),
//       home: const WebViewApp(),
//     ),
//   );
// }

// class WebViewApp extends StatefulWidget {
//   const WebViewApp({super.key});

//   @override
//   State<WebViewApp> createState() => _WebViewAppState();
// }

// class _WebViewAppState extends State<WebViewApp> {
//   InAppWebViewController? webViewController;
//   double progress = 0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Flutter WebView'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => webViewController?.reload(),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           progress < 1.0
//               ? LinearProgressIndicator(value: progress)
//               : Container(),
//           Expanded(
//             child: InAppWebView(
//               initialUrlRequest: URLRequest(
//                 url: WebUri("https://flutter.dev"),
//               ),
//               onWebViewCreated: (controller) {
//                 webViewController = controller;
//               },
//               onProgressChanged: (controller, progress) {
//                 setState(() {
//                   this.progress = progress / 100;
//                 });
//               },
//               onLoadStart: (controller, url) {
//                 print("Started loading: $url");
//               },
//               onLoadStop: (controller, url) {
//                 print("Finished loading: $url");
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Add this to pubspec.yaml:
// // dependencies:
// //   flutter_inappwebview: ^6.0.0