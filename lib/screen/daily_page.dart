import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import '../Model/ExerciseDataModel.dart';
import '../DetectionScreen.dart';
import 'exercise_history.dart';
import 'newMainPage.dart';
import 'user_profile_page.dart';
import 'dart:math';

class DailyPage extends StatefulWidget {
  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userProfile;
  List<ExerciseDataModel> todayPlan = [];
  Set<int> completedIndexes = Set();
  bool isLoading = true;
  String currentDate = "";
  String userName = "User";
  String userAge = "";
  String userGender = "";
  int selectedTabIndex = 2; // Daily tab is selected
  int currentDayNumber = 1;
  DateTime? accountCreationDate;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setCurrentDate();
    _loadUserAndPlan();

    // Initialize animations
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _setCurrentDate() {
    final now = DateTime.now();
    final formatter = DateFormat('MMM dd, yyyy');
    setState(() {
      currentDate = formatter.format(now);
    });
  }

  Future<void> _loadUserAndPlan() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userProfile = await _authService.getUserProfile(user.email!);
        if (userProfile != null) {
          setState(() {
            userName = userProfile!['username'] ?? "User";
            userAge = userProfile!['age']?.toString() ?? "";
            userGender = userProfile!['gender'] ?? "";
          });

          // Get account creation date and calculate current day
          await _calculateDayNumber(user);
        }

        // Load today's plan and completion status
        await _loadDailyPlan();
        await _loadCompletionStatus();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _calculateDayNumber(User user) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Try to get creation date from user document
        if (userData['createdAt'] != null) {
          Timestamp createdAtTimestamp = userData['createdAt'];
          accountCreationDate = createdAtTimestamp.toDate();
        } else {
          // If no creation date in user document, use Firebase Auth creation time
          accountCreationDate = user.metadata.creationTime;

          // Update user document with creation date for future reference
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.email)
              .update({
            'createdAt': Timestamp.fromDate(accountCreationDate!),
          });
        }

        // Calculate day number based on account creation date
        final today = DateTime.now();
        final creationDate = DateTime(
          accountCreationDate!.year,
          accountCreationDate!.month,
          accountCreationDate!.day,
        );
        final currentDate = DateTime(today.year, today.month, today.day);

        setState(() {
          currentDayNumber = currentDate.difference(creationDate).inDays + 1;
        });
      }
    } catch (e) {
      print('Error calculating day number: $e');
      // Fallback to day 1 if there's an error
      setState(() {
        currentDayNumber = 1;
      });
    }
  }

  Future<void> _loadDailyPlan() async {
    setState(() {
      todayPlan = _generateDailyPlan(userProfile, currentDayNumber);
    });
  }

  Future<void> _loadCompletionStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .collection('daily_progress')
            .doc(today)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          List<dynamic> completed = data['completed_exercises'] ?? [];
          setState(() {
            completedIndexes = completed.cast<int>().toSet();
          });
        }
      }
    } catch (e) {
      print('Error loading completion status: $e');
    }
  }

  Future<void> _saveCompletionStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .collection('daily_progress')
            .doc(today)
            .set({
          'completed_exercises': completedIndexes.toList(),
          'total_exercises': todayPlan.length,
          'completion_percentage': (completedIndexes.length / todayPlan.length * 100).round(),
          'date': today,
          'day_number': currentDayNumber,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving completion status: $e');
    }
  }

  List<ExerciseDataModel> _generateDailyPlan(Map<String, dynamic>? profile, int day) {
    final allExercises = ExerciseDataModel.getAllExercises();
    final random = Random(day);

    // Filter exercises based on user profile if available
    List<ExerciseDataModel> filteredExercises = allExercises;

    if (profile != null) {
      String? gender = profile['gender'];
      int? age = profile['age'];

      // Simple filtering logic - you can make this more sophisticated
      if (age != null && age > 50) {
        // For older users, prefer low-impact exercises
        filteredExercises = allExercises.where((exercise) =>
        exercise.type != ExerciseType.JumpingJacks &&
            exercise.type != ExerciseType.Burpees
        ).toList();
      }
    }

    // Shuffle and pick 4 exercises
    final shuffled = List<ExerciseDataModel>.from(filteredExercises)..shuffle(random);
    return shuffled.take(4).toList();
  }

  // Modified: Remove the manual toggle and only mark complete through exercise completion
  void _markExerciseCompleted(int index) async {
    setState(() {
      completedIndexes.add(index);
    });

    // Save to Firestore
    await _saveCompletionStatus();

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  // Bottom navigation (same as MainScreen)
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, "Home"),
              _buildNavItem(1, Icons.favorite_outline, Icons.favorite, "Activity"),
              _buildNavItem(2, Icons.calendar_today_outlined, Icons.calendar_today, "Calendar"),
              _buildNavItem(3, Icons.person_outline, Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    bool isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          selectedTabIndex = index;
        });
        _handleTabNavigation(index);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF97316).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFFF97316) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? filledIcon : outlineIcon,
                size: isSelected ? 18 : 22,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
            SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 200),
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Color(0xFFF97316) : Colors.black54,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTabNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(Tween(begin: Offset(-1.0, 0.0), end: Offset.zero)),
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 300),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ExerciseHistoryPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(Tween(begin: Offset(-1.0, 0.0), end: Offset.zero)),
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 300),
          ),
        );
        break;
      case 2:
        break; // Stay on current page
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => UserProfilePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(Tween(begin: Offset(1.0, 0.0), end: Offset.zero)),
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 300),
          ),
        );
        break;
    }
  }

  Widget _buildProgressHeader() {
    double completionPercentage = todayPlan.isEmpty ? 0 : (completedIndexes.length / todayPlan.length);
    bool isCompleted = completionPercentage >= 1.0;

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted ? [
            Colors.green,
            Colors.green.withOpacity(0.8),
          ] : [
            Color(0xFFF97316),
            Color(0xFFF97316).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isCompleted ? Colors.green.withOpacity(0.3) : Color(0xFFF97316).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompleted ? "Challenge Complete!" : "Today's Challenge",
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "Day $currentDayNumber",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          if (isCompleted) ...[
            // Completion message
            Row(
              children: [
                Icon(Icons.celebration, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Nice! Wait for tomorrow's new exercises!",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              "All exercises completed for today",
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ] else ...[
            Text(
              "${completedIndexes.length}/${todayPlan.length} Exercises Completed",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 12),
            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: completionPercentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "${(completionPercentage * 100).round()}% Complete",
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseDataModel exercise, int index) {
    bool isCompleted = completedIndexes.contains(index);

    return GestureDetector(
      onTap: isCompleted ? null : () => _showExerciseDialog(exercise, index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Completion checkbox (now just for display)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.grey.shade400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isCompleted
                  ? Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            SizedBox(width: 16),

            // Exercise icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getExerciseBackgroundColor(exercise.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getExerciseIcon(exercise.category),
                color: _getExerciseBackgroundColor(exercise.category),
                size: 30,
              ),
            ),
            SizedBox(width: 16),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isCompleted ? Colors.green.shade700 : Colors.black87,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getExerciseDescription(exercise.type),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department,
                          color: Color(0xFFF97316), size: 16),
                      SizedBox(width: 4),
                      Text(
                        "${_getExerciseCalories(exercise.type)} cal",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF97316),
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.timer_outlined,
                          color: Colors.grey.shade600, size: 16),
                      SizedBox(width: 4),
                      Text(
                        _isTimerExercise(exercise.type) ? "2 min" : "10 reps",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action button
            Icon(
              isCompleted ? Icons.check_circle : Icons.play_circle_outline,
              color: isCompleted ? Colors.green : Color(0xFFF97316),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDialog(ExerciseDataModel exercise, int index) {
    bool isTimerExercise = _isTimerExercise(exercise.type);
    int reps = 10;
    int minutes = 2;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 20,
              title: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getExerciseBackgroundColor(exercise.category),
                          _getExerciseBackgroundColor(exercise.category).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      _getExerciseIcon(exercise.category),
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    exercise.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getExerciseDescription(exercise.type),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),

                  if (isTimerExercise) ...[
                    Text(
                      "Set Timer (minutes):",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (minutes > 1) {
                              setState(() {
                                minutes--;
                              });
                            }
                          },
                          icon: Icon(Icons.remove_circle_outline),
                          color: exercise.color,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: exercise.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$minutes min",
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: exercise.color,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              minutes++;
                            });
                          },
                          icon: Icon(Icons.add_circle_outline),
                          color: exercise.color,
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      "Number of Reps:",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (reps > 1) {
                              setState(() {
                                reps--;
                              });
                            }
                          },
                          icon: Icon(Icons.remove_circle_outline),
                          color: exercise.color,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: exercise.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$reps reps",
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: exercise.color,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              reps++;
                            });
                          },
                          icon: Icon(Icons.add_circle_outline),
                          color: exercise.color,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetectionScreen(
                          exerciseDataModel: exercise,
                          targetReps: isTimerExercise ? null : reps,
                          targetMinutes: isTimerExercise ? minutes : null,
                        ),
                      ),
                    ).then((result) {
                      // Only mark as completed if the exercise was actually completed
                      if (result == true) { // Assuming DetectionScreen returns true when exercise is completed
                        _markExerciseCompleted(index);
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: exercise.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 4,
                  ),
                  child: Text(
                    'Start Exercise',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            );
          },
        );
      },
    );
  }

  // Helper methods (same as MainScreen)
  bool _isTimerExercise(ExerciseType type) {
    switch (type) {
      case ExerciseType.Plank:
      case ExerciseType.WallSit:
        return true;
      default:
        return false;
    }
  }

  IconData _getExerciseIcon(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.upperBody:
        return Icons.fitness_center;
      case ExerciseCategory.core:
        return Icons.accessibility_new;
      case ExerciseCategory.legs:
        return Icons.directions_walk;
      case ExerciseCategory.fullBody:
        return Icons.sports_gymnastics;
    }
  }

  String _getExerciseDescription(ExerciseType type) {
    switch (type) {
      case ExerciseType.StandardPushUp:
        return "Classic chest and triceps exercise";
      case ExerciseType.DumbbellBicepCurl:
        return "Biceps isolation exercise";
      case ExerciseType.HammerCurl:
        return "Biceps and forearm exercise";
      case ExerciseType.DumbbellLateralRaises:
        return "Shoulder isolation exercise";
      case ExerciseType.PikePushUps:
        return "Advanced shoulder exercise";
      case ExerciseType.BicycleCrunches:
        return "Dynamic core exercise";
      case ExerciseType.Plank:
        return "Core stability exercise";
      case ExerciseType.ToesToHeaven:
        return "Core Activation";
      case ExerciseType.Lunges:
        return "Works the leg muscles";
      case ExerciseType.PistolSquats:
        return "Press the leg!";
      case ExerciseType.Squats:
        return "Lower body compound exercise";
      case ExerciseType.WallSit:
        return "Quad endurance exercise";
      case ExerciseType.JumpingJacks:
        return "Full body cardio exercise";
      case ExerciseType.Burpees:
        return "Dynamic full body HIIT exercise";
      case ExerciseType.PullUp:
        return "Upper body pulling exercise for back and biceps.";
      case ExerciseType.Deadlift:
        return "Full-body strength exercise focusing on posterior chain.";
      case ExerciseType.HangingDeadRaise:
        return "Core and hip flexor exercise performed hanging from a bar.";
    }
  }

  Color _getExerciseBackgroundColor(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.upperBody:
        return Color(0xFF4A90E2);
      case ExerciseCategory.core:
        return Color(0xFF7B68EE);
      case ExerciseCategory.legs:
        return Color(0xFF32CD32);
      case ExerciseCategory.fullBody:
        return Color(0xFFFF6B6B);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
              ),
              SizedBox(height: 20),
              Text(
                'Loading your daily plan...',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, $userName!",
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            currentDate,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Progress header
                        _buildProgressHeader(),

                        // Exercise list
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Today's Exercises",
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Exercise cards
                        ...todayPlan.asMap().entries.map((entry) {
                          int index = entry.key;
                          ExerciseDataModel exercise = entry.value;
                          return _buildExerciseCard(exercise, index);
                        }).toList(),

                        SizedBox(height: 100), // Extra space for bottom navigation
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}