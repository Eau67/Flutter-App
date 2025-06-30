# 📸 Image Filter App with Flutter, C++ (FFI), and Python FastAPI AI Filter

This cross-platform image filtering app allows users to apply native C++ filters or advanced AI-style filters using a Python FastAPI backend. The UI is built using Flutter and provides an interactive before/after comparison slider.

---

## ✨ Features

- Pick an image from your gallery
- Apply native filters (C++ via FFI): Grayscale, Sepia, Invert, Blur, Sharpen, Edge Detection, Emboss
- Apply AI-style filters (FastAPI + OpenCV Python backend)
- Navigate through filter history (Undo / Redo)
- Compare original vs. filtered with a draggable slider

---

## 📁 Project Structure

```
image_filter_app/
├── ai_server.py                         # FastAPI image processing backend
├── lib/
│   ├── main.dart                        # Flutter UI code
│   ├── image_filters.dart               # Dart FFI integration with C++ filters
│   ├── python_api.dart                  # HTTP client to communicate with Python FastAPI
├── build/
│   └── windows/ 
|       └── runner/
|            └── Debug/
|                └──ImageFiltersCpp.dll  # Compiled C++ DLL (for Windows only)
```

---

## 🚀 Setup Guide

### 1. Flutter App Setup

#### ✅ Prerequisites:
- Flutter SDK installed: https://docs.flutter.dev/get-started/install
- Visual Studio (for building C++ DLLs if you need to modify)
- Android/iOS emulator or physical device

#### 🔧 Steps:

```bash
git clone <your-repo-url>
cd image_filter_app
flutter pub get
```

Make sure the following packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.7
  image: ^4.0.15
  ffi: ^2.0.2
  http: ^0.13.0
  http_parser: ^4.0.2
```

Ensure the compiled `ImageFiltersCpp.dll` is located in your project root or referenced correctly in `image_filters.dart`.

#### ▶️ Run App:

```bash
flutter run
```

---

### 2. Native C++ Filter Library (Windows Only)

#### ✅ Prerequisites:

- Visual Studio with C++ Desktop Development workload
- OpenCV installed and environment variables set

#### 📦 Compile the DLL:

1. Create a new DLL project in Visual Studio
2. Add the `apply_filter` and `free_image` functions
3. Link against OpenCV libraries
4. Build and copy `ImageFiltersCpp.dll` into your Flutter project

> 📝 The `image_filters.dart` file uses FFI to load this DLL:
```dart
DynamicLibrary.open("ImageFiltersCpp.dll");
```

---

### 3. Python FastAPI Server

#### ✅ Prerequisites:
- Python 3.8+
- Install required packages:

```bash
pip install fastapi uvicorn opencv-python numpy python-multipart
```

#### ▶️ Run the server:

```bash
cd python_server
uvicorn main:app --reload
```

Make sure it runs at: `http://127.0.0.1:8000/process-image/`

If running on a physical device, use your PC's IP address and update the Flutter code accordingly:
```dart
Uri.parse('http://<your-ip>:8000/process-image/')
```

---

## 🧪 Usage Guide

1. Launch the Flutter app
2. Click **"Pick Image"** and select one from gallery
3. Use the filter buttons to apply transformations
4. Drag the circular slider to compare original vs. filtered image
5. Use **Undo** and **Redo** to navigate through filter steps
6. Press **Apply AI Filter** to send the image to the Python server

---

## 🔍 Filter Descriptions

| Filter Name     | Description                            |
|----------------|----------------------------------------|
| Grayscale       | Converts image to black & white       |
| Sepia           | Applies a warm brown vintage effect    |
| Invert          | Inverts all pixel colors               |
| Blur            | Applies Gaussian blur                  |
| Sharpen         | Sharpens edges using convolution       |
| EdgeDetection   | Uses Canny algorithm for edge finding  |
| Emboss          | Highlights edges with emboss effect    |
| AI Filter       | Rotates hue channel via Python/OpenCV  |

---

## 💡 Notes

- **Windows only**: The current C++ FFI setup supports Windows due to `.dll` usage. For cross-platform support, compile `.so` (Linux/Android) or `.dylib` (macOS/iOS).
- The Python backend runs locally. For production, consider deploying it on a remote server or container.
- Make sure firewall allows connections to your FastAPI port (8000 by default).

---

## 📷 Demo

> 📝 You can add a short `.mp4` video demo here by uploading it elsewhere (e.g., [Imgur](https://imgur.com) or [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)) and embedding:

```markdown
![Demo](https://your-url.com/demo.gif)
```

---
