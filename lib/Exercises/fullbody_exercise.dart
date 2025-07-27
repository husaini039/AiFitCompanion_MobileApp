import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../Model/ExerciseDataModel.dart';

class FullBodyExercise {
  static bool isDoingExercise = false;
  static int repCount = 0;
  static int kneeLiftCount = 0;  // Count for knee lifts
  static bool leftKneeUp = false; // Track left knee status
  static bool rightKneeUp = false; // Track right knee status

  // Burpee specific state tracking
  static BurpeePhase currentBurpeePhase = BurpeePhase.standing;
  static bool burpeePhaseCompleted = false;
  static int phaseHoldFrames = 0; // Counter to ensure phase is held for minimum frames
  static const int minPhaseFrames = 3; // Minimum frames to confirm phase transition

  static void resetState() {
    isDoingExercise = false;
    repCount = 0;
    kneeLiftCount = 0;
    leftKneeUp = false;
    rightKneeUp = false;
    currentBurpeePhase = BurpeePhase.standing;
    burpeePhaseCompleted = false;
    phaseHoldFrames = 0;
  }

  static int detectExercise(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ExerciseType type,
      ) {
    switch (type) {
      case ExerciseType.JumpingJacks:
        _detectJumpingJacks(landmarks);
        return repCount;
      case ExerciseType.Burpees:
        _detectBurpees(landmarks);
        return repCount;
      default:
        return 0;
    }
  }

  static void _detectJumpingJacks(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ) {
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftAnkle == null ||
        rightAnkle == null ||
        leftWrist == null ||
        rightWrist == null ||
        leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) return;

    double legSpread = (rightAnkle.x - leftAnkle.x).abs();
    double armSpread = (rightWrist.x - leftWrist.x).abs();
    double shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();

    bool legsApart = legSpread > shoulderWidth * 1.5;
    bool armsUp = leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y;

    if (legsApart && armsUp && !isDoingExercise) {
      isDoingExercise = true;
    } else if (!legsApart && !armsUp && isDoingExercise) {
      repCount++;
      isDoingExercise = false;
    }
  }

  static void _detectMountainClimbers(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ) {
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
        rightShoulder == null) return;

    // Check if the person is in plank position
    bool isInPlank = _isInPlankPosition(landmarks);

    if (!isInPlank) return; // Only proceed if in a plank position

    double hipY = (leftHip.y + rightHip.y) / 2;

    // Detect left knee lift
    if (leftKnee.y < hipY && !leftKneeUp) {
      kneeLiftCount++;
      leftKneeUp = true;
    } else if (leftKnee.y >= hipY) {
      leftKneeUp = false;
    }

    // Detect right knee lift
    if (rightKnee.y < hipY && !rightKneeUp) {
      kneeLiftCount++;
      rightKneeUp = true;
    } else if (rightKnee.y >= hipY) {
      rightKneeUp = false;
    }

    // Count 1 rep for every 2 knee lifts (left or right)
    if (kneeLiftCount >= 2) {
      repCount++;
      kneeLiftCount = 0; // Reset count after 1 rep
    }
  }

  static void _detectBurpees(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];

    if (leftHip == null || rightHip == null || leftKnee == null ||
        rightKnee == null || leftAnkle == null || rightAnkle == null ||
        leftShoulder == null || rightShoulder == null ||
        leftWrist == null || rightWrist == null) return;

    // Calculate key body positions
    double hipY = (leftHip.y + rightHip.y) / 2;
    double shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    double kneeY = (leftKnee.y + rightKnee.y) / 2;
    double ankleY = (leftAnkle.y + rightAnkle.y) / 2;
    double wristY = (leftWrist.y + rightWrist.y) / 2;

    // Get current pose state
    bool isStanding = _isStandingBurpee(landmarks);
    bool isSquatting = _isSquattingBurpee(landmarks);
    bool isInPlank = _isPlankBurpee(landmarks);
    bool isJumping = _isJumpingBurpee(landmarks);

    switch (currentBurpeePhase) {
      case BurpeePhase.standing:
        if (isSquatting) {
          phaseHoldFrames++;
          if (phaseHoldFrames >= minPhaseFrames) {
            currentBurpeePhase = BurpeePhase.squat;
            phaseHoldFrames = 0;
          }
        } else {
          phaseHoldFrames = 0;
        }
        break;

      case BurpeePhase.squat:
        if (isInPlank) {
          phaseHoldFrames++;
          if (phaseHoldFrames >= minPhaseFrames) {
            currentBurpeePhase = BurpeePhase.plank;
            phaseHoldFrames = 0;
          }
        } else {
          phaseHoldFrames = 0;
        }
        break;

      case BurpeePhase.plank:
        if (isSquatting) {
          phaseHoldFrames++;
          if (phaseHoldFrames >= minPhaseFrames) {
            currentBurpeePhase = BurpeePhase.squat_return;
            phaseHoldFrames = 0;
          }
        } else {
          phaseHoldFrames = 0;
        }
        break;

      case BurpeePhase.squat_return:
        if (isJumping || isStanding) {
          phaseHoldFrames++;
          if (phaseHoldFrames >= minPhaseFrames) {
            repCount++;
            currentBurpeePhase = BurpeePhase.standing;
            phaseHoldFrames = 0;
          }
        } else {
          phaseHoldFrames = 0;
        }
        break;
    }
  }

  // Improved burpee position detection methods
  static bool _isStandingBurpee(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftHip == null || rightHip == null || leftKnee == null ||
        rightKnee == null || leftShoulder == null || rightShoulder == null) return false;

    double shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    double hipY = (leftHip.y + rightHip.y) / 2;
    double kneeY = (leftKnee.y + rightKnee.y) / 2;

    // Standing: shoulders above hips, hips above or near knees
    double bodyHeight = hipY - shoulderY;
    double hipToKnee = kneeY - hipY;

    return bodyHeight > 0 && hipToKnee < bodyHeight * 0.8;
  }

  static bool _isSquattingBurpee(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || rightHip == null || leftKnee == null ||
        rightKnee == null || leftAnkle == null || rightAnkle == null) return false;

    double hipY = (leftHip.y + rightHip.y) / 2;
    double kneeY = (leftKnee.y + rightKnee.y) / 2;
    double ankleY = (leftAnkle.y + rightAnkle.y) / 2;

    // Calculate knee angles for better squat detection
    double leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    // Squatting: hips close to knee level and knee angle is bent
    bool hipLowered = (hipY - kneeY).abs() < 50; // Adjust threshold as needed
    bool kneesBent = avgKneeAngle < 140; // Knees are bent

    return hipLowered && kneesBent;
  }

  static bool _isPlankBurpee(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder == null || rightShoulder == null || leftHip == null ||
        rightHip == null || leftKnee == null || rightKnee == null) return false;

    double shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    double hipY = (leftHip.y + rightHip.y) / 2;
    double kneeY = (leftKnee.y + rightKnee.y) / 2;

    // Plank: shoulders, hips, and knees should be roughly aligned horizontally
    double shoulderHipDiff = (shoulderY - hipY).abs();
    double hipKneeDiff = (hipY - kneeY).abs();

    // More lenient plank detection - focus on horizontal body alignment
    bool horizontalAlignment = shoulderHipDiff < 80 && hipKneeDiff < 80;
    bool lowPosition = shoulderY > hipY - 50; // Body is low to ground

    return horizontalAlignment || lowPosition;
  }

  static bool _isJumpingBurpee(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    if (leftWrist == null || rightWrist == null || leftShoulder == null ||
        rightShoulder == null || leftKnee == null || rightKnee == null) return false;

    double leftWristY = leftWrist.y;
    double rightWristY = rightWrist.y;
    double leftShoulderY = leftShoulder.y;
    double rightShoulderY = rightShoulder.y;
    double kneeY = (leftKnee.y + rightKnee.y) / 2;

    // Arms raised above shoulders OR knees extended (jumping up)
    bool armsRaised = leftWristY < leftShoulderY - 30 || rightWristY < rightShoulderY - 30;
    bool kneesExtended = leftKnee.y < kneeY - 20 || rightKnee.y < kneeY - 20;

    return armsRaised || kneesExtended;
  }

  static bool _isInPlankPosition(
      Map<PoseLandmarkType, PoseLandmark> landmarks,
      ) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftShoulder == null || leftHip == null || leftAnkle == null ||
        rightShoulder == null || rightHip == null || rightAnkle == null) return false;

    // Ensure arms are straight and the body is aligned in plank position
    double shoulderAngle = _calculateAngle(leftShoulder, rightShoulder, leftHip);
    double hipAngle = _calculateAngle(leftHip, rightHip, leftAnkle);

    // Check if the body is in a straight line (plank position)
    return shoulderAngle > 160 && hipAngle > 160;
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
      case ExerciseType.JumpingJacks:
        return _isJumpingJackCorrect(landmarks);
      case ExerciseType.Burpees:
        return _isBurpeeCorrect(landmarks);
      default:
        return false;
    }
  }

  static bool _isJumpingJackCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    if (leftAnkle == null || rightAnkle == null || leftWrist == null || rightWrist == null || leftShoulder == null || rightShoulder == null) return false;
    double legSpread = (rightAnkle.x - leftAnkle.x).abs();
    double armSpread = (rightWrist.x - leftWrist.x).abs();
    double shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();
    bool legsApart = legSpread > shoulderWidth * 1.5;
    bool armsUp = leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y;
    return legsApart && armsUp;
  }

  static bool _isMountainClimberCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null || leftKnee == null || rightKnee == null || leftAnkle == null || rightAnkle == null) return false;
    double hipY = (leftHip.y + rightHip.y) / 2;
    bool kneesUp = leftKnee.y < hipY && rightKnee.y < hipY;
    return kneesUp;
  }

  static bool _isBurpeeCorrect(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Check if the current burpee phase is being performed correctly
    switch (currentBurpeePhase) {
      case BurpeePhase.standing:
        return _isStandingBurpee(landmarks);
      case BurpeePhase.squat:
        return _isSquattingBurpee(landmarks);
      case BurpeePhase.plank:
        return _isPlankBurpee(landmarks);
      case BurpeePhase.squat_return:
        return _isSquattingBurpee(landmarks);
      default:
        return true; // More lenient for transitions
    }
  }

  // Get current burpee phase for UI feedback
  static String getCurrentBurpeePhase() {
    switch (currentBurpeePhase) {
      case BurpeePhase.standing:
        return "Ready - Squat down";
      case BurpeePhase.squat:
        return "Jump back to plank";
      case BurpeePhase.plank:
        return "Jump forward to squat";
      case BurpeePhase.squat_return:
        return "Jump up!";
      default:
        return "Keep going!";
    }
  }

  // Get progress percentage for current burpee
  static double getBurpeeProgress() {
    switch (currentBurpeePhase) {
      case BurpeePhase.standing:
        return 0.0;
      case BurpeePhase.squat:
        return 0.25;
      case BurpeePhase.plank:
        return 0.5;
      case BurpeePhase.squat_return:
        return 0.75;
      default:
        return 1.0;
    }
  }
}

// Enum for burpee phases (simplified)
enum BurpeePhase {
  standing,    // Ready position
  squat,       // Squat down
  plank,       // Plank position
  squat_return // Back to squat before jump
}