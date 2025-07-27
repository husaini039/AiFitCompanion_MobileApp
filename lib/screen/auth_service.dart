import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Method to check if the user is logged in
  Future<bool> isLoggedIn() async {
    User? user = _auth.currentUser;
    return user != null;
  }

  // Method to log in with Google
  Future<UserCredential?> loginWithGoogle() async {
    try {
      // Trigger Google Sign-In process
      final googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null; // The user canceled the sign-in process
      }

      // Get authentication details from Google
      final googleAuth = await googleUser.authentication;

      // Create a credential from the authentication details
      final cred = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Sign in with the credential
      final userCredential = await _auth.signInWithCredential(cred);

      // Store email in Firestore
      await _storeUserEmail(userCredential.user?.email ?? '');

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: ${e.toString()}');
    }
    return null;
  }

  // Store user email in Firestore
  Future<void> _storeUserEmail(String email) async {
    try {
      CollectionReference collRef = _firestore.collection('user_information');

      // Check if user already exists
      QuerySnapshot existingUser = await collRef
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isEmpty) {
        // First time user - add email only
        await collRef.add({
          'email': email,
          'created_at': FieldValue.serverTimestamp(),
        });
        print('New user email stored: $email');
      } else {
        print('User already exists: $email');
      }
    } catch (e) {
      print('Error storing user email: $e');
    }
  }

  // Check if user has completed profile
  Future<bool> isUserProfileComplete(String email) async {
    try {
      CollectionReference collRef = _firestore.collection('user_information');
      QuerySnapshot userDoc = await collRef
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        Map<String, dynamic> userData = userDoc.docs.first.data() as Map<String, dynamic>;

        // Check if all required fields are present and not null
        return userData.containsKey('age') &&
            userData.containsKey('gender') &&
            userData.containsKey('username') &&
            userData.containsKey('weight') &&
            userData.containsKey('height') &&
            userData['age'] != null &&
            userData['gender'] != null &&
            userData['username'] != null &&
            userData['weight'] != null &&
            userData['height'] != null;
      }
      return false;
    } catch (e) {
      print('Error checking user profile: $e');
      return false;
    }
  }

  // Update user profile information
  Future<void> updateUserProfile({
    required String email,
    int? age,
    String? gender,
    String? username,
    double? weight,
    double? height,
  }) async {
    try {
      CollectionReference collRef = _firestore.collection('user_information');

      // Find the user document
      QuerySnapshot userDoc = await collRef
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        // Build update map only with provided fields
        Map<String, dynamic> updateData = {};
        if (age != null) updateData['age'] = age;
        if (gender != null) updateData['gender'] = gender;
        if (username != null) updateData['username'] = username;
        if (weight != null) updateData['weight'] = weight;
        if (height != null) updateData['height'] = height;
        if (updateData.isNotEmpty) {
          updateData['updated_at'] = FieldValue.serverTimestamp();
          await userDoc.docs.first.reference.update(updateData);
          print('User profile updated successfully');
        }
      }
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    try {
      CollectionReference collRef = _firestore.collection('user_information');
      QuerySnapshot userDoc = await collRef
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        return userDoc.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // Save exercise history
  Future<void> saveExerciseHistory({
    required String email,
    required String exerciseName,
    required String exerciseCategory,
    required int completedReps,
    required int completedTime,
    required int caloriesBurned,
  }) async {
    try {
      CollectionReference collRef = _firestore.collection('exercise_history');
      
      await collRef.add({
        'email': email,
        'exercise_name': exerciseName,
        'exercise_category': exerciseCategory,
        'completed_reps': completedReps,
        'completed_time': completedTime, // in seconds
        'calories_burned': caloriesBurned,
        'completed_at': FieldValue.serverTimestamp(),
      });
      
      // Update total calories in user profile
      await _updateTotalCalories(email, caloriesBurned);
      
      print('Exercise history saved successfully');
    } catch (e) {
      print('Error saving exercise history: $e');
    }
  }

  // Get exercise history for a user
  Future<List<Map<String, dynamic>>> getExerciseHistory(String email) async {
    try {
      CollectionReference collRef = _firestore.collection('exercise_history');
      
      QuerySnapshot querySnapshot = await collRef
          .where('email', isEqualTo: email)
          .orderBy('completed_at', descending: true)
          .get();

      List<Map<String, dynamic>> history = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID
        history.add(data);
      }
      
      return history;
    } catch (e) {
      print('Error getting exercise history: $e');
      return [];
    }
  }

  // Update total calories in user profile
  Future<void> _updateTotalCalories(String email, int newCalories) async {
    try {
      CollectionReference collRef = _firestore.collection('user_information');
      
      QuerySnapshot userDoc = await collRef
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        Map<String, dynamic> currentData = userDoc.docs.first.data() as Map<String, dynamic>;
        int currentCalories = currentData['total_calories'] ?? 0;
        int updatedCalories = currentCalories + newCalories;
        
        await userDoc.docs.first.reference.update({
          'total_calories': updatedCalories,
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        print('Total calories updated: $updatedCalories');
      }
    } catch (e) {
      print('Error updating total calories: $e');
    }
  }
}