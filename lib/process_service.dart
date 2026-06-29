import 'dart:async';

import 'package:ericsson/tflite_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';

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

  final rotated = img.copyRotate(img2, angle: 0);
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

        DateTime startTime = DateTime.now();

        final List<List<double>>? output =
            await _tfliteService.runInference(input.buffer);

        DateTime endTime = DateTime.now();

        int durationMicroseconds = endTime.microsecondsSinceEpoch - startTime.microsecondsSinceEpoch;
        double durationMilliseconds = durationMicroseconds / 1000;
        print('Operation took ${durationMilliseconds.toStringAsFixed(3)} ms');

        if (output == null) {
          print("Inference failed or returned null.");
          return null;
        }

        var newDetections = output.where((box) => box[4] > 0.25).toList();

        return newDetections;
      
    } catch (e) {
      print("Error during processing: $e");
    } finally {
      isProcessing = false;
    }
    return null;
  }
  
}