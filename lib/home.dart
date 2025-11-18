import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:ericsson/camera.dart';
import 'package:ericsson/tflite_service.dart';
import 'package:ericsson/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
      isolateData, isolateData.targetWidth, isolateData.targetHeight);
}

Float32List convertYUV420ToFloat32(
    IsolateData isolateData, int targetWidth, int targetHeight) {
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

  final Float32List floatInput =
      Float32List(1 * 3 * targetHeight * targetWidth);
  int index = 0;
  ;
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

class Location {
  final String type;
  final List<double> coordinates;

  Location({
    required this.type,
    required this.coordinates,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };
}

class DetectionLog {
  final String label;
  final DateTime timestamp;
  final double confidence;
   final Location location;

  DetectionLog({
    required this.label,
    required this.timestamp,
    required this.confidence,
     required this.location,
  });

    Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'location': location.toJson(),
      };

}

class DetectionPainter extends CustomPainter {
  final List<String> labels = [
 "burned socket",
 "damage wire",
 "overloaded socket",
 '0',
 "black smoke",
 "fire1",
 "smoky fire",
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

  List<List<double>> _currentDetections = [];
  List<DetectionLog> _detectionLog = [];

  final List<DetectionLog> _unsentDetections = [];
  bool isSending = false;

  final TFLiteService _tfliteService = TFLiteService();
  bool _isModelLoaded = false;

  final Map<String, DateTime> _lastAlertTimes = {};
  final Duration alertCooldown = const Duration(seconds: 5);

  final List<String> labels = [
 "burned socket",
 "damage wire",
 "overloaded socket",
 '0',
 "black smoke",
 "fire1",
 "smoky fire",
  ];

  @override
  void initState() {
    
    super.initState();
    _initAsync();
    
  }

  Future<void> _initAsync() async {
  _setupCamera();
  await loadModel();

  await inferWithImage();


}

  Future<String> loadModel() async {
    final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    String result = await _tfliteService.loadModel();
    if (result.contains("Model loaded")) {
      setState(() {
        _isModelLoaded = true;
      });
    }
    return result;
  }

Future inferWithImage() async {
  try {
    final ByteData data = await rootBundle.load('assets/images/2.jpg');
    final bytes = data.buffer;

    await _tfliteService.runInference(bytes);

    List<double> times = [];

    for (int i = 0; i < 10; i++) {
      final stopwatch = Stopwatch()..start();
      
      await _tfliteService.runInference(bytes);

      stopwatch.stop();
      final t = stopwatch.elapsedMicroseconds / 1000.0; // ms
      times.add(t);

      print("Run ${i + 1}: ${t.toStringAsFixed(3)} ms");
    }

    double avg = times.reduce((a, b) => a + b) / times.length;
    double minTime = times.reduce((a, b) => a < b ? a : b);
    double maxTime = times.reduce((a, b) => a > b ? a : b);

    print("------ Results ------");
    print("Average: ${avg.toStringAsFixed(3)} ms");
    print("Min    : ${minTime.toStringAsFixed(3)} ms");
    print("Max    : ${maxTime.toStringAsFixed(3)} ms");
    print("---------------------");

  } catch (err) {
    print(err);
  }
}


  Future<Location?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );

      return Location(
        type: 'Point',
        coordinates: [position.latitude, position.longitude],
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
  final _secureStorage = const FlutterSecureStorage();
  Future<void> sendDetections() async {
    if(_unsentDetections.isEmpty) return;
    if (isSending) return;
    isSending = true;

    final uri = Uri.parse('https://safemine-backend-production.up.railway.app/detection');

  try {
    final token = await _secureStorage.read(key: 'jwt_token');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final List<DetectionLog> logsToSend = List<DetectionLog>.from(_unsentDetections);

    final body = jsonEncode({
      'detections': logsToSend.map((log) => log.toJson()).toList(),
    });

    final resp = await http
        .post(
          uri,
          headers: headers,
          body: body,
        )
        .timeout(const Duration(seconds: 15)); // increase timeout if needed

    if (resp.statusCode == 200) {
      setState(() {
        _unsentDetections.removeRange(0, logsToSend.length);
      });
    } else {
      _unsentDetections.clear();
    }
  } on TimeoutException catch (e) {
    print('Error sending detections: Timeout - $e');
  } catch (e) {
    print('Error sending detections: $e');
  } finally {
    isSending = false;
  }
  }

  Future<void> mapDetections(List<List<double>> newDetections) async {
    final currentTime = DateTime.now();
    List<DetectionLog> newLogs = [];
    try {
      if (newDetections.isEmpty) {
        print("No detections.");
      } else {
        for (var det in newDetections) {
          if (det[4] > 0.25) {
            int rawClass = det[5].toInt();
            int cls = rawClass % labels.length;
            String label = labels[cls];
            double confidence = det[4];

            final DateTime? lastTime = _lastAlertTimes[label];

            if (lastTime != null &&
                currentTime.difference(lastTime) < alertCooldown) {
              continue;
            }
            _lastAlertTimes[label] = currentTime;

            // Get current location
            final location = await _getCurrentLocation();

            final newLog = DetectionLog(
              label: label,
              timestamp: DateTime.now(),
              confidence: confidence,
              location: location!,
            );
            

            newLogs.add(newLog);
            _unsentDetections.add(newLog);

            final player = AudioPlayer();
            player.play(AssetSource('sounds/alert.wav'));
            Vibration.vibrate(duration: 500);

            sendDetections();

            print(
              "Detected $label (class $rawClass → mapped $cls) "
              "with confidence ${(det[4] * 100).toStringAsFixed(1)}% "
              "at [x1:${det[0]}, y1:${det[1]}, x2:${det[2]}, y2:${det[3]}]"
              "${location != null ? ' | Location: ${location.coordinates}' : ''}",
            );
          }
        }
      }

      setState(() {
        _currentDetections = newDetections;

        if (newLogs.isNotEmpty) {
          _detectionLog.insertAll(0, newLogs);

          if (_detectionLog.length > 50) {
            _detectionLog = _detectionLog.sublist(0, 50);
          }
        }
      });
      if(newLogs.isNotEmpty){
        unawaited(sendDetections());
      }
    } catch (e) {
      print("Error mapping detections: $e");
    }
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      print("camera: $cameras");
      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras.first, ResolutionPreset.max,
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

  int lastInferenceTime = 0;
  bool isProcessing = false;


  Future<void> processCameraImage(CameraImage image) async {
    const int throttleMs = 80;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastInferenceTime < throttleMs) return;
    if (isProcessing) return;

    isProcessing = true;
    lastInferenceTime = now;


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

    } catch (e) {
      print("Error during processing: $e");
    } finally {
      isProcessing = false;
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
                                    padding: const EdgeInsets.fromLTRB(
                                        16.0, 0, 16.0, 16.0),
                                    child: Center(
                                      child: Center(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ImageFiltered(
                                                imageFilter: ImageFilter.blur(
                                                  sigmaX: 10.0,
                                                  sigmaY: 10.0,
                                                ),
                                                child: Image.asset(
                                                  'assets/images/2.jpg',
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Container(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                              ),
                                              Center(
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.white,
                                                    foregroundColor:
                                                        Colors.black,
                                                    elevation: 5,
                                                  ),
                                                  onPressed: () {
                                                    final cameraDescription =
                                                        _controller
                                                            ?.description;

                                                    if (cameraDescription != null &&
                                                    context.mounted) {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          TakePictureScreen(
                                                        camera: cameraDescription,
                                                        onDetections: (detections) {
                                                          mapDetections(detections);
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                }
                                                  },
                                                  child: const Text(
                                                      "Go to Live View"),
                                                ),
                                              ),
                                            ],
                                          ),
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
                                              // TODO: Add navigation or action here
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
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  itemCount: _detectionLog.length,
                                  itemBuilder: (context, index) {
                                    final log = _detectionLog[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10.0),
                                      child: IncidentList(
                                        warnName: log.label,
                                        timeStamp: log.timestamp
                                                .millisecondsSinceEpoch ~/
                                            1000,
                                      ),
                                    );
                                  },
                                ),
                              )
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
