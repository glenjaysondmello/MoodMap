import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import '../graphql/graphql_documents.dart';

// Using the same theme colors for consistency
const themeColors = {
  'backgroundStart': Color(0xFF2A2A72),
  'backgroundEnd': Color(0xFF009FFD),
  'card': Color(
    0x22FFFFFF,
  ), // Semi-transparent white for a "frosted glass" effect
  'text': Colors.white,
  'textFaded': Color(0xAAFFFFFF),
  'accent': Color(0xFF00D2FF),
};

class HistoryTypingPage extends StatelessWidget {
  const HistoryTypingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. A transparent AppBar to blend with the gradient
      appBar: AppBar(
        title: Text(
          'Test History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: themeColors['text'],
      ),
      // Extend the body behind the AppBar for a seamless look
      extendBodyBehindAppBar: true,
      // 2. The consistent gradient background
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
          child: Query(
            options: QueryOptions(
              document: gql(getTypingTestQuery),
              fetchPolicy: FetchPolicy.networkOnly,
            ),
            builder: (result, {fetchMore, refetch}) {
              if (result.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (result.hasException) {
                return Center(
                  child: Text(
                    "Error: ${result.exception}",
                    style: TextStyle(color: themeColors['text']),
                  ),
                );
              }

              final tests = result.data?['getTypingTests'] ?? [];

              if (tests.isEmpty) {
                // 3. An improved, more engaging empty state
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 80,
                        color: themeColors['textFaded'],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No History Yet",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: themeColors['text'],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Complete a test to see your progress!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: themeColors['textFaded'],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms);
              }

              // 4. An animated list of beautifully redesigned cards
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                itemCount: tests.length,
                itemBuilder: (context, index) {
                  final test = tests[index];
                  return HistoryCard(test: test)
                      .animate()
                      .fadeIn(delay: (100 * (index % 10)).ms, duration: 400.ms)
                      .slideX(begin: -0.2, curve: Curves.easeOut);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A custom widget to display a single test history item.
class HistoryCard extends StatelessWidget {
  final Map<String, dynamic> test;

  const HistoryCard({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    final DateTime createdAt = DateTime.parse(test['createdAt']);
    final String formattedDate = DateFormat.yMMMd().add_jm().format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeColors['card'],
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row for the main score and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Score
              Row(
                children: [
                  Icon(
                    Icons.star_border_purple500_outlined,
                    color: themeColors['accent'],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Score: ${test['score'].toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: themeColors['text'],
                    ),
                  ),
                ],
              ),
              // Date
              Text(
                formattedDate,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: themeColors['textFaded'],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          // Row for detailed stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.speed_outlined,
                label: 'WPM',
                value: test['wpm'].toString(),
              ),
              _StatItem(
                icon: Icons.dialpad_outlined,
                label: 'CPM',
                value: test['cpm'].toString(),
              ),
              _StatItem(
                icon: Icons.ads_click_outlined,
                label: 'Accuracy',
                value: '${test['accuracy'].toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small helper widget to display a single stat with an icon.
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: themeColors['textFaded'], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: themeColors['text'],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: themeColors['textFaded'],
          ),
        ),
      ],
    );
  }
}
