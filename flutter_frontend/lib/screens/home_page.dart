import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import '../graphql/graphql_documents.dart';
import '../provider/auth_provider.dart';
import './log_mood_screen.dart';
import './history_screen.dart';
import './typing_text_launcer.dart';
import './dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? todayMood;
  bool isLoading = true;
  String? error;
  bool _hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasFetched) {
      _hasFetched = true;
      _fetchTodayMood();
    }
  }

  Future<void> _fetchTodayMood() async {
    try {
      final client = GraphQLProvider.of(context).value;
      final result = await client.query(
        QueryOptions(
          document: gql(getTodayMoodQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

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
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    Future<void> signOut() async {
      final nav = Navigator.of(context);
      await authProvider.signOut();
      nav.pushReplacementNamed('/auth');
    }

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('MoodMap'),
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: signOut),
          ],
        ),
        body: Center(child: Text('Error: $error')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (user?.photoURL != null)
              CircleAvatar(backgroundImage: NetworkImage(user!.photoURL!))
            else
              CircleAvatar(child: Icon(Icons.person)),

            const SizedBox(width: 10),

            Text(
              user?.displayName ?? 'Guest',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),

        actions: [
          IconButton(onPressed: signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                title: const Text('Todays Mood'),
                subtitle: Text(
                  todayMood == null
                      ? 'Not logged yet'
                      : '${todayMood!['mood']} - ${todayMood!['journalText']}',
                ),
                trailing: FilledButton(
                  onPressed: () async {
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
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HistoryScreen()),
                    );

                    _fetchTodayMood();
                  },
                  child: const Text('Open'),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                title: const Text('Typing Test'),
                subtitle: const Text(
                  '1-minute test, mistakes, WPM, CPM & score',
                ),
                trailing: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TypingTestLauncherPage(),
                      ),
                    );
                  },
                  child: const Text('Start'),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Dashboard'),
                subtitle: const Text(
                  'View your key metrics and recent activity.',
                ),
                trailing: ElevatedButton(
                  // ElevatedButton often looks better here
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardPage()),
                    );
                  },
                  child: const Text('View'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
