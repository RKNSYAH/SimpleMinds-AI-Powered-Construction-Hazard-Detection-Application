package com.example.safemine

import io.flutter.plugins.QnnInference
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.FileUtil
import org.tensorflow.lite.gpu.GpuDelegate
import org.tensorflow.lite.nnapi.NnApiDelegate
import java.nio.ByteBuffer
import java.nio.ByteOrder
import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageFormat
import androidx.annotation.NonNull
import androidx.camera.core.ImageProxy
import android.renderscript.*
// import kotlinx.coroutines.CoroutineScope
// import kotlinx.coroutines.Dispatchers
// import kotlinx.coroutines.launch
// import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.safemine/tflite"
    private var interpreter: Interpreter? = null

    private fun saveDebugBitmap(context: Context, data: ByteArray, width: Int, height: Int) {
    try {
        // 1. Wrap as FloatBuffer to read floats easily
        val floatBuffer = ByteBuffer.wrap(data)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()

        // Calculate the size of one color plane (e.g., 640 * 640)
        val planeSize = width * height
        
        // Safety check
        if (floatBuffer.capacity() < planeSize * 3) {
            Log.e("SaveDebug", "Buffer too small! Expected ${planeSize * 3} floats, got ${floatBuffer.capacity()}")
            return
        }

        val pixels = IntArray(planeSize)

        for (i in 0 until planeSize) {
            // 2. READ PLANAR DATA (NCHW)
            // Red is at index i
            // Green is at index i + (640*640)
            // Blue is at index i + (2 * 640*640)
            val rFloat = floatBuffer.get(i)
            val gFloat = floatBuffer.get(i + planeSize)
            val bFloat = floatBuffer.get(i + (planeSize * 2))

            // 3. Scale 0.0-1.0 back to 0-255
            val r = (rFloat * 255).toInt().coerceIn(0, 255)
            val g = (gFloat * 255).toInt().coerceIn(0, 255)
            val b = (bFloat * 255).toInt().coerceIn(0, 255)

            pixels[i] = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
        }

        val bitmap = Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)

        val fileName = "debug_planar_${System.currentTimeMillis()}.jpg"
        val file = java.io.File(context.getExternalFilesDir(null), fileName)
        val outStream = java.io.FileOutputStream(file)
        
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outStream)
        outStream.flush()
        outStream.close()

        Log.i("SaveDebug", "✅ Planar Image saved: ${file.absolutePath}")

    } catch (e: Exception) {
        Log.e("SaveDebug", "❌ Failed to save image: ${e.message}", e)
    }
}


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
                    // Use QnnInference helper that attempts QNN delegate and falls back to CPU.
                    interpreter = QnnInference.createInterpreter(this, "newoptimized.tflite")
                    result.success("Model loaded (QNN delegate or fallback).")
                } catch (e: Exception) {
                    result.error("LOAD_ERROR", "Failed to load model: ${e.message}", null)
                }
            } 
            
            else if (call.method == "runInference") {
                if (interpreter == null) {
                    result.error("INFERENCE_ERROR", "Interpreter is not initialized.", null)
                    return@setMethodCallHandler
                }
                
                val inputBytes = call.argument<ByteArray>("bytes")
                if (inputBytes == null) {
                    result.error("INFERENCE_ERROR", "Input bytes are missing.", null)
                    return@setMethodCallHandler
                }

                val inputBuffer = ByteBuffer.allocateDirect(1 * 3 * 640 * 640 * 4)
                inputBuffer.order(ByteOrder.nativeOrder())
                inputBuffer.put(inputBytes)
                inputBuffer.rewind()

    //             if (inputBytes != null) {
    //     // Save the image to check strictly what the model sees
    //     saveDebugBitmap(this, inputBytes, 640, 640) 
    // }
                
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

    companion object {
        init {
            try {
                Log.i("MainActivity", "Before loadLibrary")
                System.loadLibrary("QnnSystem")
                Log.i("MainActivity", "✅ Successfully loaded QnnSystem library")
            } catch (e: UnsatisfiedLinkError) {
                Log.e("MainActivity", "❌ Failed to load QnnSystem library: ${e.message}", e)
            } catch (e: Exception) {
                Log.e("MainActivity", "❌ Unexpected error loading QnnSystem: ${e.message}", e)
            }
        }
    }   

    
    override fun onDestroy() {
        interpreter?.close()
        QnnInference.close()
        super.onDestroy()
    }
}