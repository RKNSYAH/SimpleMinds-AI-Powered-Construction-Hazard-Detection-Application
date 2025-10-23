import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class TFLiteService {
  static const platform = MethodChannel('com.example.safemine/tflite');
  
  Future<String> loadModel() async {
    try {
      final String result = await platform.invokeMethod('loadModel');
      return result;
    } on PlatformException catch (e) {
      return "Failed to load model: '${e.message}'.";
    }
  }

  Future<List<List<double>>?> runInference(ByteBuffer preprocessedBytes) async {
    try {
      final List<dynamic>? result = await platform.invokeMethod('runInference', {
        'bytes': preprocessedBytes.asUint8List(),
      });

      if (result == null) return null;

      final floatList = result.cast<double>();
      final List<List<double>> detections = [];
      
      const int numDetections = 300;
      const int numValues = 6;
      
      for (int i = 0; i < numDetections; i++) {
        detections.add(
          floatList.sublist(i * numValues, (i + 1) * numValues)
        );
      }
      return detections;
      
    } on PlatformException catch (e) {
      print("Failed to run inference: '${e.message}'.");
      return null;
    }
  }
}