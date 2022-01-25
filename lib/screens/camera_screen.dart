import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera/screens/preview_screen.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({required this.cameras, Key? key}) : super(key: key);
  final List<CameraDescription> cameras;
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;

  File? _imageFile;
  File? _videoFile;

  // Initial values
  bool _isCameraInitialized = false;
  bool _isRearCameraSelected = true;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  // Current values
  double _currentZoomLevel = 1.0;
  double _currentExposureOffset = 0.0;
  FlashMode? _currentFlashMode;

  List<File> allFileList = [];

  final resolutionPresets = ResolutionPreset.values;

  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

  refreshAlreadyCapturedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> fileList = await directory.list().toList();
    allFileList.clear();
    List<Map<int, dynamic>> fileNames = [];

    for (var file in fileList) {
      if (file.path.contains('.jpg')) {
        allFileList.add(File(file.path));

        String name = file.path.split('/').last.split('.').first;
        fileNames.add({0: int.parse(name), 1: file.path.split('/').last});
      }
    }

    if (fileNames.isNotEmpty) {
      final recentFile =
          fileNames.reduce((curr, next) => curr[0] > next[0] ? curr : next);
      String recentFileName = recentFile[1];
      _imageFile = File('${directory.path}/$recentFileName');
      _videoFile = null;

      setState(() {});
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;

    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      // ignore: avoid_print
      print('Error occured while taking picture: $e');
      return null;
    }
  }

  void resetCameraValues() async {
    _currentZoomLevel = 1.0;
    _currentExposureOffset = 0.0;
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;

    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await previousCameraController?.dispose();

    resetCameraValues();

    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
      /*await Future.wait([
        cameraController
            .getMinExposureOffset()
            .then((value) => _minAvailableExposureOffset = value),
        cameraController
            .getMaxExposureOffset()
            .then((value) => _maxAvailableExposureOffset = value),
        cameraController
            .getMaxZoomLevel()
            .then((value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((value) => _minAvailableZoom = value),
      ]);*/

      _currentFlashMode = controller!.value.flashMode;
    } on CameraException catch (e) {
      // ignore: avoid_print
      print('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  @override
  void initState() {
    onNewCameraSelected(widget.cameras[0]);
    refreshAlreadyCapturedImages();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isCameraInitialized
            ? Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1 / controller!.value.aspectRatio,
                    child: Stack(
                      children: [
                        controller!.buildPreview(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            8.0,
                            16.0,
                            8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      right: 8.0,
                                    ),
                                    child: DropdownButton<ResolutionPreset>(
                                      dropdownColor: Colors.black87,
                                      underline: Container(),
                                      value: currentResolutionPreset,
                                      items: [
                                        for (ResolutionPreset preset
                                            in resolutionPresets)
                                          DropdownMenuItem(
                                            child: Text(
                                              preset
                                                  .toString()
                                                  .split('.')[1]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            value: preset,
                                          )
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          currentResolutionPreset = value!;
                                          _isCameraInitialized = false;
                                        });
                                        onNewCameraSelected(
                                            controller!.description);
                                      },
                                      hint: const Text("Select item"),
                                    ),
                                  ),
                                ),
                              ),
                              // Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 8.0, top: 16.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _currentExposureOffset
                                              .toStringAsFixed(1) +
                                          'x',
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: SizedBox(
                                    height: 30,
                                    child: Slider(
                                      value: _currentExposureOffset,
                                      min: _minAvailableExposureOffset,
                                      max: _maxAvailableExposureOffset,
                                      activeColor: Colors.white,
                                      inactiveColor: Colors.white30,
                                      onChanged: (value) async {
                                        setState(() {
                                          _currentExposureOffset = value;
                                        });
                                        await controller!
                                            .setExposureOffset(value);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: _currentZoomLevel,
                                      min: _minAvailableZoom,
                                      max: _maxAvailableZoom,
                                      activeColor: Colors.white,
                                      inactiveColor: Colors.white30,
                                      onChanged: (value) async {
                                        setState(() {
                                          _currentZoomLevel = value;
                                        });
                                        await controller!.setZoomLevel(value);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          _currentZoomLevel.toStringAsFixed(1) +
                                              'x',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isCameraInitialized = false;
                                      });
                                      onNewCameraSelected(widget.cameras[
                                          _isRearCameraSelected ? 1 : 0]);
                                      setState(() {
                                        _isRearCameraSelected =
                                            !_isRearCameraSelected;
                                      });
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: Colors.black38,
                                          size: 60,
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      XFile? rawImage = await takePicture();
                                      File imageFile = File(rawImage!.path);

                                      int currentUnix =
                                          DateTime.now().millisecondsSinceEpoch;

                                      final directory =
                                          await getApplicationDocumentsDirectory();

                                      String fileFormat =
                                          imageFile.path.split('.').last;

                                      // ignore: avoid_print
                                      print(fileFormat);

                                      await imageFile.copy(
                                        '${directory.path}/$currentUnix.$fileFormat',
                                      );

                                      refreshAlreadyCapturedImages();
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(
                                          Icons.circle,
                                          color: Colors.white38,
                                          size: 80,
                                        ),
                                        const Icon(
                                          Icons.circle,
                                          color: Colors.white,
                                          size: 65,
                                        ),
                                        Container(),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap:
                                        _imageFile != null || _videoFile != null
                                            ? () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PreviewScreen(
                                                      imageFile: _imageFile!,
                                                      fileList: allFileList,
                                                    ),
                                                  ),
                                                );
                                              }
                                            : null,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        image: _imageFile != null
                                            ? DecorationImage(
                                                image: FileImage(_imageFile!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: Container(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(
                child: Text(
                  'LOADING',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }
}
