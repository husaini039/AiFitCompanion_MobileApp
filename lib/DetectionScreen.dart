import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pose_detection_realtime/Model/ExerciseDataModel.dart';
import 'package:pose_detection_realtime/Exercises/upperbody_exercise.dart';
import 'package:pose_detection_realtime/Exercises/core_exercise.dart';
import 'package:pose_detection_realtime/Exercises/leg_exercise.dart';
import 'package:pose_detection_realtime/Exercises/fullbody_exercise.dart';
import 'package:pose_detection_realtime/screen/exercise_completion_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pose_detection_realtime/screen/auth_service.dart';

import 'main.dart' as main_utils;

class DetectionScreen extends StatefulWidget {
  DetectionScreen({
    Key? key,
    required this.exerciseDataModel,
    this.targetReps,
    this.targetMinutes,
  }) : super(key: key);

  ExerciseDataModel exerciseDataModel;
  int? targetReps; // For rep-based exercises
  int? targetMinutes; // For timer-based exercises

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<DetectionScreen> {
  // Check for a standing pose using joint alignment
  bool _isStandingPoseAligned(Map<PoseLandmarkType, PoseLandmark> landmarks) {
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
    final nose = landmarks[PoseLandmarkType.nose]!;
    final leftEye = landmarks[PoseLandmarkType.leftEye]!;
    final rightEye = landmarks[PoseLandmarkType.rightEye]!;
    if ((nose.x - leftEye.x).abs() > 50 || (nose.x - rightEye.x).abs() > 50) {
      return false;
    }
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    if ((leftShoulder.y - rightShoulder.y).abs() > 30) {
      return false;
    }
    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;
    if ((leftHip.y - rightHip.y).abs() > 30) {
      return false;
    }
    final leftElbow = landmarks[PoseLandmarkType.leftElbow]!;
    final rightElbow = landmarks[PoseLandmarkType.rightElbow]!;
    final leftWrist = landmarks[PoseLandmarkType.leftWrist]!;
    final rightWrist = landmarks[PoseLandmarkType.rightWrist]!;
    if ((leftElbow.x - leftShoulder.x).abs() > 50 ||
        (rightElbow.x - rightShoulder.x).abs() > 50 ||
        (leftWrist.x - leftElbow.x).abs() > 50 ||
        (rightWrist.x - rightElbow.x).abs() > 50) {
      return false;
    }
    final leftKnee = landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = landmarks[PoseLandmarkType.rightKnee]!;
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle]!;
    if ((leftKnee.x - leftAnkle.x).abs() > 40 ||
        (rightKnee.x - rightAnkle.x).abs() > 40) {
      return false;
    }
    if ((leftKnee.x - rightKnee.x).abs() > 100 ||
        (leftAnkle.x - rightAnkle.x).abs() > 100) {
      return false;
    }
    return true;
  }
  // Simple check: is user standing in frame (just presence of main joints)
  bool _isStandingInFrame(Map<PoseLandmarkType, PoseLandmark> landmarks) {
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
    return true;
  }
  CameraController? controller;
  bool isBusy = false;
  late Size size;
  int _cameraIndex = 0;
  int _counter = 0;
  late PoseDetector poseDetector;

  // Timer variables
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerExercise = false;
  bool _isExerciseCompleted = false;
  bool _timerStarted = false; // Flag to prevent multiple timer starts

  // Feedback text for real-time pose correction
  String _feedbackText = "";

  // Exercise start flow state
  bool _cameraInitializing = false;
  bool _showWelcomeScreen = true;
  double _userDetectionProgress = 0.0;
  String _currentInstruction = "";
  bool _waitingForUserInFrame = false;
  bool _userDetected = false;
  bool _showCountdown = false;
  int _countdown = 3;
  bool _exerciseStarted = false;
  int _standingFrames = 0;
  final int _requiredStandingFrames = 90; // 3 seconds at 30 FPS
  bool _countdownActive = false;
  int _countdownValue = 3;
  Timer? _countdownTimer;

  // Haptic feedback variables
  int _lastRepCount = 0; // Track previous rep count to detect increases

  @override
  void initState() {
    super.initState();
    _resetExerciseStates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeScreenMethod();
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    poseDetector.close();
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // Play rep count haptic feedback
  void _playRepCountHaptic() async {
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Error playing rep count haptic: $e');
    }
  }

  // Play exercise start haptic feedback
  void _playExerciseStartHaptic() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('Error playing exercise start haptic: $e');
    }
  }

  void _resetExerciseStates() {
    _counter = 0;
    _elapsedSeconds = 0;
    _isTimerExercise = false;
    _isExerciseCompleted = false;
    _timer?.cancel();
    _timerStarted = false; // Reset the flag
    // Reset exercise-specific states
    UpperBodyExercise.resetState();
    CoreExercise.resetState();
    LegExercise.resetState();
    FullBodyExercise.resetState();
  }

  void onNewCameraSelected() async {
    final previous = controller;
    if (previous != null) {
      await previous.dispose();
    }

    _cameraIndex = _cameraIndex == 0 ? 1 : 0;

    final CameraController cameraController = CameraController(
      main_utils.cameras[_cameraIndex],
      ResolutionPreset.medium,
      imageFormatGroup:
          Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
      enableAudio: false,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
    } catch (e) {
      print('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {});
    }

    cameraController.startImageStream((image) {
      if (!isBusy) {
        isBusy = true;
        img = image;
        doPoseEstimationOnFrame();
      }
    });
  }

  //TODO code to initialize the camera feed
  initializeCamera() async {
    //TODO initialize detector
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    poseDetector = PoseDetector(options: options);

    final CameraController cameraController = CameraController(
      main_utils.cameras[_cameraIndex],
      ResolutionPreset.high,
      imageFormatGroup:
          Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
      enableAudio: false,
    );

    controller = cameraController;

    try {
      await cameraController.initialize();
    } catch (e) {
      print('Error initializing camera: $e');
      return;
    }

    if (!mounted) return;

    setState(() {});

    cameraController.startImageStream((image) {
      if (!isBusy) {
        isBusy = true;
        img = image;
        doPoseEstimationOnFrame();
      }
    });
  }

  //TODO pose detection on a frame
  dynamic _scanResults;
  CameraImage? img;

  doPoseEstimationOnFrame() async {
    if (!_exerciseStarted && _waitingForUserInFrame) {
      // Only check for user in frame
      var inputImage = _inputImageFromCameraImage();
      if (inputImage != null) {
        final List<Pose> poses = await poseDetector.processImage(inputImage!);
        if (poses.isNotEmpty && _isStandingInFrame(poses.first.landmarks)) {
          _standingFrames++;
          if (_standingFrames >= _requiredStandingFrames && !_countdownActive) {
            _startStandingCountdown();
          }
        } else {
          _standingFrames = 0;
          if (_countdownActive) {
            _stopStandingCountdown();
          }
        }
      }
      isBusy = false;
      return;
    }
    if (!_exerciseStarted) {
      isBusy = false;
      return;
    }
    var inputImage = _inputImageFromCameraImage();
    if (inputImage != null) {
      final List<Pose> poses = await poseDetector.processImage(inputImage!);
      print("pose=" + poses.length.toString());
      _scanResults = poses;
      if (poses.length > 0) {
        final landmarks = poses.first.landmarks;

        var count = switch (widget.exerciseDataModel.category) {
          ExerciseCategory.upperBody => UpperBodyExercise.detectExercise(
            landmarks,
            widget.exerciseDataModel.type,
          ),
          ExerciseCategory.core => CoreExercise.detectExercise(
            landmarks,
            widget.exerciseDataModel.type,
          ),
          ExerciseCategory.legs => LegExercise.detectExercise(
            landmarks,
            widget.exerciseDataModel.type,
          ),
          ExerciseCategory.fullBody => FullBodyExercise.detectExercise(
            landmarks,
            widget.exerciseDataModel.type,
          ),
        };

        _counter = count;
        print('Current rep count:  [33m$_counter [0m, Target: ${widget.targetReps}');
        if (!_isTimerExercise) {
          _checkRepCompletion();
        }
        setState(() {
          // Check if rep count increased and play sound
          if (_counter > _lastRepCount) {
            _playRepCountHaptic();
            _lastRepCount = _counter;
          }
          // Clear feedback text when person is detected
          _feedbackText = "";
        });
      } else {
        setState(() {
          _feedbackText = "No person detected. Please get in frame.";
        });
      }
    }
    setState(() {
      _scanResults;
      isBusy = false;
    });
  }

  String getExerciseCount() => _counter.toString();

  // Timer methods
  void _startTimer() {
    // Prevent multiple timer starts
    if (_timerStarted) {
      print('Timer already started, skipping... - Current elapsed: $_elapsedSeconds');
      return;
    }

    // Cancel any existing timer first
    _timer?.cancel();

    // Reset elapsed seconds to ensure we start from 0
    _elapsedSeconds = 0;

    // Mark timer as started
    _timerStarted = true;

    print('Timer started - Exercise: ${widget.exerciseDataModel.title} - Elapsed: $_elapsedSeconds');
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && !_isExerciseCompleted) {
        final newElapsed = _elapsedSeconds + 1;
        setState(() {
          _elapsedSeconds = newElapsed;
        });
        print('Timer tick: ${_formatTime(_elapsedSeconds)} - Exercise: ${widget.exerciseDataModel.title} - Raw seconds: $_elapsedSeconds');

        // Check if timer exercise is completed
        if (widget.targetMinutes != null &&
            _elapsedSeconds >= widget.targetMinutes! * 60) {
          _completeExercise();
        }
      } else {
        // Cancel timer if widget is no longer mounted or exercise completed
        timer.cancel();
        if (!mounted) {
          print('Timer cancelled - Widget not mounted');
        } else if (_isExerciseCompleted) {
          print('Timer cancelled - Exercise completed');
        }
      }
    });
  }

  // Check if rep-based exercise is completed
  void _checkRepCompletion() {
    if (widget.targetReps != null && _counter >= widget.targetReps!) {
      _completeExercise();
    }
  }

  // Complete exercise and navigate to completion page
  void _completeExercise() async {
    if (!_isExerciseCompleted) {
      _isExerciseCompleted = true;
      _timer?.cancel();
      _timerStarted = false; // Reset timer flag

      // Calculate calories burned
      int caloriesBurned = 0;
      if (widget.targetReps != null) {
        // For rep-based exercises, calories burned = reps * caloriesPerRep
        caloriesBurned = (_counter * widget.exerciseDataModel.caloriesPerRep).round();
      } else if (widget.targetMinutes != null) {
        // For timer-based exercises, calories burned = total time * caloriesPerHour
        int caloriesPerHour = _getExerciseCalories(widget.exerciseDataModel.type);
        double timeInHours = _elapsedSeconds / 3600.0;
        caloriesBurned = (caloriesPerHour * timeInHours).round();
      }

      // Save exercise history to Firestore
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final AuthService authService = AuthService();
          await authService.saveExerciseHistory(
            email: currentUser.email!,
            exerciseName: widget.exerciseDataModel.title,
            exerciseCategory: widget.exerciseDataModel.category.toString(),
            completedReps: _counter,
            completedTime: _elapsedSeconds,
            caloriesBurned: caloriesBurned,
          );
        }
      } catch (e) {
        print('Error saving exercise history: $e');
      }

      // Pop this screen with true result to indicate completion
      Navigator.pop(context, true);

      // Show completion page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseCompletionPage(
            exerciseDataModel: widget.exerciseDataModel,
            completedReps: _counter,
            completedTime: _elapsedSeconds,
            isTimerExercise: _isTimerExercise,
          ),
        ),
      );
    }
  }

  // Calculate calories burned based on exercise type and duration
  int _calculateCaloriesBurned() {
    int caloriesPerHour = _getExerciseCalories(widget.exerciseDataModel.type);
    double timeInHours = _elapsedSeconds / 3600.0;
    return (caloriesPerHour * timeInHours).round();
  }

  // Get exercise calories per hour
  int _getExerciseCalories(ExerciseType type) {
    switch (type) {
      case ExerciseType.StandardPushUp:
        return 350;
      case ExerciseType.DumbbellBicepCurl:
        return 280;
      case ExerciseType.HammerCurl:
        return 290;
      case ExerciseType.DumbbellLateralRaises:
        return 250;
      case ExerciseType.PikePushUps:
        return 400;
      case ExerciseType.PullUp:
        return 500;
      case ExerciseType.Deadlift:
        return 600;
      case ExerciseType.HangingDeadRaise:
        return 400;
      case ExerciseType.BicycleCrunches:
        return 320;
      case ExerciseType.Plank:
        return 200;
      case ExerciseType.ToesToHeaven:
        return 200;
      case ExerciseType.Lunges:
        return 200;
      case ExerciseType.PistolSquats:
        return 280;
      case ExerciseType.Squats:
        return 380;
      case ExerciseType.WallSit:
        return 250;
      case ExerciseType.JumpingJacks:
        return 430;
      case ExerciseType.Burpees:
        return 450;
    }
  }

  // Format time for display
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Helper functions
  double calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    double a = distance(p2, p3);
    double b = distance(p1, p2);
    double c = distance(p1, p3);

    double angle = acos((b * b + a * a - c * c) / (2 * b * a)) * (180 / pi);
    return angle;
  }

  double distance(PoseLandmark p1, PoseLandmark p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
  }

  // Camera and image processing helpers
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
    final camera = main_utils.cameras[0];
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
        controller?.value.isInitialized != true) {
      return Text('');
    }
    final Size imageSize = Size(
      controller!.value.previewSize!.height,
      controller!.value.previewSize!.width,
    );
    CustomPainter painter = main_utils.PosePainter(imageSize, _scanResults, _cameraIndex);
    return CustomPaint(painter: painter);
  }

  // Improved welcome screen with better animations
  void _showWelcomeScreenMethod() {
    setState(() {
      _showWelcomeScreen = true;
      _currentInstruction = "Welcome! Let's get started with your  {widget.exerciseDataModel.title} exercise.";
    });
  }

  // Start the camera setup process
  void _startCameraSetup() {
    setState(() {
      _showWelcomeScreen = false;
      _cameraInitializing = true;
      _currentInstruction = "Initializing camera...";
    });
    // Add a small delay for smooth transition
    Timer(Duration(milliseconds: 800), () {
      initializeCamera().then((_) {
        setState(() {
          _cameraInitializing = false;
          _waitingForUserInFrame = true;
          _currentInstruction = "Please position yourself in the camera frame";
        });
      });
    });
  }

  void _startCountdown() {
    if (_exerciseStarted) return; // Prevent double countdown
    _countdown = 3;
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_exerciseStarted) { // If exercise started, stop countdown
        timer.cancel();
        setState(() {
          _showCountdown = false;
        });
        return;
      }
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _showCountdown = false;
          _exerciseStarted = true;
          _isTimerExercise = widget.targetMinutes != null;
          _waitingForUserInFrame = false;
          _countdownActive = false;
          _countdownValue = 3;
          _standingFrames = 0;
          // Start timer for all exercises to track total time
          _startTimer();
        });
        print('Exercise started: ${widget.exerciseDataModel.title} - Timer exercise: $_isTimerExercise');
        _playExerciseStartHaptic(); // Play start sound when exercise begins
      }
    });
  }

  void _startStandingCountdown() {
    if (_exerciseStarted || _countdownActive) return; // Prevent double countdown
    setState(() {
      _countdownActive = true;
      _countdownValue = 3;
    });
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_exerciseStarted) { // If exercise started, stop countdown
        timer.cancel();
        setState(() {
          _countdownActive = false;
          _countdownValue = 3;
        });
        return;
      }
      if (_countdownValue > 1) {
        setState(() {
          _countdownValue--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdownActive = false;
          _waitingForUserInFrame = false;
          _showCountdown = true;
        });
        _startCountdown(); // Start the exercise countdown
      }
    });
  }

  void _stopStandingCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownActive = false;
      _countdownValue = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top section - Camera feed box
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                  border: Border.all(
                    color: widget.exerciseDataModel.color.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.exerciseDataModel.color.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      // Welcome Screen
                      if (_showWelcomeScreen)
                        _buildWelcomeScreen(),
                      // Camera Initializing Screen
                      if (_cameraInitializing)
                        _buildCameraInitializingScreen(),
                      // Camera preview (when ready)
                      if (controller != null && controller!.value.isInitialized && !_showWelcomeScreen && !_cameraInitializing)
                        Positioned.fill(
                          child: AspectRatio(
                            aspectRatio: controller!.value.aspectRatio,
                            child: CameraPreview(controller!),
                          ),
                        ),
                      // Pose detection overlay
                      if (controller != null && !_showWelcomeScreen && !_cameraInitializing)
                        Positioned.fill(
                          child: buildResult(),
                        ),
                      // User Detection Screen
                      if (_waitingForUserInFrame && !_showWelcomeScreen && !_cameraInitializing)
                        _buildUserDetectionScreen(),
                      // Exercise countdown
                      if (_showCountdown)
                        _buildCountdownScreen(),
                      // Exercise UI (existing code for when exercise is running)
                      // Timer in top-left corner (only when exercise started)
                      if (_exerciseStarted)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _formatTime(_elapsedSeconds),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Exercise Info Overlay (when exercise started)
                      if (_exerciseStarted && widget.targetReps != null)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            width: 200,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Exercise Name
                                Text(
                                  widget.exerciseDataModel.title,
                                  style: GoogleFonts.montserrat(
                                    color: widget.exerciseDataModel.color,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                
                                // Target Reps
                                Row(
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Target: ${widget.targetReps} reps",
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                
                                // Current Progress
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Done: $_counter reps",
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                
                                // Calories
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: Color(0xFFF97316),
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Calories: ${_calculateCurrentCalories()}",
                                      style: GoogleFonts.montserrat(
                                        color: Color(0xFFF97316),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Camera switch button
                      if (main_utils.cameras.length > 1 && _exerciseStarted)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: widget.exerciseDataModel.color,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: onNewCameraSelected,
                              icon: Icon(
                                Icons.flip_camera_ios_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      // Feedback box (bottom center)
                      if (_exerciseStarted)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: _feedbackText.isNotEmpty
                              ? Container(
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _feedbackText,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom section - Centered progress indicator box (unchanged)
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: widget.exerciseDataModel.color,
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: widget.targetMinutes != null
                            ? (_elapsedSeconds / (widget.targetMinutes! * 60)).clamp(0.0, 1.0)
                            : (widget.targetReps != null && widget.targetReps! > 0
                                ? (_counter / widget.targetReps!).clamp(0.0, 1.0)
                                : 0.0),
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      Center(
                        child: Text(
                          widget.targetMinutes != null
                              ? _formatTime(_elapsedSeconds)
                              : getExerciseCount(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Welcome Screen Widget
  Widget _buildWelcomeScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.exerciseDataModel.color.withOpacity(0.8),
            widget.exerciseDataModel.color.withOpacity(0.4),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (value * 0.5),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 60,
                    color: widget.exerciseDataModel.color,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 32),
          // Exercise title with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1200),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Text(
                    widget.exerciseDataModel.title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          // Description with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1400),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "Get ready to start your workout! We'll guide you through the setup process.",
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 48),
          // Start button with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1600),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: value,
                  child: Container(
                    width: 200,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _startCameraSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: widget.exerciseDataModel.color,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        shadowColor: Colors.white.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 24),
                          SizedBox(width: 8),
                          Text(
                            "Let's Start!",
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Camera Initializing Screen Widget
  Widget _buildCameraInitializingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            widget.exerciseDataModel.color.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(widget.exerciseDataModel.color),
            ),
          ),
          SizedBox(height: 32),
          Text(
            "Setting up camera...",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Please wait while we prepare everything for you",
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Enhanced User Detection Screen Widget
  Widget _buildUserDetectionScreen() {
    // Calculate detection progress based on standing frames
    _userDetectionProgress = (_standingFrames / _requiredStandingFrames).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            widget.exerciseDataModel.color.withOpacity(0.2),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header with instructions
          Padding(
            padding: EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Column(
              children: [
                Icon(
                  Icons.person_pin_circle_outlined,
                  size: 60,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  "Position Yourself",
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Stand fully in the camera frame and hold still",
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Spacer(),
          // Progress section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                // Progress circle with animation
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  tween: Tween<double>(
                    begin: 0,
                    end: _userDetectionProgress,
                  ),
                  builder: (context, value, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 8,
                              ),
                            ),
                          ),
                          // Animated progress circle
                          ShaderMask(
                            shaderCallback: (rect) {
                              return SweepGradient(
                                startAngle: 0.0,
                                endAngle: 2 * 3.14,
                                stops: [value, value],
                                center: Alignment.center,
                                colors: [
                                  _countdownActive ? Colors.orange : widget.exerciseDataModel.color,
                                  Colors.transparent,
                                ],
                                transform: GradientRotation(-3.14 / 2),
                              ).createShader(rect);
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 8,
                                ),
                              ),
                            ),
                          ),
                          // Center content
                          if (_countdownActive)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "$_countdownValue",
                                  style: GoogleFonts.montserrat(
                                    color: Colors.orange,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else
                            TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 300),
                              tween: Tween<double>(
                                begin: 0.8,
                                end: _userDetectionProgress > 0.1 ? 1.0 : 0.8,
                              ),
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Icon(
                                    _userDetectionProgress > 0.1 ? Icons.person : Icons.person_outline,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),
                // Status text with animation
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Text(
                    _countdownActive
                        ? "Hold steady..."
                        : _userDetectionProgress > 0.1
                            ? "Great! Keep holding your position"
                            : "Step into the camera view",
                    key: ValueKey<String>(_countdownActive
                        ? "countdown"
                        : _userDetectionProgress > 0.1
                            ? "holding"
                            : "step"),
                    style: GoogleFonts.montserrat(
                      color: _countdownActive ? Colors.orange : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (!_countdownActive && _userDetectionProgress > 0.1)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      "Hold for ${((_requiredStandingFrames - _standingFrames) / 30).ceil()} more seconds",
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Spacer(),
          // Camera switch button
          if (main_utils.cameras.length > 1)
            Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.exerciseDataModel.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.exerciseDataModel.color.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: onNewCameraSelected,
                  icon: Icon(
                    Icons.flip_camera_ios_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  iconSize: 56,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Enhanced Countdown Screen Widget
  Widget _buildCountdownScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            widget.exerciseDataModel.color.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Get Ready!",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 40),
          // Animated countdown number
          TweenAnimationBuilder<double>(
            key: ValueKey(_countdown),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (value * 0.5),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "$_countdown",
                      style: GoogleFonts.montserrat(
                        color: widget.exerciseDataModel.color,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 40),
          Text(
            widget.exerciseDataModel.title,
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Add this method to calculate current calories
  int _calculateCurrentCalories() {
    if (widget.targetReps != null) {
      // For rep-based exercises
      return (_counter * widget.exerciseDataModel.caloriesPerRep).round();
    } else {
      // For timer-based exercises
      int caloriesPerHour = _getExerciseCalories(widget.exerciseDataModel.type);
      double timeInHours = _elapsedSeconds / 3600.0;
      return (caloriesPerHour * timeInHours).round();
    }
  }
}
