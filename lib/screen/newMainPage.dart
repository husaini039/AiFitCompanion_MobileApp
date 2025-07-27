import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pose_detection_realtime/screen/age_selector.dart';
import 'package:pose_detection_realtime/screen/purpose_screen.dart';
import 'package:pose_detection_realtime/screen/user_profile_page.dart';
import 'package:pose_detection_realtime/screen/exercise_history.dart';
import 'auth_service.dart';
import 'package:intl/intl.dart';
import 'package:pose_detection_realtime/Model/ExerciseDataModel.dart';
import 'package:pose_detection_realtime/screen/login_page.dart';
import 'package:pose_detection_realtime/DetectionScreen.dart';

import 'daily_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String userName = "User";
  String currentDate = "";
  String userAge = "";
  bool isLoading = true;
  int selectedCategoryIndex = 0;
  int selectedTabIndex = 0;
  late List<ExerciseDataModel> exercises;
  final List<String> categories = [
    "Upper Body",
    "Core",
    "Legs",
    "Full Body",
  ];

  // Scroll controllers for smooth scrolling
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setCurrentDate();
    exercises = ExerciseDataModel.getAllExercises();

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
    _mainScrollController.dispose();
    _categoryScrollController.dispose();
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

  Future<void> _loadUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Map<String, dynamic>? userProfile = await _authService.getUserProfile(currentUser.email!);
        if (userProfile != null) {
          setState(() {
            userName = userProfile['username'] ?? "User";
            userAge = userProfile['age']?.toString() ?? "";
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Enhanced bottom navigation bar with better animations
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
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ExerciseHistoryPage(),
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
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => DailyPage(),
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

  // Enhanced exercise card with better animations and visual appeal
  Widget _buildNewExerciseCard(ExerciseDataModel exercise) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showExerciseDetailsDialog(exercise);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enhanced illustration section with gradient overlay
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getExerciseBackgroundColor(exercise.category),
                    _getExerciseBackgroundColor(exercise.category).withOpacity(0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Subtle pattern overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Exercise icon with better styling
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getExerciseIcon(exercise.category),
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Decorative elements
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Enhanced text section
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.title,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getExerciseDescription(exercise.type),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFFF97316).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Color(0xFFF97316),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "${_getExerciseCalories(exercise.type)}",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF97316),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced category button with better animations
  Widget _buildCategoryButton(String title, IconData icon, int index, Color color) {
    bool isSelected = selectedCategoryIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          selectedCategoryIndex = index;
        });

        // Auto-scroll to show selected category better
        if (_categoryScrollController.hasClients) {
          double targetOffset = index * 120.0; // Approximate button width
          _categoryScrollController.animateTo(
            targetOffset,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? color : Color(0xFFF5F5F5),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 20,
              height: 20,
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
            SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 200),
              style: GoogleFonts.montserrat(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              child: Text(title),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetailsDialog(ExerciseDataModel exercise) {
    bool isTimerExercise = _isTimerExercise(exercise.type);
    int reps = 10;
    int minutes = 1;

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

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF97316).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Color(0xFFF97316),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "${_getExerciseCalories(exercise.type)} Kcal/rep",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF97316),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

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
                    );
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

  bool _isTimerExercise(ExerciseType type) {
    switch (type) {
      case ExerciseType.Plank:
      case ExerciseType.WallSit:
        return true;
      default:
        return false;
    }
  }

  Widget _buildExerciseCard(ExerciseDataModel exercise) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetectionScreen(exerciseDataModel: exercise),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Icon(
                  _getExerciseIcon(exercise.category),
                  size: 50,
                  color: _getCategoryColor(exercise.category),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getExerciseDescription(exercise.type),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ExerciseCategory _getSelectedCategory() {
    switch (selectedCategoryIndex) {
      case 0:
        return ExerciseCategory.upperBody;
      case 1:
        return ExerciseCategory.core;
      case 2:
        return ExerciseCategory.legs;
      case 3:
        return ExerciseCategory.fullBody;
      default:
        return ExerciseCategory.upperBody;
    }
  }

  List<ExerciseDataModel> _getFilteredExercises() {
    ExerciseCategory selectedCategory = _getSelectedCategory();
    return exercises.where((e) => e.category == selectedCategory).toList();
  }

  Color _getCategoryColor(ExerciseCategory category) {
    return ExerciseDataModel.getCategoryColor(category);
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
        return 3; // 3 calories per rep
      case ExerciseType.DumbbellBicepCurl:
        return 2; // 2 calories per rep
      case ExerciseType.HammerCurl:
        return 2; // 2 calories per rep
      case ExerciseType.DumbbellLateralRaises:
        return 1; // 1 calorie per rep
      case ExerciseType.PikePushUps:
        return 4; // 4 calories per rep
      case ExerciseType.PullUp:
        return 5; // 5 calories per rep
      case ExerciseType.Deadlift:
        return 6; // 6 calories per rep
      case ExerciseType.HangingDeadRaise:
        return 4; // 4 calories per rep
      case ExerciseType.BicycleCrunches:
        return 3; // 3 calories per rep
      case ExerciseType.Plank:
        return 1; // 1 calorie per rep (held for a time period)
      case ExerciseType.PistolSquats:
        return 2; // 2 calories per rep
      case ExerciseType.Squats:
        return 4; // 4 calories per rep
      case ExerciseType.WallSit:
        return 1; // 1 calorie per rep (held for a time period)
      case ExerciseType.JumpingJacks:
        return 5; // 5 calories per rep
      case ExerciseType.Burpees:
        return 6; // 6 calories per rep
      default:
        return 0; // Default case for unknown exercises
    }
  }




  @override
  Widget build(BuildContext context) {
    // Set the status bar color to black
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.black, // Status bar background color
        statusBarIconBrightness:
            Brightness.light, // Status bar icons (e.g., time, battery) color
      ),
    );
    return Scaffold(
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: Color(0xFFFFFFFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Color(0xFFF9F9F9),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IntrinsicHeight(
                          child: Container(
                            padding: const EdgeInsets.only(top: 45, bottom: 19),
                            margin: const EdgeInsets.only(bottom: 23),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(40), // Bottom-left corner radius
                                bottomRight: Radius.circular(40), // Bottom-right corner radius
                              ),
                              color: Colors.black,
                            ),
                            child: Column(
                              children: [
                                // User Information Section - Centered
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Row(
                                    children: [


                                      // User Text Information
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                currentDate,
                                                style: GoogleFonts.montserrat(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 4),
                                              child: isLoading
                                                  ? SizedBox(
                                                      width: 120,
                                                      height: 24,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.3),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                      ),
                                                    )
                                                  : Text(
                                                      "Hello, $userName",
                                                      style: GoogleFonts.montserrat(
                                                        color: Color(0xFFFFFFFF),
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                            Container(
                                              child: isLoading
                                                  ? SizedBox(
                                                      width: 60,
                                                      height: 12,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.3),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                      ),
                                                    )
                                                  : Text(
                                                      "${userAge} years old",
                                                      style: GoogleFonts.montserrat(
                                                        color: Color(0xFFFFFFFF),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Notification Icon
                                      InkWell(
                                        onTap: () async {
                                          await _authService.signOut();

                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => LoginPage()),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Color(0xFF7B7B7B),
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: Stack(
                                            children: [
                                              Icon(
                                                Icons.logout,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 20),

                                // Search Bar - Centered with same horizontal padding
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: InkWell(
                                    onTap: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (context) {
                                          String searchQuery = "";
                                          List<ExerciseDataModel> allExercises = ExerciseDataModel.getAllExercises();
                                          List<ExerciseDataModel> filteredExercises = allExercises;
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                title: TextField(
                                                  autofocus: true,
                                                  decoration: InputDecoration(
                                                    hintText: "Search for exercise...",
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      searchQuery = value;
                                                      filteredExercises = allExercises
                                                          .where((e) => e.title.toLowerCase().contains(searchQuery.toLowerCase()))
                                                          .toList();
                                                    });
                                                  },
                                                ),
                                                content: Container(
                                                  width: double.maxFinite,
                                                  height: 350,
                                                  child: filteredExercises.isEmpty
                                                      ? Center(child: Text("No exercises found."))
                                                      : ListView.builder(
                                                          itemCount: filteredExercises.length,
                                                          itemBuilder: (context, index) {
                                                            final exercise = filteredExercises[index];
                                                            return ListTile(
                                                              leading: Icon(Icons.fitness_center, color: exercise.color),
                                                              title: Text(exercise.title),
                                                              onTap: () {
                                                                Navigator.of(context).pop();
                                                                _showExerciseDetailsDialog(exercise);
                                                              },
                                                            );
                                                          },
                                                        ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: Text("Close"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: Color(0xFF666A73),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 15,
                                      ),
                                      width: double.infinity,
                                      child: Row(
                                        children: [
                                          Expanded(
                                                                                      child: Text(
                                            "Search for exercise",
                                            style: GoogleFonts.montserrat(
                                              color: Color(0xFFFFFFFF),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(40),
                                            ),
                                            width: 24,
                                            height: 24,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(40),
                                              child: Image.network(
                                                "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/szObxWHKSw/4qxz5yxa_expires_30_days.png",
                                                fit: BoxFit.fill,
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
                        ),
                        IntrinsicHeight(
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 14,
                              left: 11,
                              right: 11,
                            ),
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    width: double.infinity,
                                    child: Text(
                                      "Browse Category",
                                      style: GoogleFonts.montserrat(
                                        color: Color(0xFF000000),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    child: GestureDetector(
                                      onTap: () async {
                                        await showDialog(
                                          context: context,
                                          builder: (context) {
                                            List<ExerciseDataModel> allExercises = ExerciseDataModel.getAllExercises();
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              title: Text(
                                                "All Exercises",
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Container(
                                                width: double.maxFinite,
                                                height: 400,
                                                child: ListView.builder(
                                                  itemCount: allExercises.length,
                                                  itemBuilder: (context, index) {
                                                    final exercise = allExercises[index];
                                                    return ListTile(
                                                      leading: Icon(Icons.fitness_center, color: exercise.color),
                                                      title: Text(exercise.title),
                                                      subtitle: Text(categories[exercise.category.index]),
                                                      onTap: () {
                                                        Navigator.of(context).pop();
                                                        _showExerciseDetailsDialog(exercise);
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: Text("Close"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Text(
                                        "See All",
                                        style: GoogleFonts.montserrat(
                                          color: Color(0xFFF97316),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: 20,
                                left: 16,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedCategoryIndex = 0;
                                        });
                                        print('Upper Body pressed');
                                        // Add your category selection logic here
                                      },
                                      child: IntrinsicWidth(
                                        child: IntrinsicHeight(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: selectedCategoryIndex == 0
                                                  ? Color(0xFF478DDE) // Orange when selected
                                                  : Color(0xFFE7E7E7), // Gray when not selected
                                            ),
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                              left: 12,
                                              right: 12,
                                            ),
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(40),
                                                  ),
                                                  margin: const EdgeInsets.only(
                                                    right: 8,
                                                  ),
                                                  width: 20,
                                                  height: 20,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(40),
                                                    child: Icon(
                                                      Icons.fitness_center,
                                                      size: 20,
                                                      color: selectedCategoryIndex == 0
                                                          ? Colors.white // White icon when selected
                                                          : Color(0xFF000000), // Black icon when not selected
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  "Upper Body",
                                                  style: GoogleFonts.montserrat(
                                                    color: selectedCategoryIndex == 0
                                                        ? Colors.white // White text when selected
                                                        : Color(0xFF000000), // Black text when not selected
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Core
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedCategoryIndex = 1;
                                        });
                                        print('Core pressed');
                                        // Add your category selection logic here
                                      },
                                      child: IntrinsicWidth(
                                        child: IntrinsicHeight(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: selectedCategoryIndex == 1
                                                  ? Color(0xFF7767E8)
                                                  : Color(0xFFE7E7E7),
                                            ),
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                              left: 12,
                                              right: 12,
                                            ),
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(40),
                                                  ),
                                                  margin: const EdgeInsets.only(
                                                    right: 8,
                                                  ),
                                                  width: 20,
                                                  height: 20,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(40),
                                                    child: Icon(
                                                      Icons.accessibility_new,
                                                      size: 20,
                                                      color: selectedCategoryIndex == 1
                                                          ? Colors.white
                                                          : Color(0xFF000000),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  "Core",
                                                  style: GoogleFonts.montserrat(
                                                    color: selectedCategoryIndex == 1
                                                        ? Colors.white
                                                        : Color(0xFF000000),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Legs
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedCategoryIndex = 2;
                                        });
                                        print('Legs pressed');
                                        // Add your category selection logic here
                                      },
                                      child: IntrinsicWidth(
                                        child: IntrinsicHeight(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: selectedCategoryIndex == 2
                                                  ? Color(0xFF31CA31)
                                                  : Color(0xFFE7E7E7),
                                            ),
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                              left: 12,
                                              right: 12,
                                            ),
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(40),
                                                  ),
                                                  margin: const EdgeInsets.only(
                                                    right: 8,
                                                  ),
                                                  width: 20,
                                                  height: 20,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(40),
                                                    child: Icon(
                                                      Icons.directions_walk,
                                                      size: 20,
                                                      color: selectedCategoryIndex == 2
                                                          ? Colors.white
                                                          : Color(0xFF000000),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  "Legs",
                                                  style: GoogleFonts.montserrat(
                                                    color: selectedCategoryIndex == 2
                                                        ? Colors.white
                                                        : Color(0xFF000000),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Full Body
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedCategoryIndex = 3;
                                        });
                                        print('Full Body pressed');
                                        // Add your category selection logic here
                                      },
                                      child: IntrinsicWidth(
                                        child: IntrinsicHeight(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: selectedCategoryIndex == 3
                                                  ? Color(0xFFFB696A)
                                                  : Color(0xFFE7E7E7),
                                            ),
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 10,
                                              left: 12,
                                              right: 12,
                                            ),
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(40),
                                                  ),
                                                  margin: const EdgeInsets.only(
                                                    right: 8,
                                                  ),
                                                  width: 20,
                                                  height: 20,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(40),
                                                    child: Icon(
                                                      Icons.sports_gymnastics,
                                                      size: 20,
                                                      color: selectedCategoryIndex == 3
                                                          ? Colors.white
                                                          : Color(0xFF000000),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  "Full Body",
                                                  style: GoogleFonts.montserrat(
                                                    color: selectedCategoryIndex == 3
                                                        ? Colors.white
                                                        : Color(0xFF000000),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Exercise Grid Section
                        Container(
                          margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section Title
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  "${categories[selectedCategoryIndex]} Exercises",
                                  style: GoogleFonts.montserrat(
                                    color: Color(0xFF000000),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Exercise Grid with new card design
                              Container(
                                height: 400, // Fixed height to enable scrolling
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: _getFilteredExercises().length,
                                  itemBuilder: (context, index) {
                                    final exercise = _getFilteredExercises()[index];
                                    return _buildNewExerciseCard(exercise);
                                  },
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
