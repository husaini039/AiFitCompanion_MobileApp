import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pose_detection_realtime/ExerciseListingScreen.dart';

import 'screen/welcome_page.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  cameras = await availableCameras();
  runApp(MaterialApp(
    theme: ThemeData(
      textTheme: GoogleFonts.montserratTextTheme(),
    ),
    home: WelcomePage(),
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      home: WelcomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  dynamic controller;
  bool isBusy = false;
  late Size size;
  int _cameraIndex = 0;

  //TODO declare detector
  late PoseDetector poseDetector;
  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  //TODO code to initialize the camera feed
  initializeCamera() async {
    //TODO initialize detector
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    poseDetector = PoseDetector(options: options);

    controller = CameraController(
      cameras[_cameraIndex],
      ResolutionPreset.medium,
      imageFormatGroup:
          Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
      enableAudio: false,
    );
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream(
        (image) => {
          if (!isBusy) {isBusy = true, img = image, doPoseEstimationOnFrame()},
        },
      );
    });
  }

  //TODO pose detection on a frame
  dynamic _scanResults;
  CameraImage? img;
  doPoseEstimationOnFrame() async {
    var inputImage = _inputImageFromCameraImage();
    if (inputImage != null) {
      final List<Pose> poses = await poseDetector.processImage(inputImage!);
      print("pose=" + poses.length.toString());
      _scanResults = poses;
      if (poses.length > 0) {
        // Transform landmarks for front camera
        bool isFrontCamera = cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
        final Size imageSize = Size(
          controller.value.previewSize!.width,
          controller.value.previewSize!.height,
        );
        final landmarks = _transformLandmarksIfFrontCamera(
          poses.first.landmarks,
          imageSize.height,
          isFrontCamera,
        );
        // Use 'landmarks' for all detection logic below
        detectPushUp(landmarks); // Example: replace with your detection function
        // ... repeat for other exercise detection functions as needed ...
      }
    }
    setState(() {
      _scanResults;
      isBusy = false;
    });
  }

  //close all resources
  @override
  void dispose() {
    controller?.dispose();
    poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    size = MediaQuery.of(context).size;
    if (controller != null) {
      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child:
                controller.value.isInitialized
                    ? Transform.scale(
                      scale: 1.0,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: CameraPreview(controller),
                        ),
                      ),
                    )
                    : Container(),
          ),
        ),
      );

      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: buildResult(),
        ),
      );
      stackChildren.add(
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.black,
            ),
            child: Center(
              child: Text(
                "$pushUpCount",
                style: GoogleFonts.montserrat(
                  color: Colors.white, 
                  fontSize: 20,
                ),
              ),
            ),
            width: 70,
            height: 70,
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 0),
        color: Colors.black,
        child: Stack(children: stackChildren),
      ),
    );
  }

  int pushUpCount = 0;
  bool isLowered = false;
  void detectPushUp(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        leftWrist == null ||
        rightWrist == null ||
        leftHip == null ||
        rightHip == null) {
      return; // Skip if any landmark is missing
    }

    // Calculate elbow angles
    double leftElbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightElbowAngle = calculateAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );
    double avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Calculate torso alignment (ensuring a straight plank)
    double torsoAngle = calculateAngle(
      leftShoulder,
      leftHip,
      leftKnee ?? rightKnee!,
    );
    bool inPlankPosition =
        torsoAngle > 160 && torsoAngle < 180; // Slight flexibility

    if (avgElbowAngle < 90 && inPlankPosition) {
      // User is in the lowered push-up position
      isLowered = true;
    } else if (avgElbowAngle > 160 && isLowered && inPlankPosition) {
      // User returns to the starting position
      pushUpCount++;
      isLowered = false;

      // Update UI
      setState(() {});
    }
  }

  int squatCount = 0;
  bool isSquatting = false;
  void detectSquat(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftShoulder == null ||
        rightShoulder == null) {
      return; // Skip detection if any key landmark is missing
    }

    // Calculate angles
    double leftKneeAngle = calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    double hipY = (leftHip.y + rightHip.y) / 2;
    double kneeY = (leftKnee.y + rightKnee.y) / 2;

    bool deepSquat = avgKneeAngle < 90; // Ensuring squat is deep enough

    if (deepSquat && hipY > kneeY) {
      if (!isSquatting) {
        isSquatting = true;
      }
    } else if (!deepSquat && isSquatting) {
      squatCount++;
      isSquatting = false;

      // Update UI
      setState(() {});
    }
  }

  int plankToDownwardDogCount = 0;
  bool isInDownwardDog = false;
  void detectPlankToDownwardDog(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftHip == null ||
        rightHip == null ||
        leftShoulder == null ||
        rightShoulder == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftWrist == null ||
        rightWrist == null) {
      return; // Skip detection if any key landmark is missing
    }

    // **Step 1: Detect Plank Position**
    bool isPlank =
        (leftHip.y - leftShoulder.y).abs() < 30 &&
        (rightHip.y - rightShoulder.y).abs() < 30 &&
        (leftHip.y - leftAnkle.y).abs() > 100 &&
        (rightHip.y - rightAnkle.y).abs() > 100;

    // **Step 2: Detect Downward Dog Position**
    bool isDownwardDog =
        (leftHip.y < leftShoulder.y - 50) &&
        (rightHip.y < rightShoulder.y - 50) &&
        (leftAnkle.y > leftHip.y) &&
        (rightAnkle.y > rightHip.y);

    // **Step 3: Count Repetitions**
    if (isDownwardDog && !isInDownwardDog) {
      isInDownwardDog = true;
    } else if (isPlank && isInDownwardDog) {
      plankToDownwardDogCount++;
      isInDownwardDog = false;

      // Print count
      print("Plank to Downward Dog Count: $plankToDownwardDogCount");
    }
  }

  int jumpingJackCount = 0;
  bool isJumping = false;
  bool isJumpingJackOpen = false;
  void detectJumpingJack(Pose pose) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftAnkle == null ||
        rightAnkle == null ||
        leftHip == null ||
        rightHip == null ||
        leftShoulder == null ||
        rightShoulder == null ||
        leftWrist == null ||
        rightWrist == null) {
      return; // Skip detection if any landmark is missing
    }

    // Calculate distances
    double legSpread = (rightAnkle.x - leftAnkle.x).abs();
    double armHeight = (leftWrist.y + rightWrist.y) / 2; // Average wrist height
    double hipHeight = (leftHip.y + rightHip.y) / 2; // Average hip height
    double shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();

    // Define thresholds based on shoulder width
    double legThreshold =
        shoulderWidth * 1.2; // Legs should be ~1.2x shoulder width apart
    double armThreshold =
        hipHeight - shoulderWidth * 0.5; // Arms should be above shoulders

    // Check if arms are raised and legs are spread
    bool armsUp = armHeight < armThreshold;
    bool legsApart = legSpread > legThreshold;

    // Detect full jumping jack cycle
    if (armsUp && legsApart && !isJumpingJackOpen) {
      isJumpingJackOpen = true;
    } else if (!armsUp && !legsApart && isJumpingJackOpen) {
      jumpingJackCount++;
      isJumpingJackOpen = false;

      // Print the count
      print("Jumping Jack Count: $jumpingJackCount");
    }
  }

  // Function to calculate angle between three points (shoulder, elbow, wrist)
  double calculateAngle(
    PoseLandmark shoulder,
    PoseLandmark elbow,
    PoseLandmark wrist,
  ) {
    double a = distance(elbow, wrist);
    double b = distance(shoulder, elbow);
    double c = distance(shoulder, wrist);

    double angle = acos((b * b + a * a - c * c) / (2 * b * a)) * (180 / pi);
    return angle;
  }

  // Helper function to calculate Euclidean distance
  double distance(PoseLandmark p1, PoseLandmark p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
  }

  // Utility function to check if all major joints are present (full body in frame)
  bool isFullBodyInFrame(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // List of required joints for a full standing body
    final requiredJoints = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftEye,
      PoseLandmarkType.rightEye,
      PoseLandmarkType.leftEar,
      PoseLandmarkType.rightEar,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];
    for (final joint in requiredJoints) {
      if (!landmarks.containsKey(joint) || landmarks[joint] == null) {
        return false;
      }
    }
    return true;
  }

  // Utility function to check for a standing pose using joint alignment
  bool _isStandingPoseAligned(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Only require the most reliable joints
    final requiredJoints = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];
    for (final joint in requiredJoints) {
      if (!landmarks.containsKey(joint) || landmarks[joint] == null) {
        return false;
      }
    }

    // Relaxed alignment checks
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    if ((leftShoulder.y - rightShoulder.y).abs() > 60) return false;

    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;
    if ((leftHip.y - rightHip.y).abs() > 60) return false;

    final leftKnee = landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = landmarks[PoseLandmarkType.rightKnee]!;
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle]!;
    if ((leftKnee.x - leftAnkle.x).abs() > 80 ||
        (rightKnee.x - rightAnkle.x).abs() > 80) return false;

    // Feet not too far apart
    if ((leftAnkle.x - rightAnkle.x).abs() > 200) return false;

    return true;
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  InputImage? _inputImageFromCameraImage() {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final camera = cameras[0];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(img!.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888))
      return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (img!.planes.length != 1) return null;
    final plane = img!.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(img!.width.toDouble(), img!.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  //Show rectangles around detected objects
  Widget buildResult() {
    if (_scanResults == null ||
        controller == null ||
        !controller.value.isInitialized) {
      return Text('');
    }
    final Size imageSize = Size(
      controller.value.previewSize!.width,
      controller.value.previewSize!.height,
    );
    CustomPainter painter = PosePainter(imageSize, _scanResults, _cameraIndex);
    return CustomPaint(painter: painter);
  }
}

// Add this helper function to flip y-coordinates for the front camera
PoseLandmark _flipLandmarkY(PoseLandmark landmark, double imageHeight) {
  return PoseLandmark(
    type: landmark.type,
    x: landmark.x,
    y: imageHeight - landmark.y,
    z: landmark.z,
    likelihood: landmark.likelihood,
  );
}

Map<PoseLandmarkType, PoseLandmark> _transformLandmarksIfFrontCamera(
  Map<PoseLandmarkType, PoseLandmark> landmarks,
  double imageHeight,
  bool isFrontCamera,
) {
  if (!isFrontCamera) return landmarks;
  return landmarks.map((type, landmark) {
    return MapEntry(type, _flipLandmarkY(landmark, imageHeight));
  });
}

class PosePainter extends CustomPainter {
  PosePainter(this.absoluteImageSize, this.poses, this.cameraIndex);

  final Size absoluteImageSize;
  final List<Pose> poses;
  final int cameraIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    // Handle front camera mirroring - flip horizontally twice and vertically once
    if (cameras[cameraIndex].lensDirection == CameraLensDirection.front) {
      canvas.save();
      // Flip horizontally twice (cancels out) and vertically once
      canvas.scale(1, -1);
      canvas.translate(0, -size.height);
      _drawPose(canvas, size, scaleX, scaleY);
      canvas.restore();
    } else {
      _drawPose(canvas, size, scaleX, scaleY);
    }
  }

  void _drawPose(Canvas canvas, Size size, double scaleX, double scaleY) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent;

    for (final pose in poses) {
      // Draw circles for each landmark
      pose.landmarks.forEach((type, landmark) {
        final x = landmark.x * scaleX;
        final y = landmark.y * scaleY;
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.blue);
      });

      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark? joint1 = pose.landmarks[type1];
        final PoseLandmark? joint2 = pose.landmarks[type2];
        if (joint1 != null && joint2 != null) {
          canvas.drawLine(
            Offset(joint1.x * scaleX, joint1.y * scaleY),
            Offset(joint2.x * scaleX, joint2.y * scaleY),
            paintType,
          );
        }
      }

      // Arms
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, rightPaint);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      // Body
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, rightPaint);

      // Torso connection
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paint);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint);

      // Legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
      paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;  // Repaint every time
  }
}
