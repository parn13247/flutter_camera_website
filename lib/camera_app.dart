import 'dart:html';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class CameraApp extends StatefulWidget {
  final List<CameraDescription> camera;

  const CameraApp({required this.camera, Key? key}) : super(key: key);

  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _toggleCamera = true;
  bool _support2Camera = false;
  @override
  void initState() {
    super.initState();
    widget.camera.length > 1 ? _support2Camera = true : _support2Camera = false;
    onCameraSelected(widget.camera.first);
    WidgetsBinding.instance!.addObserver(this);
  }

  void onCameraSelected(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      kIsWeb ? ResolutionPreset.max : ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) setState(() {});
      if (cameraController.value.hasError) {
        showMessage('Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      showException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //if (!_controller!.value.isInitialized) {
    //  return Container();
    //}
    return AspectRatio(
      aspectRatio: (!_controller!.value.isInitialized)
          ? 1
          : _controller!.value.aspectRatio,
      child: Stack(
        children: <Widget>[
          if (!_controller!.value.isInitialized)
            MaterialApp(
              home: Container(
                color: Colors.black,
              ),
            )
          else
            MaterialApp(
              home: CameraPreview(_controller!),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 90.0,
              padding: const EdgeInsets.all(10.0),
              color: const Color.fromRGBO(00, 00, 00, 0.7),
              child: Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        onPressed: () async {
                          try {
                            final image = await _controller?.takePicture();
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DisplayPictureScreen(
                                  imagePath: image!.path,
                                ),
                              ),
                            );
                          } catch (e) {
                            //print(e);
                          }
                        },
                        icon: const Icon(
                          Icons.circle,
                          color: Colors.grey,
                        ),
                        iconSize: 60,
                      ),
                    ),
                  ),
                  //left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: Icon(
                            _toggleCamera
                                ? Icons.camera_rear
                                : Icons.camera_front,
                            color: Colors.grey),
                        onPressed: () {
                          if (_support2Camera) {
                            if (_toggleCamera) {
                              onCameraSelected(widget.camera.first);
                              setState(() {
                                _toggleCamera = false;
                              });
                            } else {
                              onCameraSelected(widget.camera.last);
                              setState(() {
                                _toggleCamera = true;
                              });
                            }
                          }
                        },
                        iconSize: 40,
                      ),
                    ),
                  ),
                  //right
                  Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(
                            Icons.home_filled,
                            color: Colors.grey,
                          ),
                          onPressed: () async {
                            dispose();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MyHomePage(
                                        title: 'Test',
                                      )),
                              (Route<dynamic> route) => false,
                            );
                          },
                          iconSize: 40,
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showException(CameraException e) {
    logError(e.code, e.description!);
    showMessage('Error: ${e.code}\n${e.description}');
  }

  void showMessage(String message) {
    // ignore: avoid_print
    print(message);
  }

  void logError(String code, String message) =>
      // ignore: avoid_print
      print('Error: $code\nMessage: $message');
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: Image.network(imagePath,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center),
    );
  }
}
