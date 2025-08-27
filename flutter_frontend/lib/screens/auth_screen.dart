import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_signin_button/flutter_signin_button.dart'; // No longer needed
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

// Using the same theme colors for consistency
const themeColors = {
  'backgroundStart': Color(0xFF2A2A72),
  'backgroundEnd': Color(0xFF009FFD),
  'card': Color(0x22FFFFFF), // Semi-transparent white
  'text': Colors.white,
  'textFaded': Color(0xAAFFFFFF),
  'accent': Color(0xFF00D2FF),
};

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authProvider.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn(AuthProvider authProvider) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await authProvider.signInWithGoogle();
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      // 1. A consistent, immersive gradient background
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    [
                          // 2. A beautiful header with branding and animations
                          const Icon(
                            Icons.keyboard_command_key,
                            color: Colors.white,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ClarityKeys',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: themeColors['text'],
                            ),
                          ),
                          Text(
                            'Hone Your Skills, Track Your Progress',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: themeColors['textFaded'],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // 3. AnimatedSwitcher for smooth transitions between Login/Sign Up
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            child: Text(
                              _isLogin ? "Welcome Back!" : "Create Account",
                              key: ValueKey(_isLogin),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: themeColors['text'],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 4. Beautifully styled TextFormFields
                          _buildTextFormField(
                            controller: _emailController,
                            hintText: "Email Address",
                            prefixIcon: Icons.email_outlined,
                            validator: (v) => (v == null || !v.contains('@'))
                                ? "Enter a valid email"
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _passwordController,
                            hintText: "Password",
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6)
                                ? "Password must be 6+ chars"
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // 5. An enhanced primary button with a loading state
                          ElevatedButton(
                            onPressed: () => _submit(authProvider),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: themeColors['accent'],
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      _isLogin ? "LOGIN" : "SIGN UP",
                                      key: ValueKey(_isLogin),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _isLogin = !_isLogin),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isLogin
                                    ? "Don't have an account? Sign Up"
                                    : "Already have an account? Login",
                                key: ValueKey(_isLogin),
                                style: TextStyle(
                                  color: themeColors['textFaded'],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDivider(),
                          const SizedBox(height: 20),

                          OutlinedButton.icon(
                            icon: Image.asset(
                              'assets/images/google_logo.png', // Path to your asset
                              height: 24.0,
                            ),
                            label: Text(
                              'Sign in with Google',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: themeColors['text'],
                              ),
                            ),
                            onPressed: () => _googleSignIn(authProvider),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: themeColors['card'],
                              side: BorderSide(
                                color: Colors.white.withAlpha(50),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ]
                        .animate(interval: 100.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.5, curve: Curves.easeOut),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for beautifully styled text fields
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: themeColors['text']),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: themeColors['textFaded']),
        prefixIcon: Icon(prefixIcon, color: themeColors['textFaded']),
        filled: true,
        fillColor: themeColors['card'],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColors['accent']!, width: 2),
        ),
      ),
    );
  }

  // Helper widget for the "OR" divider
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: themeColors['textFaded'])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("OR", style: TextStyle(color: themeColors['textFaded'])),
        ),
        Expanded(child: Divider(color: themeColors['textFaded'])),
      ],
    );
  }
}
