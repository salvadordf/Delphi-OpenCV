# Delphi-OpenCV

[![Delphi Support](https://img.shields.io/badge/Delphi-2010--13-blue.svg?style=flat-square)](https://www.embarcadero.com/products/delphi)
[![OpenCV Version](https://img.shields.io/badge/OpenCV-2.4.13-green.svg?style=flat-square)](https://github.com/opencv/opencv/releases/tag/2.4.13.6)
[![FPC Support](https://img.shields.io/badge/FPC-3.0.4-orange.svg?style=flat-square)](https://www.freepascal.org/)
[![License](https://img.shields.io/badge/License-MPL_1.1-lightgrey.svg?style=flat-square)](http://www.mozilla.org/MPL/MPL-1_1Final.html)

A comprehensive port of the **OpenCV (Open Source Computer Vision Library) v2.4.13** to **Delphi** and **FreePascal (FPC)**. This library enables object pascal developers to leverage computer vision algorithms, image/video processing tools, and FFMPEG integration directly in their applications.

---

## 🌟 Key Features

- **Direct OpenCV Bindings:** Direct access to OpenCV C/C++ APIs (v2.4.13) from Delphi code.
- **FFMPEG Integration:** Powerful video parsing and streaming support using the Delphi-FFMPEG engine.
- **Cross-Framework UI:** Components and views ready for both **VCL** and **FireMonkey (FMX)** platforms.
- **Rich Samples Collection:** Ready-to-run examples demonstrating object tracking, camera captures, face detection (Haar cascades), motion detection, and OpenGL overlays.

---

## 📋 Prerequisites & Requirements

To compile packages and run samples, you need the following dependencies:

| Dependency | Required Version | Description | Source / Link |
| :--- | :--- | :--- | :--- |
| **VC++ Redistributable** | 2015 (VC14) | Required for OpenCV DLLs (`msvcp140.dll`, `msvcp140d.dll`) | Included in `redist/VC14` or [Microsoft Official][2] |
| **FFMPEG DLLs** | v4.2.1 | Shared FFMPEG libraries for Windows | Included in `redist/ffmpeg` or [ffbinaries][5] |
| **OpenCV DLLs** | v2.4.13.6 | Dynamic link libraries (`*2413.dll`, `*2413d.dll`) | Download from [OpenCV Releases][4] |
| **SDL Libraries** | v1.2 & v2.0 | Simple DirectMedia Layer (required for FFMPEG rendering examples) | Included in `redist/SDL` or [libsdl.org][3] |

---

## 🛠️ Installation Guide

### Step 1: Clone the Repository & Submodules
Clone the repository recursively to get all modules:
```bash
git clone https://github.com/Laex/Delphi-OpenCV.git
```
Then, run **`InitDelphiFFMPEG.cmd`** located in the root directory to automatically initialize and pull the **`Delphi-FFMPEG`** submodule. 

*(If the initialization script fails, you can clone it manually into the `<PROJECT_ROOT>\Delphi-FFMPEG` directory)*:
```bash
git clone https://github.com/Laex/Delphi-FFMPEG.git Delphi-FFMPEG
```

### Step 2: Configure Delphi Search Paths
Add the following folders to your Delphi IDE Library Paths under `Tools -> Options -> Language -> Delphi -> Library -> Library Path` (or equivalent in older versions):

```text
<PROJECT_ROOT>\source
<PROJECT_ROOT>\source\opengl
<PROJECT_ROOT>\source\sdl
<PROJECT_ROOT>\source\sdl2
<PROJECT_ROOT>\packages
<PROJECT_ROOT>esource
<PROJECT_ROOT>esourceacedetectxml
<PROJECT_ROOT>\source3
<PROJECT_ROOT>\Delphi-FFMPEG\source
```
*(Replace `<PROJECT_ROOT>` with the absolute path where you cloned the repository)*.

### Step 3: Set up Dynamic Libraries (DLLs)
For the compiler to find external DLLs during debugging or execution, copy the redistributable libraries to your Windows directories or keep them next to your compiled binaries.

#### Recommended Windows Directory Setup:
- **On 64-bit Windows:**
  - Copy **64-bit DLLs** to `C:\Windows\System32\`
  - Copy **32-bit DLLs** to `C:\Windows\SysWOW64\`
- **On 32-bit Windows:**
  - Copy **32-bit DLLs** to `C:\Windows\System32\`

*Alternatively, copy all corresponding 32-bit or 64-bit DLLs directly into the output folder next to your compiled executable.*

### Step 4: Verify Your Configuration
You can verify that all redistributable DLLs are correctly detected by running the dependency checker tool located in the repository:
```text
<PROJECT_ROOT>\CheckCVDep\CheckCVDep.exe
```
If configured correctly, the tool will output `OK` for all checked components (Microsoft, OpenCV, classes, FFMPEG, and SDL).

### Step 5: Install Delphi Components
Open the appropriate package folder for your IDE version (e.g., `packages\Delphi 13 Florence\` or `packages\Delphi 12 Athens\`) and build/install the packages in the following logical order:

1. **`rtpFFMPEG.dpk`** (FFMPEG Runtime Package)
2. **`rclVCLOpenCV.dpk`** (VCL Runtime OpenCV components)
3. **`rclFMXOpenCV.dpk`** (FMX Runtime OpenCV components)
4. **`dclVCLOpenCV.dpk`** (VCL Design-time components)
5. **`dclFMXOpenCV.dpk`** (FMX Design-time components)

---

## 📂 Directory Structure

```text
<PROJECT_ROOT>
 ├── bin              # Compiled binaries and executables for samples
 ├── CheckCVDep       # Environment verification tool
 ├── Delphi-FFMPEG    # Delphi-FFMPEG submodule
 ├── packages         # Design and runtime Delphi IDE packages (D2010 to D13)
 ├── redist           # Pre-packaged redistributable libraries (VC14, FFmpeg, SDL)
 ├── resource         # Media files, XML classifiers, and Haar cascades
 ├── samples          # Demos and VCL/FMX sample projects
 ├── source           # Core Object Pascal bindings for OpenCV, SDL, and OpenGL
 └── source3          # Source files for OpenCV 3 integration attempts
```

---

## 🚀 Examples & Demos

Delphi-OpenCV includes several demo group projects to showcase different capabilities. Open them in your Delphi IDE to compile and run:

- **`samples\LibDemo\LibDemo.groupproj`** — Demonstrations of basic OpenCV functions, utilities, and bindings.
- **`samples\MultiDemo\MultiDemo.groupproj`** — Advanced video processing, motion detection, and image analysis algorithms.
- **`samples\VCLDemo\VCLDemo.groupproj`** — Visual OpenCV wrappers designed specifically for classic VCL Forms.
- **`samples\Components\ComponentsDemo.groupproj`** — Visual components usage (viewers, capturers, video writers).
- **`Delphi-FFMPEG\examples`** — Examples of low-level FFMPEG video parsing.

---

## 👥 Contributors

- **Laentir Valetov** (Lead Contributor) — [laex@bk.ru](mailto:laex@bk.ru)
- **Mikhail Grigorev** — [sleuthhound@gmail.com](mailto:sleuthhound@gmail.com)

---

## 📄 License

This project is licensed under the **Mozilla Public License Version 1.1 (MPL 1.1)**. You may obtain a copy of the License at [Mozilla MPL 1.1 Page](http://www.mozilla.org/MPL/MPL-1_1Final.html).

[1]: https://github.com/Laex/Delphi-OpenCV/archive/master.zip
[2]: https://www.microsoft.com/en-us/download/details.aspx?id=48145
[3]: https://www.libsdl.org/
[4]: https://github.com/opencv/opencv/releases/tag/2.4.13.6
[5]: https://ffbinaries.com/downloads#version_4.2.1
