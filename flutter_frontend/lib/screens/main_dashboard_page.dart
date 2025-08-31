import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import '../provider/auth_provider.dart';
import '../../graphql/graphql_documents.dart'; // Ensure your queries are here

// Consistent theme colors
const themeColors = {
  'backgroundStart': Color(0xFF2A2A72),
  'backgroundEnd': Color(0xFF009FFD),
  'card': Color(0x22FFFFFF),
  'text': Colors.white,
  'textFaded': Color(0xAAFFFFFF),
  'accent': Color(0xFF00D2FF),
  'speakingAccent': Color(0xFF39FF14),
  'typingAccent': Color(0xFFFFD700),
};

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _overallStats = {};
  List<dynamic> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    // Fetch all data when the widget is first created
    _fetchDashboardData();
  }

  /// Fetches speaking and typing tests concurrently and processes them.
  Future<void> _fetchDashboardData() async {
    final client = GraphQLProvider.of(context).value;

    try {
      // Run both queries in parallel for efficiency
      final results = await Future.wait([
        client.query(
          QueryOptions(
            document: gql(getSpeakingTestQuery),
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        ),
        client.query(
          QueryOptions(
            document: gql(getTypingTestQuery),
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        ),
      ]);

      final speakingResult = results[0];
      final typingResult = results[1];

      if (speakingResult.hasException || typingResult.hasException) {
        throw Exception("Error fetching data. Please try again.");
      }

      final speakingTests = speakingResult.data?['getSpeakingTests'] ?? [];
      final typingTests = typingResult.data?['getTypingTests'] ?? [];

      setState(() {
        _overallStats = _calculateOverallStats(speakingTests, typingTests);
        _recentActivities = _getRecentActivities(speakingTests, typingTests);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Calculates aggregate statistics from all test results.
  Map<String, dynamic> _calculateOverallStats(
    List<dynamic> speakingTests,
    List<dynamic> typingTests,
  ) {
    // Calculate average speaking score
    final double avgSpeakingScore = speakingTests.isNotEmpty
        ? speakingTests
                  .map<double>(
                    (t) => (t['scores']['overall'] as num).toDouble(),
                  )
                  .reduce((a, b) => a + b) /
              speakingTests.length
        : 0.0;

    // Calculate average WPM
    final double avgWpm = typingTests.isNotEmpty
        ? typingTests
                  .map<double>((t) => (t['wpm'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              typingTests.length
        : 0.0;

    // Calculate average accuracy
    final double avgAccuracy = typingTests.isNotEmpty
        ? typingTests
                  .map<double>((t) => (t['accuracy'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              typingTests.length
        : 0.0;

    return {
      'totalTests': speakingTests.length + typingTests.length,
      'avgSpeakingScore': avgSpeakingScore,
      'avgWpm': avgWpm,
      'avgAccuracy': avgAccuracy,
    };
  }

  /// Merges, sorts, and truncates test results for a unified activity feed.
  List<dynamic> _getRecentActivities(
    List<dynamic> speakingTests,
    List<dynamic> typingTests,
  ) {
    // Add a 'type' field to each test to identify it later
    final combined = [
      ...speakingTests.map((t) => {...t, 'type': 'speaking'}),
      ...typingTests.map((t) => {...t, 'type': 'typing'}),
    ];

    // Sort all tests by date, newest first
    combined.sort(
      (a, b) => DateTime.parse(
        b['createdAt'],
      ).compareTo(DateTime.parse(a['createdAt'])),
    );

    // Return the 5 most recent activities
    return combined.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: themeColors['text']),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDashboardData,
                  child: ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      // 1. User Profile Header
                      _UserProfileHeader(
                        name: user?.displayName ?? 'Guest',
                        imageUrl: user?.photoURL,
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 30),

                      // 2. Overall Performance Section
                      _SectionTitle(title: 'Overall Performance'),
                      const SizedBox(height: 10),
                      _OverallStatsGrid(stats: _overallStats)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.2),

                      const SizedBox(height: 30),

                      // 3. Recent Activity Section
                      _SectionTitle(title: 'Recent Activity'),
                      const SizedBox(height: 10),
                      if (_recentActivities.isEmpty)
                        const Center(
                          child: Text(
                            "No activities yet.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      else
                        ..._recentActivities.asMap().entries.map((entry) {
                          return _RecentActivityCard(test: entry.value)
                              .animate()
                              .fadeIn(
                                delay: (400 + entry.key * 100).ms,
                                duration: 400.ms,
                              )
                              .slideX(begin: -0.2);
                        }),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// #region Helper Widgets for Dashboard UI

class _UserProfileHeader extends StatelessWidget {
  final String name;
  final String? imageUrl;
  const _UserProfileHeader({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white24,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? const Icon(Icons.person, size: 30, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                color: themeColors['textFaded'],
                fontSize: 16,
              ),
            ),
            Text(
              name,
              style: GoogleFonts.poppins(
                color: themeColors['text'],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: themeColors['text'],
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _OverallStatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _OverallStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [
        _StatCard(
          icon: Icons.mic,
          label: 'Avg. Speaking Score',
          value: (stats['avgSpeakingScore'] as double).toStringAsFixed(1),
          color: themeColors['speakingAccent']!,
        ),
        _StatCard(
          icon: Icons.keyboard,
          label: 'Avg. Typing WPM',
          value: (stats['avgWpm'] as double).toStringAsFixed(1),
          color: themeColors['typingAccent']!,
        ),
        _StatCard(
          icon: Icons.check_circle,
          label: 'Avg. Typing Accuracy',
          value: "${(stats['avgAccuracy'] as double).toStringAsFixed(1)}%",
          color: themeColors['accent']!,
        ),
        _StatCard(
          icon: Icons.format_list_numbered,
          label: 'Total Tests Taken',
          value: stats['totalTests'].toString(),
          color: Colors.white,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeColors['card'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: themeColors['textFaded'],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final Map<String, dynamic> test;
  const _RecentActivityCard({required this.test});

  @override
  Widget build(BuildContext context) {
    final isSpeaking = test['type'] == 'speaking';
    final date = DateFormat.yMMMd().format(DateTime.parse(test['createdAt']));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeColors['card'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isSpeaking ? Icons.mic : Icons.keyboard,
            color: isSpeaking
                ? themeColors['speakingAccent']
                : themeColors['typingAccent'],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpeaking ? 'Speaking Test' : 'Typing Test',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    color: themeColors['textFaded'],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isSpeaking
                ? 'Score: ${(test['scores']['overall'] as num).toStringAsFixed(1)}'
                : 'WPM: ${(test['wpm'] as num).toStringAsFixed(1)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// #endregion
