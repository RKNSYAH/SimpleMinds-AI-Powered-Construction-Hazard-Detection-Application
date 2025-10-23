package com.example.safemine
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.HexagonDelegate
import org.tensorflow.lite.support.common.FileUtil
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.safemine/tflite"
    private var interpreter: Interpreter? = null
    private var hexagonDelegate: HexagonDelegate? = null
  override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            
            if (call.method == "loadModel") {
                try {
                    hexagonDelegate = HexagonDelegate(this)
                    val options = Interpreter.Options().addDelegate(hexagonDelegate)
                    
                    val model = FileUtil.loadMappedFile(this, "ConstructionHazardV3.tflite") 
                    
                    interpreter = Interpreter(model, options)
                    result.success("Model loaded with HexagonDelegate. ✅")
                } catch (e: Exception) {
                    // Fallback to CPU if Hexagon fails
                    try {
                        val options = Interpreter.Options()
                        val model = FileUtil.loadMappedFile(this, "ConstructionHazardV3.tflite")
                        interpreter = Interpreter(model, options)
                        result.success("Model loaded with CPU (Hexagon failed: ${e.message})")
                    } catch (e2: Exception) {
                        result.error("LOAD_ERROR", "Failed to load model: ${e2.message}", null)
                    }
                }
            } 
            
            else if (call.method == "runInference") {
                if (interpreter == null) {
                    result.error("INFERENCE_ERROR", "Interpreter is not initialized.", null)
                    return@setMethodCallHandler
                }
                
                val inputBytes = call.argument<ByteArray>("bytes")
                if (inputBytes == null) {
                    result.error("INFERENCE_ERROR", "Input bytes are null.", null)
                    return@setMethodCallHandler
                }
                
                // Prepare Input Buffer (Shape: [1, 3, 640, 640])
                val inputBuffer = ByteBuffer.allocateDirect(1 * 3 * 640 * 640 * 4)
                inputBuffer.order(ByteOrder.nativeOrder())
                inputBuffer.put(inputBytes)
                
                // Prepare Output Buffer (Shape: [1, 300, 6])
                val outputBuffer = ByteBuffer.allocateDirect(1 * 300 * 6 * 4) 
                outputBuffer.order(ByteOrder.nativeOrder())

                try {
                    // Run Inference
                    interpreter?.run(inputBuffer, outputBuffer)

                    // Send results back to Flutter
                    outputBuffer.rewind()
                    val outputArray = FloatArray(1 * 300 * 6)
                    outputBuffer.asFloatBuffer().get(outputArray)
                    
                    result.success(outputArray)

                } catch (e: Exception) {
                    result.error("INFERENCE_ERROR", "Inference failed: ${e.message}", null)
                }
            } 
            
            // --- Handle unknown methods ---
            else {
                result.notImplemented()
            }
        }
    }
    
    override fun onDestroy() {
        interpreter?.close()
        hexagonDelegate?.close()
        super.onDestroy()
    }
}