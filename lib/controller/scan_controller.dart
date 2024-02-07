import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFLite();
  }

  @override
  void dispose() {
    super.dispose();
    Tflite.close();
    cameraController.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription>
      cameras; //Contain all cameras available in device

  //late CameraImage cameraImage;

  var isCameraInitialized = false.obs;
  var isDetecting = false;
  var cameraCount = 0; //fetch results at 30fps

  initCamera() async {
    //Get Permission from user to access the camera
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(cameras[1], ResolutionPreset.low); 
      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 10 == 0) { 
            cameraCount = 0;
            objectDetector(image);
          }
          update();
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      print("Permission denied");
    }
  }

  // initCamera() async {
  //   cameras = await availableCameras();
  //   cameraController = CameraController(
  //     cameras[0],
  //     ResolutionPreset.max,
  //   );
  //   await cameraController.initialize().then((value) {
  //     cameraController.startImageStream((image) {
  //       if (!isDetecting) {
  //         isDetecting = true;
  //         objectDetector(image).then((_) => isDetecting = false);
  //       }
  //       update();
  //     });
  //   });
  //   isCameraInitialized(true);
  //   update();
  // }

  initTFLite() async {
    await Tflite.loadModel(
        model: "assets/converted_model.tflite",
        labels: "assets/new_onnx_model94.txt",
        isAsset: true,
        numThreads: 1,
        useGpuDelegate: false);
  }

  // objectDetector(CameraImage image) async {
  //   var detector = await Tflite.runModelOnFrame(
  //     bytesList: image.planes.map((e) {
  //       return e.bytes;
  //     }).toList(),
  //     asynch: true,
  //     imageHeight: image.height,
  //     imageWidth: image.width,
  //     imageMean: 127.5,
  //     imageStd: 127.5,
  //     numResults: 1,
  //     rotation: 90,
  //     threshold: 0.4,
  //   );

  //   if (detector != null) {
  //     if (kDebugMode) {
  //       print("Result is $detector"); //log
  //     }
  //   }
  // }

  objectDetector(CameraImage image) async {
  try {
    //print("Input Image Shape: ${image.width}x${image.height}");
  
    var detector = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((e) {
        return e.bytes;
      }).toList(),
      asynch: true,
      imageHeight: image.height, //640
      imageWidth: image.width, //480
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );

    if (detector != null) {
      if (kDebugMode) {
        print("Result is $detector");
      }
    }
  } catch (e) {
    print("Error in object detection: $e");
  }
}

}
