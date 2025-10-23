import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:ericsson/tflite_service.dart';
import 'package:ericsson/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;

class IsolateData {
  final List<Uint8List> planes;
  final int height;
  final int width;
  final int uvRowStride;
  final int uvPixelStride;
  final int yRowStride;
  final int targetWidth;
  final int targetHeight;

  IsolateData(this.planes, this.height, this.width, this.uvRowStride,
      this.uvPixelStride, this.yRowStride, this.targetWidth, this.targetHeight);
}

Float32List _preprocessInIsolate(IsolateData isolateData) {
  return convertYUV420ToFloat32(
    isolateData, 
    isolateData.targetWidth, 
    isolateData.targetHeight
  );
}

// Float32List convertYUV420ToFloat32(
//     CameraImage image, int targetWidth, int targetHeight) {

//   final int width = image.width;
//   final int height = image.height;

//   // UV plane info
//   final int uvRowStride = image.planes[1].bytesPerRow;
//   final int uvPixelStride = image.planes[1].bytesPerPixel!;

//   // Create an empty RGB image buffer
//   var rgbImage = img.Image(width: width, height: height);

//   // Convert YUV420 to RGB
//   for (int y = 0; y < height; y++) {
//     for (int x = 0; x < width; x++) {
//       final int uvIndex =
//           uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);

//       final int bytesPerRowY = image.planes[0].bytesPerRow;
//       final int index = y * bytesPerRowY + x;

//       final int yp = image.planes[0].bytes[index];
//       final int up = image.planes[1].bytes[uvIndex];
//       final int vp = image.planes[2].bytes[uvIndex];

//       // Convert YUV to RGB
//       int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
//       int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
//           .round()
//           .clamp(0, 255);
//       int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

//       rgbImage.setPixelRgba(x, y, r, g, b, 255);
//     }
//   }

//   // Rotate image 90° clockwise
//   final rotatedImage = img.copyRotate(rgbImage, angle: 90);

//   // Resize/crop to square 640x640
//   final resizedImage = img.copyResizeCropSquare(rotatedImage, size: 640);

//   // Optional: Save the resized image for debugging
//   Future<void> saveResizedImage(img.Image image) async {
//     final dir = await getApplicationDocumentsDirectory();
//     final path = '${dir.path}/resized_test.png';
//     final pngBytes = img.encodePng(image);
//     await File(path).writeAsBytes(pngBytes);
//     print("Saved image to $path");
//   }

//   saveResizedImage(resizedImage);

//   // Convert image to Float32List for ML input
//   final Float32List floatInput =
//       Float32List(1 * 3 * targetHeight * targetWidth);

//   int index = 0;
//   for (int c = 0; c < 3; c++) {
//     for (int y = 0; y < targetHeight; y++) {
//       for (int x = 0; x < targetWidth; x++) {
//         final pixel = resizedImage.getPixel(x, y);
//         double value;

//         if (c == 0) {
//           value = pixel.r / 255.0; // Red channel
//         } else if (c == 1) {
//           value = pixel.g / 255.0; // Green channel
//         } else {
//           value = pixel.b / 255.0; // Blue channel
//         }

//         floatInput[index++] = value;
//       }
//     }
//   }

//   return floatInput;
// }



Float32List convertYUV420ToFloat32(IsolateData isolateData, int targetWidth, int targetHeight) {
  final int width = isolateData.width;
  final int height = isolateData.height;
  final int uvRowStride = isolateData.uvRowStride;
  final int uvPixelStride = isolateData.uvPixelStride;
  final int yRowStride = isolateData.yRowStride;
  final planes = isolateData.planes;

  var img2 = img.Image(width: width, height: height); 

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex =
          uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
      final int index = y * yRowStride + x;

      final yp = planes[0][index];
      final up = planes[1][uvIndex];
      final vp = planes[2][uvIndex];
      
      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .round()
          .clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
      img2.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  final rotated = img.copyRotate(img2, angle: 90);
  final resized = img.copyResizeCropSquare(rotated, size: 640);

  final Float32List floatInput = Float32List(1 * 3 * targetHeight * targetWidth);
  int index = 0;;
  for (int c = 0; c < 3; c++) {
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final pixel = resized.getPixel(x, y);
        double value;
        if (c == 0) {
          value = pixel.r / 255.0; // R
        } else if (c == 1) {
          value = pixel.g / 255.0; // G
        } else {
          value = pixel.b / 255.0; // B
        }
        floatInput[index++] = value;
      }
    }
  }
  return floatInput;
}

class IncidentList extends StatelessWidget {
  final String warnName;
  final int timeStamp;

  const IncidentList(
      {Key? key, required this.warnName, required this.timeStamp})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert timestamp to DateTime
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);
    // Format date and time
    final formatted = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 243, 244, 246),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(74, 199, 210, 255),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(warnName),
                  Text(formatted), // Show formatted date and time
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<String> labels = [
    "crack",
    "cracks",
    "mold",
    "peeling_paint",
    "stairstep_crack",
    "water_seepage",
  ];
  final List<List<double>> detections;
  final double scale; // scaling factor from 640 to screen size
  final bool flipHorizontally;

  DetectionPainter({
    required this.detections,
    required this.scale,
    this.flipHorizontally = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    for (var det in detections) {
      double x1 = det[0] * scale;
      double y1 = det[1] * scale;
      double x2 = det[2] * scale;
      double y2 = det[3] * scale;

      if (flipHorizontally) {
        x1 = size.width - x1;
        x2 = size.width - x2;
      }

      final rect = Rect.fromLTRB(x1, y1, x2, y2);
      canvas.drawRect(rect, paint);

      // Draw label
      final label =
          "${labels[det[5].toInt() % labels.length]} ${(det[4] * 100).toStringAsFixed(1)}%";
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x1, y1 - 14));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) =>
      oldDelegate.detections != detections;
}


class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<List<double>> detections = [];
  final TFLiteService _tfliteService = TFLiteService();
  bool _isModelLoaded = false;

  final List<String> labels = [
    "crack",
    "cracks",
    "mold",
    "peeling_paint",
    "stairstep_crack",
    "water_seepage",
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
    _setupCamera();
  }

  Future<String> loadModel() async {
  String result = await _tfliteService.loadModel();
  if (result.contains("Model loaded")) {
    setState(() {
      _isModelLoaded = true;
    });
  }
  print(result);
  return result;
}

  int lastInferenceTime = 0;
  bool isProcessing = false;

  Future<void> processCameraImage(CameraImage image) async {
    const int throttleMs = 400;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastInferenceTime < throttleMs) return;
    if (isProcessing) return;

    isProcessing = true;
    lastInferenceTime = now;

    print("camera running");

    try {
      final isolateData = IsolateData(
        [image.planes[0].bytes, image.planes[1].bytes, image.planes[2].bytes],
        image.height,
        image.width,
        image.planes[1].bytesPerRow,
        image.planes[1].bytesPerPixel!,
        image.planes[0].bytesPerRow,
        640,
        640,
      );

      final Float32List input = await compute(_preprocessInIsolate, isolateData);

      final List<List<double>>? output = await _tfliteService.runInference(input.buffer);

      if (output == null) {
        print("Inference failed or returned null.");
        return;
      }

      for(var box in output){
        print(box);
      }

      setState(() {
        detections = output
            .where((box) => box[4] > 0.25)
            .toList();
      });

      if (detections.isEmpty) {
        print("No detections.");
      } else {
        for (var det in detections) {
          if (det[4] > 0.25) {
            int rawClass = det[5].toInt();
            int cls = rawClass % labels.length;
            String label = labels[cls];
            print(
              "Detected $label (class $rawClass → mapped $cls) "
              "with confidence ${(det[4] * 100).toStringAsFixed(1)}% "
              "at [x1:${det[0]}, y1:${det[1]}, x2:${det[2]}, y2:${det[3]}]",
            );
          }
        }
      }
    } catch (e) {
      print("Error during processing: $e");
    } finally {
      isProcessing = false;
    }
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras.first, ResolutionPreset.medium,
            enableAudio: false);
        _initializeControllerFuture = _controller!.initialize();
        await _initializeControllerFuture;
        _controller!.startImageStream((CameraImage image) {
          if (_isModelLoaded) processCameraImage(image);
        });
        setState(() {});
      }
    } catch (e) {
      // Handle camera error
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 243, 244, 246),
        body: Padding(
          padding: const EdgeInsets.only(top: 65),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    double targetWidth = constraints.maxWidth;
                    double screenWidth = MediaQuery.of(context).size.width;
                    double targetHeight = 60.0;
                    return Column(
                      children: [
                        Container(
                          width: targetWidth,
                          height: targetHeight,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromARGB(74, 199, 210, 255),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Image(
                                  image:
                                      AssetImage('assets/images/camera_ic.png'),
                                  color: null,
                                  width: 35,
                                  height: 35,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '1234',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Tunnel A - Level B',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: targetWidth / 2.5,
                              height: targetHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(74, 199, 210, 255),
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image(
                                          image: AssetImage(
                                              'assets/images/vcam_ic.png'),
                                          width: 16,
                                          height: 16,
                                        ),
                                        SizedBox(height: 4),
                                        Image(
                                          image: AssetImage(
                                              'assets/images/green_circ.png'),
                                          width: 14,
                                          height: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Camera',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        'Connected',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: targetWidth / 2.5,
                              height: targetHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(74, 199, 210, 255),
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: Icon(Icons
                                          .battery_charging_full_outlined)),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Battery',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      FutureBuilder<int>(
                                        future: Battery().batteryLevel,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Text(
                                              'Loading...',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            );
                                          } else if (snapshot.hasError) {
                                            return Text(
                                              'Error',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            );
                                          } else {
                                            return Text(
                                              '${snapshot.data}%',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Container(
                            width: targetWidth - 20,
                            height: 280,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(74, 199, 210, 255),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16.0, top: 16.0, bottom: 16.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Live Camera Feed',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          Text(
                                            'Real-Time View',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 16.0, top: 16.0, bottom: 16.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'LIVE',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: Center(
                                      child: (_controller != null &&
                                              _initializeControllerFuture !=
                                                  null)
                                          ? FutureBuilder<void>(
                                              future:
                                                  _initializeControllerFuture,
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.done) {
                                                  return SizedBox(
                                                    width: screenWidth,
                                                    height:
                                                        screenWidth, // square
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              13),
                                                      child: Stack(
                                                        fit: StackFit.expand,
                                                        children: [
                                                          CameraPreview(
                                                              _controller!),
                                                          if (detections
                                                              .isNotEmpty)
                                                            CustomPaint(
                                                              painter:
                                                                  DetectionPainter(
                                                                detections:
                                                                    detections,
                                                                scale:
                                                                    screenWidth /
                                                                        640,
                                                                flipHorizontally:
                                                                    false, // true for front camera
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  return const Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                }
                                              },
                                            )
                                          : Center(
                                              child: Text(
                                                'Camera not available',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                        const SizedBox(height: 25),
                        Container(
                            width: targetWidth - 20,
                            height: 280,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(74, 199, 210, 255),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16.0, top: 16.0, bottom: 16.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Recent Alerts',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        Text(
                                          'Latest Safety Incidents Detected',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        right: 16.0, top: 16.0, bottom: 16.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              minimumSize: const Size(50, 18),
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 243, 244, 246),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            onPressed: () {
                                              // TODO: Add your navigation or action here
                                            },
                                            child: Text(
                                              'View All',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Column(children: [
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Column(
                                    children: [
                                      IncidentList(
                                          warnName: 'Corrosion Detected ',
                                          timeStamp: 1760033682),
                                      SizedBox(height: 10),
                                      IncidentList(
                                          warnName: 'Crack (Wall) Detected ',
                                          timeStamp: 1760023682),
                                      SizedBox(height: 10),
                                      IncidentList(
                                          warnName: 'Crack (Floor) Detected ',
                                          timeStamp: 1760011682),
                                    ],
                                  ),
                                )
                              ])
                            ])),
                      ],
                    );
                  },
                )
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
            elevation: 0,
            backgroundColor: const Color.fromARGB(255, 243, 244, 246),
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                label: 'Menu',
              ),
            ],
            onTap: (value) => {if (value == 0) {}}),
      ),
    );
  }
}
