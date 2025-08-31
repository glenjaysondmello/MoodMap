import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import './typing/typing_page.dart'; // Import the new TypingPage
import './speaking/speaking_page.dart'; // Import the new SpeakingPage

// Using the same theme colors for consistency
const themeColors = {
  'backgroundStart': Color(0xFF2A2A72),
  'backgroundEnd': Color(0xFF009FFD),
  'card': Color(0x22FFFFFF),
  'text': Colors.white,
  'textFaded': Color(0xAAFFFFFF),
  'accent': Color(0xFF00D2FF),
};

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      // The AppBar now includes a button to open the sidebar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: themeColors['text'],
        ), // Makes the drawer icon white
        actions: [
          IconButton(
            onPressed: () async {
              if (!context.mounted) return;
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      // Add the new sidebar drawer
      drawer: AppDrawer(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Welcome header remains the same
                Text(
                  'Welcome,',
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

                const Spacer(),

                // The two main navigation buttons
                _HomePageButton(
                  icon: Icons.keyboard_alt_outlined,
                  title: 'Typing Practice',
                  subtitle: 'Test your speed and accuracy.',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TypingPage()),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

                const SizedBox(height: 20),

                _HomePageButton(
                  icon: Icons.mic_none_outlined,
                  title: 'Speaking Practice',
                  subtitle: 'Test your fluency and pronunciation.',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SpeakingPage()),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom widget for the new sidebar (Drawer).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      child: Container(
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                user?.displayName ?? 'Guest',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                user?.email ?? '',
                style: GoogleFonts.poppins(),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null ? const Icon(Icons.person) : null,
              ),
              decoration: BoxDecoration(color: Colors.white.withAlpha(30)),
            ),
            _buildDrawerItem(
              icon: Icons.keyboard_alt_outlined,
              title: 'Typing',
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TypingPage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.mic_none_outlined,
              title: 'Speaking',
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SpeakingPage()),
                );
              },
            ),
            const Divider(color: Colors.white54),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: () async {
                if (!context.mounted) return;
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/auth');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}

/// A reusable custom widget for the main buttons on the home page.
class _HomePageButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _HomePageButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
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
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
