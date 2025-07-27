import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pose_detection_realtime/screen/weight_select.dart';
import 'auth_service.dart';

class AgeSelectionScreen extends StatefulWidget {
  final String email;
  const AgeSelectionScreen({Key? key, required this.email}) : super(key: key);

  @override
  _AgeSelectionScreenState createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen> with TickerProviderStateMixin {
  int selectedAge = 19;
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _scaleController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedAge();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _scrollToSelectedAge() {
    double itemHeight = 70.0;
    double offset = (selectedAge - 10) * itemHeight - (MediaQuery.of(context).size.height / 2) + itemHeight / 2;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
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
                          "2 of 6",
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
                          "What's your",
                          style: GoogleFonts.workSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Age?",
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
                  const SizedBox(height: 40),

                  // Age Selector
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        height: 400,
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.vertical,
                          itemCount: 51,
                          itemBuilder: (context, index) {
                            int age = 10 + index;
                            bool isSelected = age == selectedAge;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedAge = age;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.grey[50] : Colors.white,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFF97316) : Colors.grey[300]!,
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
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
                                child: Row(
                                  children: [
                                    const SizedBox(width: 24),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFF97316).withOpacity(0.1)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFF97316).withOpacity(0.3)
                                              : Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.cake_outlined,
                                        color: isSelected ? const Color(0xFFF97316) : Colors.grey[600],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Text(
                                        '$age',
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
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Enhanced Continue Button
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: !_isLoading
                          ? () async {
                        setState(() => _isLoading = true);
                        await _authService.updateUserProfile(
                          email: widget.email,
                          age: selectedAge,
                        );
                        setState(() => _isLoading = false);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WeightSelectionScreen(email: widget.email),
                          ),
                        );
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
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
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
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
        ),
      ),
    );
  }
}
