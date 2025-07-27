import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pose_detection_realtime/Model/ExerciseDataModel.dart';
import 'package:pose_detection_realtime/screen/newMainPage.dart';

import '../DetectionScreen.dart';

class ExerciseCompletionPage extends StatelessWidget {
  final ExerciseDataModel exerciseDataModel;
  final int completedReps;
  final int completedTime;
  final bool isTimerExercise;

  const ExerciseCompletionPage({
    Key? key,
    required this.exerciseDataModel,
    required this.completedReps,
    required this.completedTime,
    required this.isTimerExercise,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                exerciseDataModel.color.withOpacity(0.8),
                Colors.black,
              ],
            ),
          ),
          child: Column(
            children: [
              // Top section with celebration
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Celebration icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.celebration,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Congratulations text
                      Text(
                        "Congratulations!",
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      
                      Text(
                        "You completed your exercise!",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Results section
              Expanded(
                flex: 3,
                child: Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Exercise name
                      Text(
                        exerciseDataModel.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      
                      // Results grid
                      Row(
                        children: [
                          // Left result card
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: exerciseDataModel.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    isTimerExercise ? Icons.timer : Icons.fitness_center,
                                    size: 32,
                                    color: exerciseDataModel.color,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    isTimerExercise ? "Time" : "Reps",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    isTimerExercise 
                                        ? _formatTime(completedTime)
                                        : completedReps.toString(),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: exerciseDataModel.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          
                          // Right result card
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Color(0xFFF97316).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 32,
                                    color: Color(0xFFF97316),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "Calories",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _calculateCalories().round().toString(),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF97316),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Additional metrics row (show both time and reps if available)
                      if (!isTimerExercise && completedTime > 0)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.timer,
                                size: 28,
                                color: Colors.grey[600],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Total Time",
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatTime(completedTime),
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 32),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: exerciseDataModel.color),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'Back to Home',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: exerciseDataModel.color,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Restart the same exercise
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetectionScreen(
                                      exerciseDataModel: exerciseDataModel,
                                      targetReps: isTimerExercise ? null : completedReps,
                                      targetMinutes: isTimerExercise ? (completedTime ~/ 60) : null,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: exerciseDataModel.color,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'Do Again',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Format time for display
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // Calculate calories burned
  int _calculateCalories() {
    int caloriesPerHour = _getExerciseCalories(exerciseDataModel.type);
    double timeInHours = isTimerExercise 
        ? completedTime / 3600.0 
        : (completedReps * 3) / 3600.0; // Assume 3 seconds per rep
    
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
} 