import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:ericsson/process_service.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
    this.onDetections,
  });

  final CameraDescription camera;
  final ValueChanged<List<List<double>>>? onDetections; // <-- callback

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
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

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ProcessService _processService = ProcessService();

  bool _isProcessingFrame = false;
  bool _streamStarted = false;

  // store detections for the painter: each detection is [x1,y1,x2,y2,score,class]
  List<List<double>> _detections = [];

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.veryHigh,
    );

    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) return;
      if (!_streamStarted) {
        _streamStarted = true;
        _controller.startImageStream((CameraImage image) async {
          if (_isProcessingFrame) return;
          _isProcessingFrame = true;
          try {
            final List<List<double>>? result =
                await _processService.processCameraImage(image);
            if (!mounted) return;
            final detections = result ?? <List<double>>[];
            setState(() {
              _detections = detections;
            });
            // send detections back to caller
            if (widget.onDetections != null) {
              widget.onDetections!(detections);
            }
          } catch (e) {
            // ignore individual-frame errors
            setState(() => _detections = <List<double>>[]);
          } finally {
            _isProcessingFrame = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // Restore system UI and orientations when leaving.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Dispose of the controller when the widget is disposed.
    if (_controller.value.isStreamingImages) {
      _controller.stopImageStream();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return WillPopScope(
              onWillPop: () async {
                Navigator.of(context).popUntil((route) => route.isFirst);
                return false;
              },
              child: Stack(
                children: [
                  // camera preview
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    ),
                  ),

                  // overlay painter sized to the actual preview box
                  Positioned.fill(
                    child: LayoutBuilder(builder: (context, constraints) {
                      final containerSize =
                          Size(constraints.maxWidth, constraints.maxHeight);
                      final previewAspect = _controller.value.aspectRatio;

                      double previewWidth = containerSize.width;
                      double previewHeight = previewWidth / previewAspect;
                      if (previewHeight > containerSize.height) {
                        previewHeight = containerSize.height;
                        previewWidth = previewHeight * previewAspect;
                      }

                      final dx = (containerSize.width - previewWidth) / 2;
                      final dy = (containerSize.height - previewHeight) / 2;

                      // input to model was resized to 640x640, scale detections to preview size
                      final scale = previewWidth / 720.0;

                      return Stack(
                        children: [
                          Positioned(
                            left: dx,
                            top: dy,
                            width: previewWidth,
                            height: previewHeight,
                            child: CustomPaint(
                              painter: DetectionPainter(
                                detections: _detections,
                                scale: scale,
                                flipHorizontally:
                                    widget.camera.lensDirection ==
                                        CameraLensDirection.front,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  // back button
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
