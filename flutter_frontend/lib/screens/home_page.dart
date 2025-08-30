import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'typing/typing_text_launcer.dart';
import 'typing/dashboard_page.dart';
import 'speaking/dashboard_page.dart';
import 'speaking/speaking_text_launcer.dart';

// Using the same theme colors for consistency
const themeColors = {
  'backgroundStart': Color(0xFF2A2A72),
  'backgroundEnd': Color(0xFF009FFD),
  'card': Color(0x22FFFFFF), // Semi-transparent white
  'text': Colors.white,
  'textFaded': Color(0xAAFFFFFF),
  'accent': Color(0xFF00D2FF),
  'primaryAction': Color(0xFF39FF14), // Neon green for the main button
};

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    Future<void> signOut() async {
      if (!context.mounted) return;
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(100),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                user?.displayName ?? 'Guest',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeColors['text'],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            color: themeColors['text'],
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            // 1. Wrapped the Column in a SingleChildScrollView to prevent overflows.
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // A prominent, welcoming header
                  Text(
                    'Welcome back,',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      color: themeColors['textFaded'],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                  Text(
                    user?.displayName ?? 'Guest',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: themeColors['text'],
                      height: 1.2,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),

                  // 2. Replaced Spacers with SizedBoxes for explicit spacing in a scroll view.
                  const SizedBox(height: 30),

                  // Typing Test Section
                  _ActionCard(
                    icon: Icons.keyboard_alt_outlined,
                    title: 'Typing Test',
                    subtitle: 'Challenge yourself and measure your speed.',
                    buttonText: 'Start Now',
                    isPrimary: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TypingTestLauncherPage(),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                  const SizedBox(height: 20),
                  _ActionCard(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard (Typing)',
                    subtitle: 'Analyze your performance and progress.',
                    buttonText: 'View Stats',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardTyping(),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                  const SizedBox(height: 40), // Spacing between sections
                  // Speaking Test Section
                  _ActionCard(
                    icon: Icons.mic_none_outlined,
                    title: 'Speaking Test',
                    subtitle: 'Test your pronunciation and fluency.',
                    buttonText: 'Start Now',
                    isPrimary: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SpeakingTestLauncherPage(),
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
                  const SizedBox(height: 20),
                  _ActionCard(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard (Speaking)',
                    subtitle: 'Review your scores and suggestions.',
                    buttonText: 'View Stats',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardSpeaking(),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),

                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A reusable custom widget for the action cards to keep the build method clean.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: themeColors['card'],
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: themeColors['accent']),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeColors['text'],
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: themeColors['textFaded'],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          isPrimary
              ? ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColors['primaryAction'],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(buttonText),
                )
              : OutlinedButton(
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeColors['text'],
                    side: BorderSide(color: themeColors['textFaded']!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(buttonText),
                ),
        ],
      ),
    );
  }
}
