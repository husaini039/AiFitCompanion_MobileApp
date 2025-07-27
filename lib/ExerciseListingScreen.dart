// Inside Exerciselistingscreen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pose_detection_realtime/DetectionScreen.dart';
import 'package:pose_detection_realtime/Model/ExerciseDataModel.dart';
import 'package:pose_detection_realtime/screen/auth_service.dart';
import 'screen/login_page.dart';
import 'screen/age_selector.dart';  // Import the AgeSelectorScreen

class Exerciselistingscreen extends StatefulWidget {
  const Exerciselistingscreen({super.key});

  @override
  State<Exerciselistingscreen> createState() => _ExerciselistingscreenState();
}

class _ExerciselistingscreenState extends State<Exerciselistingscreen> {
  ExerciseCategory _selectedCategory = ExerciseCategory.upperBody;
  late List<ExerciseDataModel> exercises;
  AuthService _authService = AuthService();


  @override
  void initState() {
    super.initState();
    exercises = ExerciseDataModel.getAllExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removed AppBar title and back icon
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false, // Removes the default back button
      ),
      body: Column(
        children: [
          _buildProfileSection(),
          _buildCategorySelector(),
          Expanded(child: _buildExerciseGrid()),
        ],
      ),
    );
  }

  // Profile Section
  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile Image and Name
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage('assets/profile_image.png'), // Placeholder image
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Hello, Eren',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          // Notification Icon
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () async {
                  await _authService.signOut();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Category Selector
  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Browse Category" Text and "See All" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Browse Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Action for 'See All'
                  print('See all exercises');
                },
                child: const Text(
                  'See All',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Category Selector Buttons
          SizedBox(
            height: 60, // Slimmer height for the category selector
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ExerciseCategory.values.map((category) {
                bool isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getCategoryName(category),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.upperBody:
        return 'Upper Body';
      case ExerciseCategory.core:
        return 'Core';
      case ExerciseCategory.legs:
        return 'Legs';
      case ExerciseCategory.fullBody:
        return 'Full Body';
      default:
        return '';
    }
  }

  IconData _getCategoryIcon(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.upperBody:
        return Icons.fitness_center;
      case ExerciseCategory.core:
        return Icons.accessibility_new;
      case ExerciseCategory.legs:
        return Icons.directions_walk;
      case ExerciseCategory.fullBody:
        return Icons.sports_gymnastics;
      default:
        return Icons.help;
    }
  }

  Widget _buildExerciseGrid() {
    final categoryExercises =
    exercises.where((e) => e.category == _selectedCategory).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: categoryExercises.length,
      itemBuilder: (context, index) {
        final exercise = categoryExercises[index];
        return _buildExerciseCard(exercise);
      },
    );
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
      case ExerciseType.PistolSquats:
        return "Glute and lower back exercise";
      case ExerciseType.Squats:
        return "Lower body compound exercise";
      case ExerciseType.WallSit:
        return "Quad endurance exercise";
      case ExerciseType.JumpingJacks:
        return "Full body cardio exercise";
      case ExerciseType.Burpees:
        return "Dynamic full body HIIT exercise";
      default:
        return "";
    }
  }

  IconData _getExerciseIcon(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.upperBody:
        return Icons.fitness_center;
      case ExerciseCategory.legs:
        return Icons.directions_walk;
      case ExerciseCategory.core:
        return Icons.accessibility_new;
      case ExerciseCategory.fullBody:
        return Icons.sports_gymnastics;
      default:
        return Icons.help;
    }
  }

  Color _getCategoryColor(ExerciseCategory category) {
    return ExerciseDataModel.getCategoryColor(category);
  }
}
