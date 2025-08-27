import 'package:flutter/material.dart';
import 'package:flutter_frontend/graphql/graphql_documents.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Query(
        options: QueryOptions(document: gql(getTypingTestQuery)),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (result.hasException) return Text("Error: ${result.exception}");

          final tests = result.data?['getTypingTests'] ?? [];
          if (tests.isEmpty) return const Center(child: Text("No tests yet"));

          final avgWpm =
              tests.map((t) => t['wpm'] as num).reduce((a, b) => a + b) /
              tests.length;
          final avgAccuracy =
              tests.map((t) => t['accuracy'] as num).reduce((a, b) => a + b) /
              tests.length;
          final avgScore =
              tests.map((t) => t['score'] as num).reduce((a, b) => a + b) /
              tests.length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text("Average WPM: ${avgWpm.toStringAsFixed(1)}"),
                Text("Average Accuracy: ${avgAccuracy.toStringAsFixed(1)}%"),
                Text("Average Score: ${avgScore.toStringAsFixed(1)}"),
                const SizedBox(height: 20),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < tests.length; i++)
                              FlSpot(
                                i.toDouble(),
                                (tests[i]['score'] as num).toDouble(),
                              ),
                          ],
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.blue,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
