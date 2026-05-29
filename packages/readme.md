Visual and non-visual components for working with the library OpenCV
------------------------
Version: OpenCV 2.4.13

Requires installed [Visual C++ redistributable for Visual Studio 2013][1]<br>

FFmpeg (optional, for IP camera / video components): FFmpeg **4.2.2** shared DLLs — `avcodec-58.dll`, `avformat-58.dll`, `avutil-56.dll`, `avdevice-58.dll`, `avfilter-7.dll`, `postproc-55.dll`, `swresample-3.dll`, `swscale-5.dll`. Sources are in `Delphi-FFMPEG/source/` (see [Delphi-FFMPEG README](../Delphi-FFMPEG/README.md)).

Installation
------------
1. Add to system variable PATH path to DLL libraries OpenCV.
2. Add FFmpeg 4.2.2 DLLs to PATH (or next to your `.exe`) if you use `ocv.comp.FFMSource` / IP camera demos.
3. To install, open `<PROJECT_ROOT>\packages\<Delphi version>\OpenCV.groupproj`. Build and install packages in order: `rtpFFMPEG` → `rclVCLOpenCV` → `rclFMXOpenCV` → `dclVCLOpenCV` → `dclFMXOpenCV`.
4. Supported Delphi versions include Delphi 12 Athens and Delphi 13 Florence (`packages\Delphi 13 Florence\`).
5. In the panel component will be part OpenCV.
6. Open the sample<br>
```
<PROJECT_ROOT>\samples\Components\
```

Run the sample.

[1]: http://www.microsoft.com/ru-ru/download/details.aspx?id=40784