import 'package:flutter/material.dart';
import '../provider/auth_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../graphql/graphql_documents.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _start = DateTime.now().subtract(const Duration(days: 7));
  DateTime _end = DateTime.now();

  String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('History & Insights'),
            const SizedBox(width: 10),
            if (user?.photoURL != null)
              CircleAvatar(backgroundImage: NetworkImage(user!.photoURL!))
            else
              CircleAvatar(child: Icon(Icons.person)),

            const SizedBox(width: 1),

            Text(
              user?.displayName ?? 'Guest',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start'),
                    subtitle: Text(_iso(_start)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _start,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now(),
                      );

                      if (picked != null) setState(() => _start = picked);
                    },
                  ),
                ),

                Expanded(
                  child: ListTile(
                    title: const Text('End'),
                    subtitle: Text(_iso(_end)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _end,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _end = picked);
                    },
                  ),
                ),

                IconButton(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          Expanded(
            child: Query(
              options: QueryOptions(
                document: gql(getMoodHistoryQuery),
                variables: {
                  "range": {"startDate": _iso(_start), "endDate": _iso(_end)},
                },
                fetchPolicy: FetchPolicy.networkOnly,
              ),
              builder: (result, {refetch, fetchMore}) {
                if (result.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (result.hasException) {
                  return Center(child: Text('Error: ${result.exception}'));
                }

                final items = (result.data?['getMoodHistory'] as List?) ?? [];

                if (items.isEmpty) {
                  return const Center(child: Text('No entries in this range.'));
                }

                return ListView.separated(
                  itemBuilder: (context, i) {
                    final e = items[i] as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(child: Text((e['mood'] ?? '?')[0])),
                      title: Text('${e['date']} - ${e['mood']}'),
                      subtitle: Text(e['journalText'] ?? ''),
                      trailing: Text(
                        e['sentimentScore'] == null
                            ? '-'
                            : (e['sentimentScore'] as num).toStringAsFixed(2),
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: items.length,
                );
              },
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Query(
              options: QueryOptions(
                document: gql(getMoodStatsQuery),
                fetchPolicy: FetchPolicy.networkOnly,
              ),
              builder: (result, {refetch, fetchMore}) {
                if (result.isLoading) {
                  return const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (result.hasException) {
                  return Text('Stats error: ${result.exception}');
                }

                final s = result.data?['getMoodStats'];
                if (s == null) return const SizedBox.shrink();

                return Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _chip(
                      'Avg Score',
                      (s['averageMoodScore'] as num?)?.toStringAsFixed(2) ??
                          '-',
                    ),
                    _chip('Entries', '${s['moodCount']}'),
                    _chip('Positive Days', '${s['positiveDays']}'),
                    _chip('Negative Days', '${s['negativeDays']}'),
                    _chip('Streak', '${s['streak']}'),
                    _chip('Top Words', (s['mostUsedWords'] as List).join(', ')),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Chip(label: Text('$label: $value'));
  }
}
