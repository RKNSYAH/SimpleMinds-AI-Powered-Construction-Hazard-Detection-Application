package com.example.safemine

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.YuvImage
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

object ImageUtils {

    fun yuvToRgb(context: Context, yuvImage: ByteArray, width: Int, height: Int): Bitmap {
        // Convert NV21 (YUV) to JPEG
        val yuv = YuvImage(yuvImage, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuv.compressToJpeg(android.graphics.Rect(0, 0, width, height), 100, out)
        val jpegBytes = out.toByteArray()

        // Decode JPEG to RGB Bitmap
        return android.graphics.BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
    }

    fun saveBitmapToJpeg(context: Context, bitmap: Bitmap, filename: String) {
    try {
        val file = java.io.File(context.getExternalFilesDir(null), "$filename.jpg")
        val outputStream = java.io.FileOutputStream(file)
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
        outputStream.flush()
        outputStream.close()
        android.util.Log.d("ImageUtils", "Saved image to: ${file.absolutePath}")
    } catch (e: Exception) {
        android.util.Log.e("ImageUtils", "Failed to save image: ${e.message}")
    }
}

}

fun Bitmap.toFloatByteBuffer(): ByteBuffer {
    val width = width
    val height = height
    val pixels = IntArray(width * height)
    getPixels(pixels, 0, width, 0, 0, width, height)

    val inputBuffer = ByteBuffer.allocateDirect(1 * width * height * 3 * 4)
    inputBuffer.order(ByteOrder.nativeOrder())

    for (pixel in pixels) {
        val r = ((pixel shr 16) and 0xFF) / 255.0f
        val g = ((pixel shr 8) and 0xFF) / 255.0f
        val b = (pixel and 0xFF) / 255.0f
        inputBuffer.putFloat(r)
        inputBuffer.putFloat(g)
        inputBuffer.putFloat(b)
    }

    inputBuffer.rewind()
    return inputBuffer
}