import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'image_filters.dart';       
import 'python_api.dart';          

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImagePickerScreen(),
    );
  }
}

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _imageFile;                         // Original image file
  Uint8List? _originalImageBytes;          // Original raw image bytes
  List<File> _filterHistory = [];          // History of applied filters (files)
  int _currentStep = -1;                   // Index for undo/redo navigation
  double _dividerPosition = 0.5;           // For draggable comparison line
  bool _isLoading = false;                 // Loading state for UI

  final List<String> _filters = [          // List of filter names
    'Grayscale',
    'Sepia',
    'Invert',
    'Blur',
    'Sharpen',
    'EdgeDetection',
    'Emboss',
  ];

  // Opens gallery to pick an image and resets the state
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final bytes = await File(pickedImage.path).readAsBytes();
      setState(() {
        _imageFile = File(pickedImage.path);
        _originalImageBytes = bytes;
        _filterHistory = [];
        _currentStep = -1;
        _dividerPosition = 0.5;
      });
    }
  }

  // Applies a native (C++) filter via FFI and updates history
  void _applyFilter(String filter) async {
    if (_currentImageBytes == null) return;

    setState(() {
      _isLoading = true;
    });

    final resultBytes = await applyImageFilter(_currentImageBytes!, filter);
    final tempPath =
        '${Directory.systemTemp.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filteredFile = await File(tempPath).writeAsBytes(resultBytes);

    setState(() {
      // Remove forward history if we're in the middle
      if (_currentStep < _filterHistory.length - 1) {
        _filterHistory = _filterHistory.sublist(0, _currentStep + 1);
      }
      _filterHistory.add(filteredFile);
      _currentStep++;
      _dividerPosition = 0.5;
      _isLoading = false;
    });
  }

  // Applies AI-based filter via FastAPI and updates history
  Future<void> _applyAiFilter() async {
    if (_currentImageBytes == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await sendToPythonApi(_currentImageBytes!); // use current state, not original
      final tempPath =
          '${Directory.systemTemp.path}/ai_processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filteredFile = await File(tempPath).writeAsBytes(result);

      setState(() {
        if (_currentStep < _filterHistory.length - 1) {
          _filterHistory = _filterHistory.sublist(0, _currentStep + 1);
        }
        _filterHistory.add(filteredFile);
        _currentStep++;
        _dividerPosition = 0.5;
      });
    } catch (e) {
      print("Python API error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Gets image bytes at current step
  Uint8List? get _currentImageBytes {
    if (_currentStep == -1) return _originalImageBytes;
    return _filterHistory[_currentStep].readAsBytesSync();
  }

  // Gets file at current step
  File? get _currentImageFile {
    if (_currentStep == -1) return null;
    return _filterHistory[_currentStep];
  }

  // Step back in history
  void _goBack() {
    if (_currentStep > -1) {
      setState(() {
        _currentStep--;
        _dividerPosition = 0.5;
      });
    }
  }

  // Step forward in history
  void _goForward() {
    if (_currentStep < _filterHistory.length - 1) {
      setState(() {
        _currentStep++;
        _dividerPosition = 0.5;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image Filter App")),
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          // Image preview and filter comparison view
          Expanded(
            child: Center(
              child: _imageFile == null
                  ? const Text("No image selected.")
                  : Stack(
                      children: [
                        // Original image (always full width)
                        Image.file(_imageFile!, fit: BoxFit.contain, width: double.infinity),
                        
                        // Filtered image overlay with draggable comparison
                        if (_currentStep >= 0)
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                return Stack(
                                  children: [
                                    // Show part of filtered image (left side only)
                                    ClipRect(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _dividerPosition,
                                        child: Image.file(
                                          _currentImageFile!,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                        ),
                                      ),
                                    ),
                                    // Divider handle for dragging
                                    Positioned(
                                      left: (width * _dividerPosition - 20).clamp(0.0, width - 40),
                                      top: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onHorizontalDragUpdate: (details) {
                                          setState(() {
                                            _dividerPosition += details.delta.dx / width;
                                            _dividerPosition = _dividerPosition.clamp(0.0, 1.0);
                                          });
                                        },
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Circular draggable button
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(Icons.compare_arrows, color: Colors.blueAccent),
                                            ),
                                            const SizedBox(height: 8),
                                            // Vertical line
                                            Container(
                                              width: 2,
                                              height: 200,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // Show progress spinner if loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.undo),
                  label: const Text("Undo"),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Image"),
                ),
                OutlinedButton.icon(
                  onPressed: _goForward,
                  icon: const Icon(Icons.redo),
                  label: const Text("Redo"),
                ),
              ],
            ),
          ),

          // AI filter button (calls FastAPI)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ElevatedButton.icon(
              onPressed: _applyAiFilter,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text("Apply AI Filter"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),

          // Native filter buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            color: Colors.grey[300],
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: _filters.map((filter) {
                return ElevatedButton(
                  onPressed: () => _applyFilter(filter),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  child: Text(filter),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
