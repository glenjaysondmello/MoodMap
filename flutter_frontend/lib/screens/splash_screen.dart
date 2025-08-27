import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// Using the same theme colors for consistency
const themeColors = {
  'backgroundStart': Color(0xFF2A2A72),
  'backgroundEnd': Color(0xFF009FFD),
  'text': Colors.white,
};

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Your navigation logic is already perfect. It efficiently listens for
    // the auth state and navigates as soon as the check is complete.
    // We'll add a small artificial delay just to ensure the animation is visible.
    Future.delayed(const Duration(seconds: 2), () {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (mounted) {
          if (user != null) {
            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A beautiful, consistent gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColors['backgroundStart']!,
              themeColors['backgroundEnd']!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                [
                      // app logo with a fade-in and scale animation
                      Image.asset(
                            'assets/images/logo.png',
                            width: 150, // Adjust the size as needed
                          )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .scale(
                            delay: 200.ms,
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),

                      const SizedBox(height: 24),

                      // 3. A branded title and tagline that animate in
                      Text(
                        'TypeMaster',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: themeColors['text'],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hone Your Skills, Track Your Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: themeColors['text']!.withAlpha(200),
                        ),
                      ),
                    ]
                    .animate(interval: 300.ms)
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(
                      begin: 0.5,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),
          ),
        ),
      ),
    );
  }
}
