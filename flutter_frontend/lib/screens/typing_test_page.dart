import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../graphql/graphql_documents.dart';

class TypingTestPage extends StatefulWidget {
  final String referenceText;

  const TypingTestPage({super.key, required this.referenceText});

  @override
  State<TypingTestPage> createState() => _TypingTestPageState();
}

class _TypingTestPageState extends State<TypingTestPage> {
  final TextEditingController _controller = TextEditingController();
  int _seconds = 60;
  Timer? _timer;
  bool _isRunning = false;
  bool _submitted = false;
  Map<String, dynamic>? _result;
  DateTime? _startTime;

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _seconds = 60;
      _startTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
        _submitTest();
      } else {
        setState(() {
          _seconds--;
        });
      }
    });
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    DateTime endTime = DateTime.now();
    final int duration = _startTime != null
        ? endTime.difference(_startTime!).inSeconds
        : 60;

    final userText = _controller.text.trim();

    final client = GraphQLProvider.of(context).value;
    final result = await client.mutate(
      MutationOptions(
        document: gql(submitTypingTestMutation),
        variables: {
          "referenceText": widget.referenceText,
          "userText": userText,
          "durationSec": duration,
        },
      ),
    );

    if (result.hasException) {
      debugPrint(result.exception.toString());
    } else {
      setState(() {
        _submitted = true;
        _result = result.data?['submitTYpingTest'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted && _result != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Typing Test Result")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                "WPM: ${_result!['wpm']}",
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                "CPM: ${_result!['cpm']}",
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                "Accuracy: ${_result!['accuracy'].toStringAsFixed(2)}%",
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                "Score: ${_result!['score'].toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text(
                "Mistakes:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(_result!['mistakes'] as List).map(
                (m) =>
                    Text("${m['error']} → ${m['correction']} (${m['type']})"),
              ),
              const SizedBox(height: 16),
              const Text(
                "Suggestions:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(_result!['suggestions'] as List).map((s) => Text("• $s")),
              const SizedBox(height: 16),
              Text(
                "Encouragement: ${_result!['encouragement']}",
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Typing Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Reference: ${widget.referenceText}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              "Time left: $_seconds s",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 10,
              enabled: _isRunning,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Start typing here...",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRunning ? _submitTest : _startTimer,
              child: Text(_isRunning ? "Submit" : "Start Test"),
            ),
          ],
        ),
      ),
    );
  }
}
