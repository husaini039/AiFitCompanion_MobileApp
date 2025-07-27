import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pose_detection_realtime/screen/purpose_screen.dart';
import 'auth_service.dart';

class GenderSelectionScreen extends StatefulWidget {
  final String email;
  const GenderSelectionScreen({Key? key, required this.email}) : super(key: key);

  @override
  _GenderSelectionScreenState createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> with TickerProviderStateMixin {
  String selectedGender = '';
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Assessment",
                    style: GoogleFonts.workSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "4 of 6",
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // Enhanced Question Text
              Center(
                child: Column(
                  children: [
                    Text(
                      "What is your",
                      style: GoogleFonts.workSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Gender?",
                      style: GoogleFonts.workSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Enhanced Gender Options
              _buildGenderOption(
                label: "Male",
                icon: Icons.male,
              ),

              const SizedBox(height: 24),

              _buildGenderOption(
                label: "Female",
                icon: Icons.female,
              ),

              const Spacer(),

              // Enhanced Continue Button
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: selectedGender.isNotEmpty
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: selectedGender.isNotEmpty && !_isLoading
                      ? () async {
                    setState(() => _isLoading = true);
                    await _authService.updateUserProfile(
                      email: widget.email,
                      gender: selectedGender,
                    );
                    setState(() => _isLoading = false);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FitnessGoalPage(email: widget.email),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedGender.isNotEmpty ? Colors.black : Colors.grey[400],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Continue",
                        style: GoogleFonts.workSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required String label,
    required IconData icon,
  }) {
    bool isSelected = selectedGender == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[50] : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFF97316) : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFF97316).withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF97316).withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFFF97316).withOpacity(0.3) : Colors.grey[200]!,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFF97316) : Colors.grey[600],
                size: 36,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.workSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFFF97316) : Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF97316) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFF97316) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                color: isSelected ? Colors.white : Colors.transparent,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
