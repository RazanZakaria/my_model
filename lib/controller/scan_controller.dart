import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart'
    as imglib; //library for image manipulation capabilities.

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

  initTFLite() async {
    await Tflite.loadModel(
        model: "assets/converted_model.tflite",
        labels: "assets/new_onnx_model94.txt",
        isAsset: true,
        numThreads: 1,
        useGpuDelegate: false);
  }

  objectDetector(CameraImage image) async {
    try {
      var imgBytes =
          image.planes.fold<Uint8List>(Uint8List(0), (buffer, plane) {
        var bytes = plane.bytes;
        if (buffer.isEmpty) {
          buffer = bytes;
        } else {
          buffer = Uint8List.fromList([...buffer, ...bytes]);
        }
        return buffer;
      });

      // Create Image object
      var img = imglib.Image.fromBytes(image.width, image.height, imgBytes);

      // Resize the image
      img = imglib.copyResize(img, width: 416, height: 416);

      // Convert resized image back to List<Uint8List>
      var resizedBytes =
          img.getBytes().map((b) => Uint8List.fromList([b])).toList();

      print("Number of bytes in resized image: ${resizedBytes.length}");

      var detector = await Tflite.runModelOnFrame(
        bytesList: resizedBytes,
        asynch: true,
        imageHeight: image.height,
        imageWidth: image.width,
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
