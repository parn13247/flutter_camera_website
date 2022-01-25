import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera/camera_example.dart';
import 'package:flutter_camera/screen2/camera_home_screen.dart';
import 'package:image_picker_gallery_camera/image_picker_gallery_camera.dart';

import 'camera_app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Camera Upload',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Test Camera Upload'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// ignore: prefer_typing_uninitialized_variables
var _image;

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final isWebMobile = kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Test Camera in Website...',
            ),
            SizedBox(
              width: 500,
              height: 50,
              child: TextButton(
                  onPressed: () async {
                    List<CameraDescription> cameras;
                    try {
                      WidgetsFlutterBinding.ensureInitialized();
                      cameras = await availableCameras();
                      await Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                            pageBuilder: (context, animation1, animation2) =>
                                MaterialApp(
                                  home: CameraApp(camera: cameras),
                                ),
                            transitionDuration: const Duration(seconds: 2)),
                      );
                    } on CameraException catch (e) {
                      logError(e.code, e.description);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.file_upload),
                      Text(
                        'อัพโหลดไฟล์ผ่านการถ่ายรูป',
                        style: TextStyle(color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )),
            ),
            /*SizedBox(
              width: 500,
              height: 50,
              child: TextButton(
                  onPressed: () async {
                    List<CameraDescription> cameras;
                    try {
                      WidgetsFlutterBinding.ensureInitialized();
                      cameras = await availableCameras();
                      runApp(MaterialApp(
                          home: CameraExampleHome(cameras: cameras)));
                    } on CameraException catch (e) {
                      logError(e.code, e.description);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.file_upload),
                      Text(
                        'อัพโหลดไฟล์ผ่านการถ่ายรูป 3',
                        style: TextStyle(color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )),
            ),*/
            if (isWebMobile)
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: () => getImage(ImgSource.Camera),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.deepPurple,
                  ),
                  child: Text(
                    "Picker Browse force Camera".toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            SizedBox(
              width: 300,
              child: Text(
                "Detect is web mobile : " + isWebMobile.toString(),
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future getImage(ImgSource source) async {
    var image = await ImagePickerGC.pickImage(
        enableCloseButton: true,
        closeIcon: const Icon(
          Icons.close,
          color: Colors.red,
          size: 12,
        ),
        context: context,
        source: ImgSource.Camera,
        barrierDismissible: true,
        cameraIcon: const Icon(
          Icons.camera_alt,
          color: Colors.red,
        ), //cameraIcon and galleryIcon can change. If no icon provided default icon will be present
        cameraText: const Text(
          "From Camera",
          style: TextStyle(color: Colors.red),
        ),
        galleryText: const Text(
          "From Gallery",
          style: TextStyle(color: Colors.blue),
        ));
    setState(() {
      _image = image;
    });
  }
}
