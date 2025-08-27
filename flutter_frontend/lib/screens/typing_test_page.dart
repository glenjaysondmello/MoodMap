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

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _seconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
      } else {
        setState(() {
          _seconds--;
        });
      }
    });
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    final userText = _controller.text.trim();

    final client = GraphQLProvider.of(context).value;
    final result = await client.mutate(
      MutationOptions(
        document: gql(submitTypingTestMutation),
        variables: {
          "referenceText": widget.referenceText,
          "userText": userText,
          "durationSec": 60,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
