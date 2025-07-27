import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../Model/ExerciseDataModel.dart';

class CoreExercise {
  static bool isDoingExercise = false;
  static int repCount = 0;
  static int plankDuration = 0;
  static DateTime? plankStartTime;

  static void resetState() {
    isDoingExercise = false;
    repCount = 0;
    plankDuration = 0;
    plankStartTime = null;
  }

  static int detectExercise(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ExerciseType type,
      ) {
    switch (type) {
      case ExerciseType.BicycleCrunches:
        _detectBicycleCrunches(landmarks);
        return repCount;
      case ExerciseType.Plank:
        _detectPlank(landmarks);
        return plankDuration;
      case ExerciseType.ToesToHeaven:
        _detectToesToHeaven(landmarks);
        return repCount;
      default:
        return 0;
    }
  }

  static void _detectBicycleCrunches(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftShoulder == null ||
        rightShoulder == null)
      return;

    double kneeAngleDiff = (leftKnee.y - rightKnee.y).abs();
    bool kneeAlternating = kneeAngleDiff > 50;
    bool shouldersLifted =
        leftShoulder.y < leftHip.y && rightShoulder.y < rightHip.y;

    if (kneeAlternating && shouldersLifted && !isDoingExercise) {
      isDoingExercise = true;
    } else if (!kneeAlternating && shouldersLifted && isDoingExercise) {
      repCount++;
      isDoingExercise = false;
    }
  }

  static void _detectPlank(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null ||
        leftAnkle == null ||
        rightAnkle == null)
      return;

    double spineAngle = _calculateAngle(leftShoulder, leftHip, leftAnkle);
    bool isSpineStraight = spineAngle > 160;
    bool isParallel = (leftHip.y - leftShoulder.y).abs() < 30;

    if (isSpineStraight && isParallel) {
      if (!isDoingExercise) {
        isDoingExercise = true;
        plankStartTime = DateTime.now();
      }
      if (plankStartTime != null) {
        plankDuration = DateTime.now().difference(plankStartTime!).inSeconds;
      }
    } else {
      isDoingExercise = false;
      plankStartTime = null;
    }
  }

  static void _detectToesToHeaven(Map<PoseLandmarkType, PoseLandmark> landmarks) {
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
        rightShoulder == null)
      return;

    // Calculate average positions
    double avgHipY = (leftHip.y + rightHip.y) / 2;
    double avgKneeY = (leftKnee.y + rightKnee.y) / 2;
    double avgAnkleY = (leftAnkle.y + rightAnkle.y) / 2;
    double avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;

    // Check if person is lying on their back (shoulders on ground, hips elevated slightly)
    bool isLyingDown = avgShoulderY > avgHipY - 50;

    // Check if legs are raised (ankles higher than hips)
    bool legsRaised = avgAnkleY < avgHipY - 80;

    // Check if legs are relatively straight (knees close to the line between hips and ankles)
    bool legsStraight = (avgKneeY - avgHipY).abs() < (avgAnkleY - avgHipY).abs() + 50;

    bool properToesToHeavenForm = isLyingDown && legsRaised && legsStraight;

    if (properToesToHeavenForm && !isDoingExercise) {
      isDoingExercise = true;
    } else if (!properToesToHeavenForm && isDoingExercise) {
      repCount++;
      isDoingExercise = false;
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
      case ExerciseType.BicycleCrunches:
        return _isBicycleCrunchesCorrect(landmarks);
      case ExerciseType.Plank:
        return _isPlankCorrect(landmarks);
      case ExerciseType.ToesToHeaven:
        return _isToesToHeavenCorrect(landmarks);
      default:
        return false;
    }
  }

  static bool _isBicycleCrunchesCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    if (leftHip == null || rightHip == null || leftKnee == null || rightKnee == null || leftShoulder == null || rightShoulder == null) return false;
    double kneeAngleDiff = (leftKnee.y - rightKnee.y).abs();
    bool kneeAlternating = kneeAngleDiff > 50;
    bool shouldersLifted = leftShoulder.y < leftHip.y && rightShoulder.y < rightHip.y;
    return kneeAlternating && shouldersLifted;
  }

  static bool _isPlankCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null || leftAnkle == null || rightAnkle == null) return false;
    double spineAngle = _calculateAngle(leftShoulder, leftHip, leftAnkle);
    bool isSpineStraight = spineAngle > 160;
    bool isParallel = (leftHip.y - leftShoulder.y).abs() < 30;
    return isSpineStraight && isParallel;
  }

  static bool _isToesToHeavenCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftHip == null || rightHip == null || leftKnee == null ||
        rightKnee == null || leftAnkle == null || rightAnkle == null ||
        leftShoulder == null || rightShoulder == null) return false;

    // Calculate average positions
    double avgHipY = (leftHip.y + rightHip.y) / 2;
    double avgKneeY = (leftKnee.y + rightKnee.y) / 2;
    double avgAnkleY = (leftAnkle.y + rightAnkle.y) / 2;
    double avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;

    // Check if person is lying on their back (shoulders on ground, hips elevated slightly)
    bool isLyingDown = avgShoulderY > avgHipY - 50;

    // Check if legs are raised (ankles higher than hips)
    bool legsRaised = avgAnkleY < avgHipY - 80;

    // Check if legs are relatively straight (knees close to the line between hips and ankles)
    bool legsStraight = (avgKneeY - avgHipY).abs() < (avgAnkleY - avgHipY).abs() + 50;

    return isLyingDown && legsRaised && legsStraight;
  }
}