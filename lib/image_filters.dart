import 'dart:ffi';        
import 'dart:isolate';    
import 'dart:typed_data'; 
import 'dart:io';         
import 'package:ffi/ffi.dart';

// Load the native C++ DLL based on platform
final DynamicLibrary nativeLib = Platform.isWindows
    ? DynamicLibrary.open("ImageFiltersCpp.dll")
    : throw UnsupportedError("Only Windows is supported here.");

// FFI type definitions for the native filter function
typedef ApplyFilterNative = Void Function(
    Pointer<Uint8>, Int32, Pointer<Utf8>,
    Pointer<Pointer<Uint8>>, Pointer<Int32>);

// Dart equivalent of the FFI function
typedef ApplyFilterDart = void Function(
    Pointer<Uint8>, int, Pointer<Utf8>,
    Pointer<Pointer<Uint8>>, Pointer<Int32>);

// FFI type definitions for the memory freeing function
typedef FreeImageNative = Void Function(Pointer<Uint8>);
typedef FreeImageDart = void Function(Pointer<Uint8>);

// Bind the native functions to Dart
final applyFilter = nativeLib
    .lookup<NativeFunction<ApplyFilterNative>>('apply_filter')
    .asFunction<ApplyFilterDart>();

final freeImage = nativeLib
    .lookup<NativeFunction<FreeImageNative>>('free_image')
    .asFunction<FreeImageDart>();

// Simple task class to hold filter requests
class FilterTask {
  final Uint8List imageBytes; // Original image bytes
  final String filter;        // Filter name

  FilterTask(this.imageBytes, this.filter);
}

// Isolate entry function – receives a SendPort, listens for filter jobs
void filterIsolateEntryPoint(SendPort sendPort) async {
  final port = ReceivePort();       // Create a port for this isolate
  sendPort.send(port.sendPort);     // Return the new SendPort to the parent

  await for (var message in port) {
    if (message is Map) {
      final FilterTask task = message['task'];
      final SendPort replyPort = message['port'];

      try {
        // Apply filter in this isolate (blocking operation)
        final result = _applyImageFilter(task.imageBytes, task.filter);
        replyPort.send(result);
      } catch (e) {
        replyPort.send(e);
      }
    }
  }
}

// Core FFI function (runs in isolate)
// Converts Dart data to C pointers, calls C++, retrieves and returns result
Uint8List _applyImageFilter(Uint8List imageBytes, String filter) {
  // Allocate and copy input bytes
  final inputPtr = calloc<Uint8>(imageBytes.length);
  inputPtr.asTypedList(imageBytes.length).setAll(0, imageBytes);

  // Convert Dart String to C UTF-8 pointer
  final filterPtr = filter.toNativeUtf8();

  // Allocate output pointers for the native function to fill
  final outPtrPtr = calloc<Pointer<Uint8>>();
  final outLenPtr = calloc<Int32>();

  // Call the C++ function via FFI
  applyFilter(inputPtr, imageBytes.length, filterPtr, outPtrPtr, outLenPtr);

  // Convert output to Dart Uint8List
  final outLen = outLenPtr.value;
  final outData = outPtrPtr.value.asTypedList(outLen);
  final result = Uint8List.fromList(outData);

  // Free native memory
  freeImage(outPtrPtr.value); // Use the C++ free function
  calloc.free(inputPtr);
  calloc.free(filterPtr);
  calloc.free(outPtrPtr);
  calloc.free(outLenPtr);

  return result;
}

// Public async API – spawns an isolate to apply filter without blocking UI
Future<Uint8List> applyImageFilter(Uint8List imageBytes, String filter) async {
  final receivePort = ReceivePort();

  // Start isolate and get its send port
  final isolate = await Isolate.spawn(filterIsolateEntryPoint, receivePort.sendPort);
  final sendPort = await receivePort.first as SendPort;

  // Prepare response port to receive result
  final responsePort = ReceivePort();

  // Send task to isolate
  sendPort.send({
    'task': FilterTask(imageBytes, filter),
    'port': responsePort.sendPort,
  });

  // Await result from isolate
  final result = await responsePort.first;

  // Clean up isolate
  isolate.kill(priority: Isolate.immediate);

  // Propagate exception if any
  if (result is Exception) {
    throw result;
  }

  return result as Uint8List;
}
