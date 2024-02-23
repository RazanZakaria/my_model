import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:image/image.dart';
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

  initTFLite() async {
    await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
        isAsset: true,
        numThreads: 1,
        useGpuDelegate: false);
  }

  var singleTime = false;
  objectDetector(CameraImage image) async {
   
        //print("Number of bytes in resized image: ${resizedBytes.length}");
        var detector = await Tflite.runModelOnFrame(
          bytesList: image.planes.map((plane) {return plane.bytes;}).toList(),
          asynch: true,
          imageHeight: image.height,
          imageWidth: image.width,
          imageMean: 127.5,
          imageStd: 127.5,
          numResults: 26,
          rotation: 90,
          threshold: 0.4,
        )
            .then((value) => {print('Output TF $value')})
            .onError((error, stackTrace) => {print('Output Error TF $error')});

        /*if (detector != null) {
        if (kDebugMode) {
          print("Result is $detector");
        }
      }*/
      
    }
  }

