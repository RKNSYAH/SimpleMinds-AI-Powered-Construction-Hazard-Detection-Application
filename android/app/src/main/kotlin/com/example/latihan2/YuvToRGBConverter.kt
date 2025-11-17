package com.example.safemine

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.YuvImage
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

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