import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pose_detection_realtime/ExerciseListingScreen.dart';
import 'package:pose_detection_realtime/screen/register_page.dart';
import 'package:pose_detection_realtime/screen/username_selec.dart';
import 'auth_service.dart';
import 'newMainPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      });
    }
  }

  Future<void> _handleGoogleSignUp() async {
    try {
      // Use AuthService to log in/sign up with Google
      UserCredential? userCredential = await _authService.loginWithGoogle();

      if (userCredential != null) {
        final String email = userCredential.user?.email ?? '';

        // Check if user profile is complete
        bool isProfileComplete = await _authService.isUserProfileComplete(email);

        if (isProfileComplete) {
          // Profile complete - go to ExerciseListingScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          // First time user - go to profile setup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UsernameSelectScreen(email: email),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-up failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error during Google sign-up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error during Google sign-up'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } 



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 300,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/gym_machine.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sign in to FitAi',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          "Let's get you started!",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? 'Please enter email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _isObscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() => _isObscure = !_isObscure);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? 'Please enter password' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailController.text,
                                  password: _passwordController.text).then((onValue){
                                Navigator.pushReplacement(context,
                                    MaterialPageRoute(builder: (context) => const Exerciselistingscreen()));
                              }).onError((error,StackTrace){
                                print("Error ${error.toString()}");
                              });
                            }
                          },
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          label: const Text(
                            'Sign In',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16,color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _handleGoogleSignUp,  // Change to use the method
                        icon: const Icon(
                          FontAwesomeIcons.google,
                          color: Colors.black,
                          size: 25,
                        ),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black, backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.black, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpPage()),
                              );
                            },
                            child: const Text(
                              'Sign Up.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          )
                        ],
                      ),

                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
