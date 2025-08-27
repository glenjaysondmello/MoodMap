import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../graphql/graphql_documents.dart';
import 'log_mood_screen.dart';
import 'history_screen.dart';

class MoodHomePage extends StatefulWidget {
  const MoodHomePage({super.key});

  @override
  State<MoodHomePage> createState() => _MoodHomePageState();
}

class _MoodHomePageState extends State<MoodHomePage> {
  Map<String, dynamic>? todayMood;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTodayMood();
    });
  }

  Future<void> _fetchTodayMood() async {
    // Ensure the widget is still mounted before proceeding
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final client = GraphQLProvider.of(context).value;
      final result = await client.query(
        QueryOptions(
          document: gql(getTodayMoodQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (!mounted) return;

      if (result.hasException) {
        setState(() {
          error = result.exception.toString();
          isLoading = false;
        });
        return;
      }

      setState(() {
        todayMood = result.data?['getTodayMood'];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracking')),
      body: RefreshIndicator(onRefresh: _fetchTodayMood, child: buildContent()),
    );
  }

  Widget buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $error'),
        ),
      );
    }

    // Use a ListView to allow for pull-to-refresh
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: ListTile(
            title: const Text('Today\'s Mood'),
            subtitle: Text(
              todayMood == null
                  ? 'Not logged yet'
                  : '${todayMood!['mood']} - ${todayMood!['journalText']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: FilledButton(
              onPressed: () async {
                // Navigate to log/update screen and then refresh the data
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogMoodScreen()),
                );
                _fetchTodayMood();
              },
              child: Text(todayMood == null ? 'Log Now' : 'Update'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('History & Insights'),
            subtitle: const Text('View logs, range filter, and stats'),
            trailing: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ],
    );
  }
}
