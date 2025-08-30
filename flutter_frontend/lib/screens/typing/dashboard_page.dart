import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_frontend/graphql/graphql_documents.dart';
import 'package:flutter_frontend/screens/typing/history_typing_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
  'wpmLine': Color(0xFF00D2FF),
  'accuracyLine': Color(0xFF39FF14),
  'scoreLine': Color(0xFFFFD700),
};

class DashboardTyping extends StatelessWidget {
  const DashboardTyping({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
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
              MaterialPageRoute(builder: (_) => const HistoryTypingPage()),
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
                return _buildEmptyState();
              }

              // Data Processing
              tests.sort(
                (a, b) => DateTime.parse(
                  a['createdAt'],
                ).compareTo(DateTime.parse(b['createdAt'])),
              );

              final avgWpm =
                  tests.map((t) => t['wpm'] as num).reduce((a, b) => a + b) /
                  tests.length;
              final avgAccuracy =
                  tests
                      .map((t) => t['accuracy'] as num)
                      .reduce((a, b) => a + b) /
                  tests.length;
              final avgScore =
                  tests.map((t) => t['score'] as num).reduce((a, b) => a + b) /
                  tests.length;

              return RefreshIndicator(
                onRefresh: refetch!,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Text(
                      "Performance Overview",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeColors['text'],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(),
                    const SizedBox(height: 16),
                    // Summary Stat Cards
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _SummaryStatCard(
                          icon: Icons.speed,
                          label: "Avg WPM",
                          value: avgWpm.toStringAsFixed(1),
                          color: themeColors['wpmLine']!,
                        ),
                        _SummaryStatCard(
                          icon: Icons.ads_click,
                          label: "Avg Accuracy",
                          value: "${avgAccuracy.toStringAsFixed(1)}%",
                          color: themeColors['accuracyLine']!,
                        ),
                        _SummaryStatCard(
                          icon: Icons.star,
                          label: "Avg Score",
                          value: avgScore.toStringAsFixed(1),
                          color: themeColors['scoreLine']!,
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // Main Chart for WPM
                    _ChartCard(
                      title: "WPM Over Time",
                      child: _buildLineChart(
                        tests,
                        (test) => test['wpm'],
                        themeColors['wpmLine']!,
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                    const SizedBox(height: 16),
                    // Sparkline charts for other metrics
                    Row(
                      children: [
                        Expanded(
                          child: _ChartCard(
                            title: "Accuracy Trend",
                            isMini: true,
                            child: _buildLineChart(
                              tests,
                              (test) => test['accuracy'],
                              themeColors['accuracyLine']!,
                              isSparkline: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ChartCard(
                            title: "Score Trend",
                            isMini: true,
                            child: _buildLineChart(
                              tests,
                              (test) => test['score'],
                              themeColors['scoreLine']!,
                              isSparkline: true,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
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
          Icon(Icons.query_stats, size: 80, color: themeColors['textFaded']),
          const SizedBox(height: 16),
          Text(
            "No Data Yet",
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
    Color lineColor, {
    bool isSparkline = false,
  }) {
    final spots = tests.asMap().entries.map((entry) {
      final index = entry.key;
      final test = entry.value;
      return FlSpot(index.toDouble(), getValue(test).toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        // General Styling
        gridData: FlGridData(
          show: !isSparkline,
          drawVerticalLine: true,
          horizontalInterval: 20,
          verticalInterval: (tests.length / 4).ceilToDouble(),
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white.withAlpha(26), strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              FlLine(color: Colors.white.withAlpha(26), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: !isSparkline,
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
              interval: (tests.length / 4).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= tests.length) return const Text('');
                final date = DateTime.parse(tests[index]['createdAt']);
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
                value.toInt().toString(),
                style: TextStyle(color: themeColors['textFaded'], fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        // Line Styling
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: isSparkline ? 3 : 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: !isSparkline),
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
        // Interaction
        lineTouchData: LineTouchData(
          enabled: !isSparkline,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)}\n',
                TextStyle(
                  color: themeColors['text'],
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: DateFormat('MMM d, yyyy').format(
                      DateTime.parse(tests[spot.x.toInt()]['createdAt']),
                    ),
                    style: TextStyle(
                      color: themeColors['textFaded'],
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// Helper Widgets for a cleaner build method

class _SummaryStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SummaryStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isMini;
  const _ChartCard({
    required this.title,
    required this.child,
    this.isMini = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isMini
          ? const EdgeInsets.fromLTRB(8, 16, 8, 8)
          : const EdgeInsets.fromLTRB(16, 24, 16, 12),
      height: isMini ? 150 : 300,
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
              fontSize: isMini ? 14 : 18,
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
