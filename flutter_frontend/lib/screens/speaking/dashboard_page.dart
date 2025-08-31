import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../graphql/graphql_documents.dart';
import './history_speaking_page.dart';

// Using the same theme colors for consistency
const themeColors = {
  'backgroundStart': Color(0xFF2A2A72),
  'backgroundEnd': Color(0xFF009FFD),
  'card': Color(0x22FFFFFF),
  'text': Colors.white,
  'textFaded': Color(0xAAFFFFFF),
  'accent': Color(0xFF00D2FF),
  'lineColor': Color(0xFF39FF14), // Neon green for the chart
};

class DashboardSpeaking extends StatelessWidget {
  const DashboardSpeaking({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Speaking Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: themeColors['text'],
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Test History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistorySpeakingPage()),
            ),
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
          child: Query(
            options: QueryOptions(
              document: gql(getSpeakingTestQuery),
              fetchPolicy: FetchPolicy.networkOnly,
            ),
            builder: (result, {refetch, fetchMore}) {
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

              final testsRaw = result.data?['getSpeakingTests'] ?? [];
              final tests = List.from(testsRaw);

              if (tests.isEmpty) {
                // Wrap empty state in RefreshIndicator for pull-to-refresh
                return RefreshIndicator(
                  onRefresh: refetch!,
                  child: ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: _buildEmptyState(),
                      ),
                    ],
                  ),
                );
              }

              // Data Processing for chart
              // tests.sort((a, b) {
              //   final dateA =
              //       DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
              //   final dateB =
              //       DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
              //   return dateA.compareTo(dateB);
              // });

              // final latestTest = tests.last;
              // final latestDate = DateTime.tryParse(
              //   latestTest['createdAt'] ?? '',
              // );

              // Compute averages for all tests
              Map<String, double> averageScores = {
                'fluency': 0,
                'pronunciation': 0,
                'grammar': 0,
                'vocabulary': 0,
              };

              if (tests.isNotEmpty) {
                for (var key in averageScores.keys) {
                  double total = 0;
                  int count = 0;
                  for (var test in tests) {
                    final val = test['scores']?[key];
                    if (val is num) {
                      total += val;
                      count++;
                    }
                  }
                  averageScores[key] = count > 0 ? total / count : 0;
                }
              }

              String avgScore(String key) =>
                  averageScores[key]?.toStringAsFixed(1) ?? "0.0";

              // String safeScore(Map scores, String key) {
              //   final val = scores?[key];
              //   if (val is num) {
              //     return val.toStringAsFixed(1);
              //   }
              //   return "0.0";
              // }

              return RefreshIndicator(
                onRefresh: refetch!,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Text(
                      "Test Analysis",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeColors['text'],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(),
                    // if (latestDate != null)
                    //   Text(
                    //     "Taken on ${DateFormat.yMMMd().format(latestDate)}",
                    //     style: GoogleFonts.poppins(
                    //       fontSize: 14,
                    //       color: themeColors['textFaded'],
                    //     ),
                    //   ),
                    const SizedBox(height: 16),

                    // Summary Stat Cards for the AVERAGE of all tests
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: [
                        _SummaryStatCard(
                          label: "Fluency",
                          value: avgScore('fluency'),
                        ),
                        _SummaryStatCard(
                          label: "Pronunciation",
                          value: avgScore('pronunciation'),
                        ),
                        _SummaryStatCard(
                          label: "Grammar",
                          value: avgScore('grammar'),
                        ),
                        _SummaryStatCard(
                          label: "Vocabulary",
                          value: avgScore('vocabulary'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // Main Chart for Overall Score
                    _ChartCard(
                      title: "Overall Score Over Time",
                      child: _buildLineChart(
                        tests,
                        (test) => (test['scores']?['overall'] ?? 0) as num,
                        themeColors['lineColor']!,
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none, size: 80, color: themeColors['textFaded']),
          const SizedBox(height: 16),
          Text(
            "No Speaking Tests Yet",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: themeColors['text'],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Take a test to see your dashboard!",
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

  /// Builds a beautifully styled LineChart.
  Widget _buildLineChart(
    List tests,
    num Function(dynamic) getValue,
    Color lineColor,
  ) {
    final spots = tests.asMap().entries.map((entry) {
      final index = entry.key;
      final test = entry.value;
      final value = getValue(test);
      return FlSpot(index.toDouble(), value.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white.withAlpha(26), strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              FlLine(color: Colors.white.withAlpha(26), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: max(1, (tests.length / 4).ceil()).toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= tests.length) return const Text('');
                final date = DateTime.tryParse(tests[index]['createdAt'] ?? '');
                if (date == null) return const Text('');
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    DateFormat('MMM d').format(date),
                    style: TextStyle(
                      color: themeColors['textFaded'],
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: TextStyle(color: themeColors['textFaded'], fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [lineColor.withAlpha(77), lineColor.withAlpha(0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: themeColors['card'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: themeColors['textFaded'],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: themeColors['text'],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      height: 300,
      decoration: BoxDecoration(
        color: themeColors['card'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeColors['text'],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
