import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pose_detection_realtime/screen/daily_page.dart';
import 'package:pose_detection_realtime/screen/user_profile_page.dart';
import 'auth_service.dart';
import 'newMainPage.dart';

class ExerciseHistoryPage extends StatefulWidget {
  @override
  State<ExerciseHistoryPage> createState() => _ExerciseHistoryPageState();
}

class _ExerciseHistoryPageState extends State<ExerciseHistoryPage> with TickerProviderStateMixin {
  int selectedTabIndex = 1;  // Set "Activity" tab as selected by default
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> exerciseHistory = [];
  bool isLoading = true;
  String userEmail = "";
  String? errorMessage;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadExerciseHistory();

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

  Future<void> _loadExerciseHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        userEmail = currentUser.email ?? "";
        print('Current user email: $userEmail');

        // Fetch all exercise history for debugging
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('exercise_history')
            .orderBy('completed_at', descending: true)
            .get();

        List<Map<String, dynamic>> allHistory = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        List<Map<String, dynamic>> userHistory = allHistory.where((entry) {
          final entryEmail = (entry['email'] ?? '').toString().trim().toLowerCase();
          final userEmailLower = userEmail.trim().toLowerCase();
          return entryEmail == userEmailLower;
        }).toList();

        print('All emails in DB:');
        for (var entry in allHistory) {
          print('  ${entry['email']}');
        }
        print('User-matched records: ${userHistory.length}');

        setState(() {
          exerciseHistory = userHistory;
          isLoading = false;
          if (userHistory.isEmpty) {
            errorMessage = "No exercise history found for your account.";
          }
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "User not authenticated";
        });
      }
    } catch (e) {
      print('Error loading exercise history: $e');
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load exercise history: " + e.toString();
      });
    }
  }

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
        break; // Stay on current page
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

  String _formatTime(dynamic timeValue) {
    int seconds = 0;
    if (timeValue is int) {
      seconds = timeValue;
    } else if (timeValue is double) {
      seconds = timeValue.toInt();
    } else if (timeValue is String) {
      seconds = int.tryParse(timeValue) ?? 0;
    }

    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'upperbody':
        return Color(0xFF4A90E2);
      case 'core':
        return Color(0xFF7B68EE);
      case 'legs':
        return Color(0xFF32CD32);
      case 'fullbody':
        return Color(0xFFFF6B6B);
      default:
        return Color(0xFF6B7280);
    }
  }

  String _formatCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'upperbody':
        return 'Upper Body';
      case 'fullbody':
        return 'Full Body';
      case 'core':
        return 'Core';
      case 'legs':
        return 'Legs';
      default:
        return category;
    }
  }

  int _safeParseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildStatsHeader() {
    int totalExercises = exerciseHistory.length;
    int totalCalories = exerciseHistory.fold(0, (sum, exercise) => sum + _safeParseInt(exercise['calories_burned']));
    int totalTime = exerciseHistory.fold(0, (sum, exercise) => sum + _safeParseInt(exercise['completed_time']));

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF97316),
            Color(0xFFF97316).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF97316).withOpacity(0.3),
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
                "Exercise History",
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _loadExerciseHistory,
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "$totalExercises exercises completed",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.fitness_center,
                value: "$totalExercises",
                label: "Exercises",
              ),
              _buildStatCard(
                icon: Icons.local_fire_department,
                value: "$totalCalories",
                label: "Calories",
              ),
              _buildStatCard(
                icon: Icons.timer,
                value: _formatTime(totalTime),
                label: "Total Time",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
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
                'Loading exercise history...',
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
                            "Activity",
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Your workout journey",
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

                // Content
                Expanded(
                  child: errorMessage != null
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Error loading data",
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            errorMessage!,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadExerciseHistory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text("Retry"),
                        ),
                      ],
                    ),
                  )
                      : exerciseHistory.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No exercises yet",
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Complete your first exercise to see it here",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                      : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Stats header
                        _buildStatsHeader(),

                        // Exercise list title
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Recent Workouts",
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Exercise history cards
                        RefreshIndicator(
                          onRefresh: _loadExerciseHistory,
                          color: Color(0xFFF97316),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            itemCount: exerciseHistory.length,
                            itemBuilder: (context, index) {
                              final exercise = exerciseHistory[index];

                              // Robust null/type checking for all fields
                              DateTime date = DateTime.now();
                              final completedAt = exercise['completed_at'];
                              if (completedAt is Timestamp) {
                                date = completedAt.toDate();
                              } else if (completedAt is DateTime) {
                                date = completedAt;
                              }

                              final exerciseName = (exercise['exercise_name'] ?? 'Unknown Exercise').toString();
                              final exerciseCategory = (exercise['exercise_category'] ?? 'Unknown').toString();
                              final completedReps = _safeParseInt(exercise['completed_reps']);
                              final completedTime = _safeParseInt(exercise['completed_time']);
                              final caloriesBurned = _safeParseInt(exercise['calories_burned']);

                              final categoryColor = _getCategoryColor(exerciseCategory);

                              return Container(
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      // Colored accent bar
                                      Container(
                                        width: 6,
                                        decoration: BoxDecoration(
                                          color: categoryColor,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            bottomLeft: Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                      // Main content
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Header with exercise name and category
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      exerciseName,
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: categoryColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      _formatCategoryName(exerciseCategory),
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: categoryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),
                                              // Stats row
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: [
                                                  _buildStatItem(
                                                    icon: Icons.fitness_center,
                                                    value: "$completedReps",
                                                    label: "Reps",
                                                    color: Color(0xFFF97316),
                                                  ),
                                                  _buildStatItem(
                                                    icon: Icons.timer,
                                                    value: _formatTime(completedTime),
                                                    label: "Time",
                                                    color: Color(0xFF32CD32),
                                                  ),
                                                  _buildStatItem(
                                                    icon: Icons.local_fire_department,
                                                    value: "$caloriesBurned",
                                                    label: "Calories",
                                                    color: Color(0xFFFF6B6B),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),
                                              // Date
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    _formatDate(date),
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 12,
                                                      color: Colors.grey[500],
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
                              );
                            },
                          ),
                        ),
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

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}