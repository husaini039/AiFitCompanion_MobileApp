import 'package:flutter/material.dart';

// Define all exercise categories
enum ExerciseType {
  // Upper Body - Biceps
  DumbbellBicepCurl,
  HammerCurl,

  // Upper Body - Shoulders
  DumbbellLateralRaises,
  PikePushUps,

  // Upper Body - Chest
  StandardPushUp,

  // Upper Body - New
  PullUp,
  Deadlift,
  HangingDeadRaise,

  // Core - Abs
  BicycleCrunches,
  Plank,
  ToesToHeaven,

  // Leg - /Hamstrings
  PistolSquats,

  // Leg - Quads
  Squats,
  Lunges,
  WallSit,

  // Full Body - Cardio
  JumpingJacks,

  // Full Body - HIIT
  Burpees,
}

class ExerciseDataModel {
  String title;
  String image;
  Color color;
  ExerciseType type;
  double caloriesPerRep; // Add a caloriesPerRep field to ExerciseDataModel

  ExerciseDataModel(this.title, this.image, this.color, this.type, this.caloriesPerRep);

  static List<ExerciseDataModel> getAllExercises() {
    List<ExerciseDataModel> exercises = [];

    // Upper Body Exercises
    exercises.addAll([
      ExerciseDataModel(
        'Standard Push-up',
        'assets/exercises/pushup.gif',
        getCategoryColor(ExerciseCategory.upperBody),
        ExerciseType.StandardPushUp,
        0.5, // Add caloriesPerRep for Standard Push-up
      ),
      ExerciseDataModel(
        'Dumbbell Bicep Curl',
        'assets/exercises/bicep_curl.gif',
        getCategoryColor(ExerciseCategory.upperBody),
        ExerciseType.DumbbellBicepCurl,
        0.6, // Add caloriesPerRep for Dumbbell Bicep Curl
      ),
      ExerciseDataModel(
        'Hammer Curl',
        'assets/exercises/hammer_curl.gif',
        getCategoryColor(ExerciseCategory.upperBody),
        ExerciseType.HammerCurl,
        0.7, // Add caloriesPerRep for Hammer Curl
      ),
      ExerciseDataModel(
        'Lateral Raises',
        'assets/exercises/lateral_raises.gif',
        getCategoryColor(ExerciseCategory.upperBody),
        ExerciseType.DumbbellLateralRaises,
        0.5, // Add caloriesPerRep for Lateral Raises
      ),
      ExerciseDataModel(
        'Pike Push-ups',
        'assets/exercises/pike_pushup.gif',
        getCategoryColor(ExerciseCategory.upperBody),
        ExerciseType.PikePushUps,
        0.8, // Add caloriesPerRep for Pike Push-ups
      ),
      // New Upper Body Exercises
      ExerciseDataModel(
        'Pull-Up',
        'assets/exercises/pullup.gif',
        getCategoryColor(ExerciseCategory.upperBody),
        ExerciseType.PullUp,
        1.0, // Add caloriesPerRep for Pull-Up
      ),
      ExerciseDataModel(
        'Deadlift',
        'assets/exercises/deadlift.gif',
        getCategoryColor(ExerciseCategory.upperBody),
        ExerciseType.Deadlift,
        1.5, // Add caloriesPerRep for Deadlift
      ),
      ExerciseDataModel(
        'Hanging Dead Raise',
        'assets/exercises/hanging_dead_raise.gif',
        getCategoryColor(ExerciseCategory.upperBody),
        ExerciseType.HangingDeadRaise,
        0.8, // Add caloriesPerRep for Hanging Dead Raise
      ),
    ]);

    // Core Exercises
    exercises.addAll([
      ExerciseDataModel(
        'Bicycle Crunches',
        'assets/exercises/bicycle_crunches.gif',
        getCategoryColor(ExerciseCategory.core),
        ExerciseType.BicycleCrunches,
        0.4, // Add caloriesPerRep for Bicycle Crunches
      ),
      ExerciseDataModel(
        'Plank',
        'assets/exercises/plank.gif',
        getCategoryColor(ExerciseCategory.core),
        ExerciseType.Plank,
        0.3, // Add caloriesPerRep for Plank
      ),
      ExerciseDataModel(
        'Toes to Heaven',
        'assets/exercises/toes_to_heaven.gif',
        getCategoryColor(ExerciseCategory.core),
        ExerciseType.ToesToHeaven,
        0.6, // Add caloriesPerRep for Toes to Heaven
      ),
    ]);

    // Leg Exercises
    exercises.addAll([
      ExerciseDataModel(
        'Squats',
        'assets/exercises/squats.gif',
        getCategoryColor(ExerciseCategory.legs),
        ExerciseType.Squats,
        0.7, // Add caloriesPerRep for Squats
      ),
      ExerciseDataModel(
        'Lunges',
        'assets/exercises/lunges.gif',
        getCategoryColor(ExerciseCategory.legs),
        ExerciseType.Lunges,
        0.8, // Add caloriesPerRep for Lunges
      ),
      ExerciseDataModel(
        'Pistol Squats',
        'assets/exercises/pistol_bridge.gif',
        getCategoryColor(ExerciseCategory.legs),
        ExerciseType.PistolSquats,
        0.5, // Add caloriesPerRep for
      ),
      ExerciseDataModel(
        'Wall Sit',
        'assets/exercises/wall_sit.gif',
        getCategoryColor(ExerciseCategory.legs),
        ExerciseType.WallSit,
        0.4, // Add caloriesPerRep for Wall Sit
      ),
    ]);

    // Full Body Exercises
    exercises.addAll([
      ExerciseDataModel(
        'Jumping Jacks',
        'assets/exercises/jumping_jacks.gif',
        getCategoryColor(ExerciseCategory.fullBody),
        ExerciseType.JumpingJacks,
        0.3, // Add caloriesPerRep for Jumping Jacks
      ),
      ExerciseDataModel(
        'Burpees',
        'assets/exercises/burpees.gif',
        getCategoryColor(ExerciseCategory.fullBody),
        ExerciseType.Burpees,
        0.6, // Add caloriesPerRep for Mountain Climbers
      ),
    ]);

    return exercises;
  }

  // Get category based on exercise type
  ExerciseCategory get category {
    switch (type) {
      case ExerciseType.StandardPushUp:
      case ExerciseType.DumbbellBicepCurl:
      case ExerciseType.HammerCurl:
      case ExerciseType.DumbbellLateralRaises:
      case ExerciseType.PikePushUps:
      case ExerciseType.PullUp:
      case ExerciseType.Deadlift:
      case ExerciseType.HangingDeadRaise:
        return ExerciseCategory.upperBody;

      case ExerciseType.BicycleCrunches:
      case ExerciseType.Plank:
      case ExerciseType.ToesToHeaven:
        return ExerciseCategory.core;

      case ExerciseType.Squats:
      case ExerciseType.Lunges:
      case ExerciseType.PistolSquats:
      case ExerciseType.WallSit:
        return ExerciseCategory.legs;

      case ExerciseType.JumpingJacks:
      case ExerciseType.Burpees:
        return ExerciseCategory.fullBody;
    }
  }

  // Get color based on category
  static Color getCategoryColor(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.upperBody:
        return Color(0xff005f9c); // Blue
      case ExerciseCategory.core:
        return Color(0xffcebe1c); // Purple
      case ExerciseCategory.legs:
        return Color(0xff228B22); // Green
      case ExerciseCategory.fullBody:
        return Color(0xffDC143C); // Red
    }
  }
}

// Define exercise categories
enum ExerciseCategory { upperBody, core, legs, fullBody }