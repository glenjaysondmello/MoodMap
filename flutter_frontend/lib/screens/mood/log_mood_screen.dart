import 'package:flutter/material.dart';
import '../../provider/auth_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import '../../graphql/graphql_documents.dart';
import '../../widgets/mood_picker.dart';
import '../../models/mood_type.dart';
import 'package:intl/intl.dart';

class LogMoodScreen extends StatefulWidget {
  const LogMoodScreen({super.key});

  @override
  State<LogMoodScreen> createState() => _LogMoodScreenState();
}

class _LogMoodScreenState extends State<LogMoodScreen> {
  final _journalCtrl = TextEditingController();
  MoodType? _mood;
  DateTime _date = DateTime.now();
  bool _submitting = false;
  String? _error;

  String _isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final userId = user?.uid;

    if (userId == null) throw Exception('No logged-in user');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Log Mood'),
            const SizedBox(width: 100),
            if (user?.photoURL != null)
              CircleAvatar(backgroundImage: NetworkImage(user!.photoURL!))
            else
              CircleAvatar(child: Icon(Icons.person)),

            // const SizedBox(width: 1),

            // Text(
            //   user?.displayName ?? 'Guest',
            //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            // ),
          ],
        ),
      ),
      body: Mutation(
        options: MutationOptions(
          document: gql(logMoodMutation),
          onCompleted: (dynamic data) {
            if (mounted) Navigator.pop(context);
          },
          onError: (error) {
            if (!mounted) return;
            setState(() => _error = error.toString());
          },
        ),
        builder: (runMutation, result) {
          Future<void> submit() async {
            setState(() {
              _submitting = true;
              _error = null;
            });
            try {
              if (_mood == null || _journalCtrl.text.trim().isEmpty) {
                throw Exception('Please select a mood and enter your journal.');
              }

              runMutation({
                "input": {
                  "date": _isoDate(_date),
                  "mood": _mood!.name,
                  "journalText": _journalCtrl.text.trim(),
                },
              });

              if (mounted) Navigator.pop(context);
            } catch (e) {
              setState(() {
                _error = e.toString();
              });
            } finally {
              if (mounted) {
                setState(() {
                  _submitting = false;
                });
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Date'),
                subtitle: Text(_isoDate(_date)),
                trailing: IconButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 1),
                    );

                    if (picked != null) setState(() => _date = picked);
                  },
                  icon: Icon(Icons.calendar_today),
                ),
              ),

              const SizedBox(height: 8),
              const Text('Select Mood'),
              const SizedBox(height: 8),

              MoodPicker(
                selected: _mood,
                onChanged: (m) => setState(() => _mood = m),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _journalCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Journal/Reflection',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: _submitting ? null : submit,
                label: Text(_submitting ? 'Saving...' : 'Save'),
                icon: Icon(Icons.save),
              ),
            ],
          );
        },
      ),
    );
  }
}
