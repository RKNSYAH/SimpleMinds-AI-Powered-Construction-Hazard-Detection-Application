import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:ericsson/home.dart';
import 'package:ericsson/tflite_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ProcessService {

  final TFLiteService _tfliteService = TFLiteService();

  int lastInferenceTime = 0;
  bool isProcessing = false;

  Future<List<List<double>>?> processCameraImage(CameraImage image) async {
    const int throttleMs = 400;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastInferenceTime < throttleMs) return null;
    if (isProcessing) return null;

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

        final Float32List input =
            await compute(_preprocessInIsolate, isolateData);

        final List<List<double>>? output =
            await _tfliteService.runInference(input.buffer);

        if (output == null) {
          print("Inference failed or returned null.");
        }

        for (var box in output!) {
          print(box);
        }

        var newDetections = output.where((box) => box[4] > 0.25).toList();

        List<DetectionLog> newLogs = [];

        final currentTime = DateTime.now();

        return newDetections;
      
    } catch (e) {
      print("Error during processing: $e");
    } finally {
      isProcessing = false;
    }
  }
  
}