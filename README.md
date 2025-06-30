# Image Filter App with Flutter, C++ (OpenCV), and Python API

This is a Flutter-based image filtering application that integrates with:

* A native C++ image filter library using OpenCV (via Dart FFI)
* A Python FastAPI backend for AI-based image processing

## Table of Contents

* [Project Structure](#project-structure)
* [Setup Instructions](#setup-instructions)

  * [1. Flutter App](#1-flutter-app)
  * [2. C++ Native Filter Library](#2-c-native-filter-library)
  * [3. Python FastAPI Server](#3-python-fastapi-server)
* [Usage](#usage)
* [Available Filters](#available-filters)

---

## Project Structure

```
main_app/
├── lib/
│   ├── main.dart              # Main Flutter UI and logic
│   ├── image_filters.dart     # Dart FFI + isolate logic to call C++ filters
│   └── python_api.dart        # HTTP request to send image to Python server
├── ImageFiltersCpp.dll        # Compiled C++ DLL (for Windows)
├── cpp/                       # C++ source code
│   └── image_filter.cpp       # OpenCV filters
├── python_server/
│   └── main.py                # FastAPI app for AI filter
└── pubspec.yaml               # Flutter dependencies
```

---

## Setup Instructions

### 1. Flutter App

#### Requirements:

* Flutter SDK installed
* VS Code or Android Studio (with Flutter & Dart plugins)

#### Steps:

1. Clone the repository:

```bash
git clone https://github.com/yourusername/your-repo.git
cd your-repo/main_app
```

2. Install dependencies:

```bash
flutter pub get
```

3. Ensure `ImageFiltersCpp.dll` is located in the root of the project.

   * If not, compile it from the `cpp` source code (see below).

4. Run the Flutter app (e.g., on Windows desktop):

```bash
flutter run -d windows
```

> 💡 To run on Android, switch to an emulator or real device and ensure C++ FFI is not Windows-specific.

---

### 2. C++ Native Filter Library

#### Requirements:

* OpenCV installed
* CMake or Visual Studio with C++ support

#### Build Steps (Windows):

1. Open the `cpp/` directory in Visual Studio.
2. Add `image_filter.cpp` as a source file.
3. Link against OpenCV.
4. Compile to produce `ImageFiltersCpp.dll`.

**Filters Supported:** Grayscale, Sepia, Invert, Blur, Sharpen, EdgeDetection, Emboss

> The DLL is loaded dynamically in Dart via `DynamicLibrary.open("ImageFiltersCpp.dll")`.

---

### 3. Python FastAPI Server

#### Requirements:

* Python 3.7+
* pip

#### Installation:

```bash
cd python_server
pip install fastapi uvicorn opencv-python numpy
```

#### Run the server:

```bash
uvicorn main:app --reload
```

Server will run on `http://127.0.0.1:8000/process-image/`

#### Filter Used:

* A **cartoon-like color shifting filter** is applied:

  * Converts to HSV
  * Rotates the hue channel
  * Converts back to BGR

> You can customize the Python filter logic in `main.py`

---

## Usage

1. Launch the Flutter app.
2. Tap **Pick Image** to select an image.
3. Use any of the following:

   * **Native Filters**: Apply fast filters using C++ (OpenCV)
   * **AI Filter**: Sends image to FastAPI server for a cartoon-style effect
4. Use **Undo** / **Redo** to navigate filter history.
5. Drag the center handle to compare original vs filtered images.

---

## Available Filters

| Name          | Description                    | Type         |
| ------------- | ------------------------------ | ------------ |
| Grayscale     | Converts to black and white    | Native (C++) |
| Sepia         | Vintage warm tones             | Native (C++) |
| Invert        | Color inversion                | Native (C++) |
| Blur          | Gaussian blur                  | Native (C++) |
| Sharpen       | Sharpens the image             | Native (C++) |
| EdgeDetection | Canny edge detection           | Native (C++) |
| Emboss        | Emboss-style 3D effect         | Native (C++) |
| AI Filter     | Hue-shifted cartoon-like style | Python API   |

---

## Notes

* The Python server is meant to simulate a heavier AI model.
* Replace it with a cloud-deployed ML model if desired.
* This project demonstrates real-time image filtering with multi-language integration.

Feel free to modify and expand it!
