import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../Model/ExerciseDataModel.dart';

class LegExercise {
  static bool isDoingExercise = false;
  static int repCount = 0;
  static int wallSitDuration = 0;
  static DateTime? wallSitStartTime;

  static void resetState() {
    isDoingExercise = false;
    repCount = 0;
    wallSitDuration = 0;
    wallSitStartTime = null;
  }

  static int detectExercise(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ExerciseType type,
      ) {
    switch (type) {
      case ExerciseType.Squats:
        _detectSquats(landmarks);
        return repCount;
      case ExerciseType.PistolSquats:
        _detectPistolSquats(landmarks);
        return repCount;
      case ExerciseType.Lunges:
        _detectLunges(landmarks);
        return repCount;
      case ExerciseType.WallSit:
        _detectWallSit(landmarks);
        return wallSitDuration;
      default:
        return 0;
    }
  }

  static void _detectSquats(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null)
      return;

    double leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    if (avgKneeAngle < 100 && !isDoingExercise) {
      isDoingExercise = true;
    } else if (avgKneeAngle > 160 && isDoingExercise) {
      repCount++;
      isDoingExercise = false;
    }
  }

  static void _detectPistolSquats(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null)
      return;

    double leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);

    // Check if one leg is significantly more bent than the other (indicating single-leg squat)
    double angleDifference = (leftKneeAngle - rightKneeAngle).abs();
    bool oneLegBent = angleDifference > 60; // One leg much more bent than the other

    // Check if one leg is in squat position (bent) and the other is extended
    bool leftLegSquat = leftKneeAngle < 100 && rightKneeAngle > 140;
    bool rightLegSquat = rightKneeAngle < 100 && leftKneeAngle > 140;
    bool inPistolPosition = oneLegBent && (leftLegSquat || rightLegSquat);

    // Check for return to standing position (both legs relatively straight)
    bool standingPosition = leftKneeAngle > 160 && rightKneeAngle > 160;

    if (inPistolPosition && !isDoingExercise) {
      isDoingExercise = true;
    } else if (standingPosition && isDoingExercise) {
      repCount++;
      isDoingExercise = false;
    }
  }

  static void _detectLunges(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null)
      return;

    double leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);

    // Calculate leg separation to detect lunge stance
    double legSeparation = (leftAnkle.x - rightAnkle.x).abs();
    double avgAnkleY = (leftAnkle.y + rightAnkle.y) / 2;
    double avgHipY = (leftHip.y + rightHip.y) / 2;

    // Check if in lunge position (one knee significantly more bent than the other)
    bool inLungePosition = (leftKneeAngle < 110 || rightKneeAngle < 110) &&
        legSeparation > 80 && // legs are separated
        avgHipY > avgAnkleY - 100; // person is in standing position

    if (inLungePosition && !isDoingExercise) {
      isDoingExercise = true;
    } else if (!inLungePosition && isDoingExercise) {
      repCount++;
      isDoingExercise = false;
    }
  }

  static void _detectWallSit(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null)
      return;

    double leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    bool properWallSitForm = avgKneeAngle >= 85 && avgKneeAngle <= 95;

    if (properWallSitForm) {
      if (!isDoingExercise) {
        isDoingExercise = true;
        wallSitStartTime = DateTime.now();
      }
      if (wallSitStartTime != null) {
        wallSitDuration =
            DateTime.now().difference(wallSitStartTime!).inSeconds;
      }
    } else {
      isDoingExercise = false;
      wallSitStartTime = null;
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
      case ExerciseType.Squats:
        return _isSquatCorrect(landmarks);
      case ExerciseType.PistolSquats:
        return _isPistolSquatCorrect(landmarks);
      case ExerciseType.Lunges:
        return _isLungeCorrect(landmarks);
      case ExerciseType.WallSit:
        return _isWallSitCorrect(landmarks);
      default:
        return false;
    }
  }

  static bool _isSquatCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    if (leftHip == null || rightHip == null || leftKnee == null || rightKnee == null || leftAnkle == null || rightAnkle == null) return false;
    double leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;
    return avgKneeAngle < 100; // bottom of squat
  }

  static bool _isPistolSquatCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || rightHip == null || leftKnee == null ||
        rightKnee == null || leftAnkle == null || rightAnkle == null) return false;

    double leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);

    // Check if one leg is significantly more bent than the other
    double angleDifference = (leftKneeAngle - rightKneeAngle).abs();
    bool oneLegBent = angleDifference > 60;

    // Check if one leg is in deep squat position while other is extended
    bool leftLegSquat = leftKneeAngle < 100 && rightKneeAngle > 140;
    bool rightLegSquat = rightKneeAngle < 100 && leftKneeAngle > 140;

    return oneLegBent && (leftLegSquat || rightLegSquat);
  }

  static bool _isLungeCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || rightHip == null || leftKnee == null ||
        rightKnee == null || leftAnkle == null || rightAnkle == null) return false;

    double leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);

    // Calculate leg separation to detect lunge stance
    double legSeparation = (leftAnkle.x - rightAnkle.x).abs();
    double avgAnkleY = (leftAnkle.y + rightAnkle.y) / 2;
    double avgHipY = (leftHip.y + rightHip.y) / 2;

    // Check if in proper lunge position
    bool properLungeStance = legSeparation > 80 && // legs are separated
        avgHipY > avgAnkleY - 100; // person is in standing position
    bool oneKneeBent = (leftKneeAngle < 110 || rightKneeAngle < 110);

    return properLungeStance && oneKneeBent;
  }

  static bool _isWallSitCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    if (leftHip == null || rightHip == null || leftKnee == null || rightKnee == null || leftAnkle == null || rightAnkle == null) return false;
    double leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;
    return avgKneeAngle >= 85 && avgKneeAngle <= 95;
  }
}