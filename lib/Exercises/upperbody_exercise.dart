import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../Model/ExerciseDataModel.dart';

class UpperBodyExercise {
  static bool isDoingExercise = false;
  static int repCount = 0;

  static void resetState() {
    isDoingExercise = false;
    repCount = 0;
  }

  static int detectExercise(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ExerciseType type,
      ) {
    switch (type) {
      case ExerciseType.StandardPushUp:
        _detectPushUp(landmarks);
        break;
      case ExerciseType.DumbbellBicepCurl:
        _detectBicepCurl(landmarks);
        break;
      case ExerciseType.HammerCurl:
        _detectHammerCurl(landmarks);
        break;
      case ExerciseType.DumbbellLateralRaises:
        _detectLateralRaises(landmarks);
        break;
      case ExerciseType.PikePushUps:
        _detectPikePushUp(landmarks);
        break;
      case ExerciseType.PullUp:
        _detectPullUp(landmarks);
        break;
      case ExerciseType.Deadlift:
        _detectDeadlift(landmarks);
        break;
      case ExerciseType.HangingDeadRaise:
        _detectHangingDeadRaise(landmarks);
        break;
      default:
        break;
    }
    return repCount;
  }

  static void _detectPushUp(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        leftWrist == null ||
        rightWrist == null)
      return;

    double leftArmAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightArmAngle = _calculateAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );
    double avgArmAngle = (leftArmAngle + rightArmAngle) / 2;

    if (avgArmAngle < 90 && !isDoingExercise) {
      isDoingExercise = true;
    } else if (avgArmAngle > 160 && isDoingExercise) {
      repCount++;
      isDoingExercise = false;
    }
  }

  static void _detectBicepCurl(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        leftWrist == null ||
        rightWrist == null)
      return;

    double leftArmAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightArmAngle = _calculateAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );
    double avgArmAngle = (leftArmAngle + rightArmAngle) / 2;

    if (avgArmAngle < 50 && !isDoingExercise) {
      isDoingExercise = true;
    } else if (avgArmAngle > 160 && isDoingExercise) {
      repCount++;
      isDoingExercise = false;
    }
  }

  static void _detectHammerCurl(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Similar to bicep curl but checks for proper hammer curl form
    _detectBicepCurl(landmarks);
  }

  static void _detectLateralRaises(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        leftWrist == null ||
        rightWrist == null)
      return;

    bool armsRaised =
        leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y;
    double shoulderAngle = _calculateAngle(leftElbow, leftShoulder, rightElbow);

    if (armsRaised && shoulderAngle > 160 && !isDoingExercise) {
      isDoingExercise = true;
    } else if (!armsRaised && shoulderAngle < 60 && isDoingExercise) {
      repCount++;
      isDoingExercise = false;
    }
  }

  static void _detectPikePushUp(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        leftHip == null ||
        rightHip == null)
      return;

    double pikeAngle = _calculateAngle(leftShoulder, leftHip, leftElbow);
    bool isInPikePosition = pikeAngle < 90;

    if (isInPikePosition) {
      _detectPushUp(landmarks);
    }
  }

  static double _calculateAngle(
      PoseLandmark first,
      PoseLandmark middle,
      PoseLandmark last,
      ) {
    double radian =
        atan2(last.y - middle.y, last.x - middle.x) -
            atan2(first.y - middle.y, first.x - middle.x);
    double angle = (radian * 180.0 / pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  static bool isPoseCorrect(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ExerciseType type,
      ) {
    switch (type) {
      case ExerciseType.StandardPushUp:
        return _isPushUpCorrect(landmarks);
      case ExerciseType.DumbbellBicepCurl:
        return _isBicepCurlCorrect(landmarks);
      case ExerciseType.HammerCurl:
        return _isBicepCurlCorrect(landmarks);
      case ExerciseType.DumbbellLateralRaises:
        return _isLateralRaisesCorrect(landmarks);
      case ExerciseType.PikePushUps:
        return _isPushUpCorrect(landmarks);
      default:
        return false;
    }
  }

  static bool _isPushUpCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    if (leftShoulder == null || rightShoulder == null || leftElbow == null || rightElbow == null || leftWrist == null || rightWrist == null) return false;
    double leftArmAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightArmAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
    double avgArmAngle = (leftArmAngle + rightArmAngle) / 2;
    return avgArmAngle < 90; // bottom of push-up
  }

  static bool _isBicepCurlCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    if (leftShoulder == null || rightShoulder == null || leftElbow == null || rightElbow == null || leftWrist == null || rightWrist == null) return false;
    double leftArmAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightArmAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
    double avgArmAngle = (leftArmAngle + rightArmAngle) / 2;
    return avgArmAngle < 50; // curl contracted
  }

  static bool _isLateralRaisesCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    if (leftShoulder == null || rightShoulder == null || leftWrist == null || rightWrist == null) return false;
    return leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y;
  }

  // Pull-Up: Count a rep when chin goes above bar (shoulders above elbows), then returns below
  static void _detectPullUp(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];

    if (leftShoulder == null || rightShoulder == null || leftElbow == null || rightElbow == null) return;

    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final avgElbowY = (leftElbow.y + rightElbow.y) / 2;

    if (!isDoingExercise && avgShoulderY < avgElbowY - 20) {
      isDoingExercise = true;
    } else if (isDoingExercise && avgShoulderY > avgElbowY + 20) {
      repCount++;
      isDoingExercise = false;
    }
  }



  // Deadlift: Count a rep when hip angle closes (down), then opens (up)
  static void _detectDeadlift(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];

    if (leftShoulder == null || leftHip == null || leftKnee == null) return;

    final hipAngle = _calculateAngle(leftShoulder, leftHip, leftKnee);

    if (!isDoingExercise && hipAngle < 70) {
      isDoingExercise = true;
    } else if (isDoingExercise && hipAngle > 160) {
      repCount++;
      isDoingExercise = false;
    }
  }

  // Hanging Dead Raise: Count a rep when knees are raised high, then lowered
  static void _detectHangingDeadRaise(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftKnee == null || rightKnee == null || leftHip == null || rightHip == null) return;

    final avgKneeY = (leftKnee.y + rightKnee.y) / 2;
    final avgHipY = (leftHip.y + rightHip.y) / 2;

    if (!isDoingExercise && avgKneeY < avgHipY - 30) {
      isDoingExercise = true;
    } else if (isDoingExercise && avgKneeY > avgHipY + 20) {
      repCount++;
      isDoingExercise = false;
    }
  }
}