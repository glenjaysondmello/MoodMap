import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import '../../graphql/graphql_documents.dart';

// Using the same theme colors for consistency
const themeColors = {
  'backgroundStart': Color(0xFF2A2A72),
  'backgroundEnd': Color(0xFF009FFD),
  'card': Color(0x22FFFFFF),
  'text': Colors.white,
  'textFaded': Color(0xAAFFFFFF),
  'accent': Color(0xFF39FF14), // Use a different accent for variety
};

class HistorySpeakingPage extends StatelessWidget {
  const HistorySpeakingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Speaking History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: themeColors['text'],
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
          child: Query(
            options: QueryOptions(
              document: gql(getSpeakingTestQuery),
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

              final tests = result.data?['getSpeakingTests'] ?? [];
              // Sort by newest first for history view
              tests.sort(
                (a, b) => DateTime.parse(
                  b['createdAt'],
                ).compareTo(DateTime.parse(a['createdAt'])),
              );

              if (tests.isEmpty) {
                // You can add an empty state here if you like
                return Center(
                  child: Text(
                    "No history yet!",
                    style: GoogleFonts.poppins(
                      color: themeColors['text'],
                      fontSize: 18,
                    ),
                  ),
                );
              }

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
    final scores = test['scores'];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Overall: ${(scores['overall'] as num).toStringAsFixed(1)}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: themeColors['accent'],
                ),
              ),
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
          Text(
            '"${test['transcript']}"',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: themeColors['text'],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          // Row for detailed sub-scores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Fluency',
                value: (scores['fluency'] as num).toStringAsFixed(1),
              ),
              _StatItem(
                label: 'Pronunciation',
                value: (scores['pronunciation'] as num).toStringAsFixed(1),
              ),
              _StatItem(
                label: 'Grammar',
                value: (scores['grammar'] as num).toStringAsFixed(1),
              ),
              _StatItem(
                label: 'Vocabulary',
                value: (scores['vocabulary'] as num).toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small helper widget to display a single stat.
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: themeColors['text'],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: themeColors['textFaded'],
          ),
        ),
      ],
    );
  }
}
