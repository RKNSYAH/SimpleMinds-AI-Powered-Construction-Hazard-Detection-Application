package io.flutter.plugins;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.util.Log;
import android.util.Pair;

import com.qualcomm.qti.QnnDelegate;

import org.tensorflow.lite.Delegate;
import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.gpu.GpuDelegate;
import org.tensorflow.lite.gpu.GpuDelegateFactory;

import java.io.FileInputStream;
import java.io.IOException;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.security.DigestInputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

public final class QnnInference {
    private static final String TAG = "QnnInference";

    private static Interpreter tfliteInterpreter = null;
    private static Map<DelegateType, Delegate> delegatesMap = null;

    // Private constructor so no one can instantiate this utility class
    private QnnInference() {}

    public static Interpreter createInterpreter(Context context, String modelAssetPath) {
        if (tfliteInterpreter != null) return tfliteInterpreter;

        MappedByteBuffer modelBuffer;
        String modelIdentifier;
        try {
            Pair<MappedByteBuffer, String> modelData = loadModelFile(context.getAssets(), modelAssetPath);
            modelBuffer = modelData.first;
            modelIdentifier = modelData.second;
        } catch (Exception e) {
            Log.e(TAG, "Failed to load model file: " + modelAssetPath, e);
            throw new RuntimeException(e);
        }

        DelegateType[][] delegatePriorityOrder = new DelegateType[][]{
            {DelegateType.QNN_NPU},
            {DelegateType.GPUv2},
            {},
        };

        String nativeLibraryDir = context.getApplicationInfo().nativeLibraryDir;
        String cacheDir = context.getCacheDir().getAbsolutePath();

        try {
            Pair<Interpreter, Map<DelegateType, Delegate>> interpreterData =
                    CreateInterpreterAndDelegatesFromOptions(
                            modelBuffer,
                            delegatePriorityOrder,
                            -1,
                            nativeLibraryDir,
                            cacheDir,
                            modelIdentifier
                    );

            tfliteInterpreter = interpreterData.first;
            delegatesMap = interpreterData.second;

            Log.i(TAG, "Interpreter created successfully with delegates: " + (delegatesMap.isEmpty() ? "CPU" : delegatesMap.keySet().toString()));
            return tfliteInterpreter;

        } catch (Exception e) {
            Log.e(TAG, "Failed to create any interpreter: " + e.getMessage(), e);
            close(); // Clean up
            throw new RuntimeException(e);
        }
    }

    /**
     * This closes the interpreter and all active delegates.
     */
    public static void close() {
        if (tfliteInterpreter != null) {
            tfliteInterpreter.close();
            tfliteInterpreter = null;
        }

        if (delegatesMap != null) {
            for (Delegate delegate : delegatesMap.values()) {
                delegate.close();
            }
            delegatesMap.clear();
            delegatesMap = null;
        }
    }

    private enum DelegateType {
        GPUv2,
        QNN_NPU,
    }

    private static Pair<Interpreter, Map<DelegateType, Delegate>> CreateInterpreterAndDelegatesFromOptions(
            MappedByteBuffer tfLiteModel,
            DelegateType[][] delegatePriorityOrder,
            int numCPUThreads,
            String nativeLibraryDir,
            String cacheDir,
            String modelIdentifier) {

        Map<DelegateType, Delegate> delegates = new HashMap<>();
        Set<DelegateType> attemptedDelegates = new HashSet<>();

        for (DelegateType[] delegatesToRegister : delegatePriorityOrder) {
            Arrays.stream(delegatesToRegister)
                    .filter(delegateType -> !attemptedDelegates.contains(delegateType))
                    .forEach(delegateType -> {
                        Delegate delegate = CreateDelegate(delegateType, nativeLibraryDir, cacheDir, modelIdentifier);
                        if (delegate != null) {
                            delegates.put(delegateType, delegate);
                        }
                        attemptedDelegates.add(delegateType);
                    });

            if (Arrays.stream(delegatesToRegister).anyMatch(x -> !delegates.containsKey(x))) {
                continue;
            }

            Interpreter interpreter = CreateInterpreterFromDelegates(
                    Arrays.stream(delegatesToRegister).map(
                            delegateType -> new Pair<>(delegateType, delegates.get(delegateType))
                    ).toArray(Pair[]::new),
                    numCPUThreads,
                    tfLiteModel
            );

            if (interpreter == null) {
                continue;
            }

            delegates.keySet().stream()
                    .filter(delegateType -> Arrays.stream(delegatesToRegister).noneMatch(d -> d == delegateType))
                    .collect(Collectors.toSet())
                    .forEach(unusedDelegateType -> {
                        Objects.requireNonNull(delegates.remove(unusedDelegateType)).close();
                    });

            return new Pair<>(interpreter, delegates);
        }

        throw new RuntimeException("Unable to create an interpreter of any kind for the provided model. See log for details.");
    }

    private static Interpreter CreateInterpreterFromDelegates(
            final Pair<DelegateType, Delegate>[] delegates,
            int numCPUThreads,
            MappedByteBuffer tfLiteModel) {
        Interpreter.Options tfLiteOptions = new Interpreter.Options();
        tfLiteOptions.setRuntime(Interpreter.Options.TfLiteRuntime.FROM_APPLICATION_ONLY);
        tfLiteOptions.setAllowBufferHandleOutput(true);
        tfLiteOptions.setUseNNAPI(false);
        tfLiteOptions.setNumThreads(numCPUThreads);
        tfLiteOptions.setUseXNNPACK(true); // Fall back to XNNPack (fast CPU)

        Arrays.stream(delegates).forEach(x -> tfLiteOptions.addDelegate(x.second));

        try {
            Interpreter i = new Interpreter(tfLiteModel, tfLiteOptions);
            i.allocateTensors();
            return i;
        } catch (Exception e) {
            List<String> enabledDelegates = Arrays.stream(delegates).map(x -> x.first.name()).collect(Collectors.toCollection(ArrayList::new));
            enabledDelegates.add("XNNPack");
            Log.e(TAG, "Failed to Load Interpreter with delegates {" + String.join(", ", enabledDelegates) + "} | " + e.getMessage());
            return null;
        }
    }

    private static Pair<MappedByteBuffer, String> loadModelFile(AssetManager assets, String modelFilename)
            throws IOException, NoSuchAlgorithmException {
        AssetFileDescriptor fileDescriptor = assets.openFd(modelFilename);
        MappedByteBuffer buffer;
        String hash;

        try (FileInputStream inputStream = new FileInputStream(fileDescriptor.getFileDescriptor())) {
            FileChannel fileChannel = inputStream.getChannel();
            long startOffset = fileDescriptor.getStartOffset();
            long declaredLength = fileDescriptor.getDeclaredLength();

            buffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength);

            MessageDigest hashDigest = MessageDigest.getInstance("MD5");
            fileChannel.position(startOffset);
            
            try (FileInputStream hashInputStream = new FileInputStream(fileDescriptor.getFileDescriptor())) {
                hashInputStream.skip(startOffset);
                try (DigestInputStream dis = new DigestInputStream(hashInputStream, hashDigest)) {
                    byte[] data = new byte[8192];
                    long bytesToRead = declaredLength;
                    while (bytesToRead > 0) {
                        int bytesRead = dis.read(data, 0, (int) Math.min(data.length, bytesToRead));
                        if (bytesRead == -1) break;
                        bytesToRead -= bytesRead;
                    }
                }
            }

            StringBuilder hex = new StringBuilder();
            for (byte b : hashDigest.digest()) {
                hex.append(String.format("%02x", b));
            }
            hash = hex.toString();
        }

        return new Pair<>(buffer, hash);
    }

    private static Delegate CreateDelegate(DelegateType delegateType, String nativeLibraryDir, String cacheDir, String modelIdentifier) {
        if (delegateType == DelegateType.GPUv2) {
            return CreateGPUv2Delegate(cacheDir, modelIdentifier);
        }
        if (delegateType == DelegateType.QNN_NPU) {
            return CreateQNN_NPUDelegate(nativeLibraryDir, cacheDir, modelIdentifier);
        }
        throw new RuntimeException("Delegate creation not implemented for type: " + delegateType.name());
    }


    private static Delegate CreateQNN_NPUDelegate(String nativeLibraryDir, String cacheDir, String modelIdentifier) {
        QnnDelegate.Options qnnOptions = new QnnDelegate.Options();
        qnnOptions.setSkelLibraryDir(nativeLibraryDir);
        qnnOptions.setLogLevel(QnnDelegate.Options.LogLevel.LOG_LEVEL_WARN);
        qnnOptions.setCacheDir(cacheDir);
        qnnOptions.setModelToken(modelIdentifier);

        
        boolean hasHTP = QnnDelegate.checkCapability(QnnDelegate.Capability.HTP_RUNTIME_FP16) 
                      || QnnDelegate.checkCapability(QnnDelegate.Capability.HTP_RUNTIME_QUANTIZED);

        if (hasHTP) {
            Log.i(TAG, "✅ Detected HTP Capability. Setting Backend to HTP.");
            qnnOptions.setBackendType(QnnDelegate.Options.BackendType.HTP_BACKEND);
            qnnOptions.setHtpUseConvHmx(QnnDelegate.Options.HtpUseConvHmx.HTP_CONV_HMX_ON);
            qnnOptions.setHtpPerformanceMode(QnnDelegate.Options.HtpPerformanceMode.HTP_PERFORMANCE_BURST);
            
            if (QnnDelegate.checkCapability(QnnDelegate.Capability.HTP_RUNTIME_FP16)) {
                qnnOptions.setHtpPrecision(QnnDelegate.Options.HtpPrecision.HTP_PRECISION_FP16);
            }
        } 
        else if (QnnDelegate.checkCapability(QnnDelegate.Capability.DSP_RUNTIME)) {
            Log.i(TAG, "⚠️ HTP not found. Falling back to legacy DSP.");
            qnnOptions.setBackendType(QnnDelegate.Options.BackendType.DSP_BACKEND);
            qnnOptions.setDspOptions(QnnDelegate.Options.DspPerformanceMode.DSP_PERFORMANCE_BURST, QnnDelegate.Options.DspPdSession.DSP_PD_SESSION_ADAPTIVE);
        } 
        else {
            Log.e(TAG, "❌ No NPU (HTP or DSP) backend supported on this device.");
            return null;
        }

        try {
            return new QnnDelegate(qnnOptions);
        } catch (Exception e) {
            Log.e(TAG, "QNN backend failed to initialize: " + e.getMessage());
            return null;
        }
    }

    private static Delegate CreateGPUv2Delegate(String cacheDir, String modelIdentifier) {
        GpuDelegateFactory.Options gpuOptions = new GpuDelegateFactory.Options();
        gpuOptions.setInferencePreference(GpuDelegateFactory.Options.INFERENCE_PREFERENCE_SUSTAINED_SPEED);
        gpuOptions.setPrecisionLossAllowed(true);
        gpuOptions.setSerializationParams(cacheDir, modelIdentifier);

        try {
            return new GpuDelegate(gpuOptions);
        } catch (Exception e) {
            Log.e(TAG, "GPUv2 delegate failed to initialize: " + e.getMessage());
            return null;
        }
    }
}