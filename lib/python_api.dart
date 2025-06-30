import 'package:http/http.dart' as http;         
import 'package:http_parser/http_parser.dart';   
import 'dart:typed_data';                        

// Sends image bytes to Python server and returns processed image bytes
Future<Uint8List> sendToPythonApi(Uint8List imageBytes) async {
  var uri = Uri.parse('http://127.0.0.1:8000/process-image/');
  var request = http.MultipartRequest('POST', uri);

  // Attach image as multipart form data
  request.files.add(http.MultipartFile.fromBytes(
    'file',
    imageBytes,
    filename: 'image.jpg',
    contentType: MediaType('image', 'jpeg'),
  ));

  // Send request and handle response
  var response = await request.send();

  if (response.statusCode == 200) {
    return await response.stream.toBytes();
  } else {
    throw Exception("Failed to process image from API.");
  }
}
