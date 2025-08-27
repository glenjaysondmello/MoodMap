import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../graphql/graphql_documents.dart';
import './typing_test_page.dart';

class TypingTestLauncherPage extends StatelessWidget {
  const TypingTestLauncherPage({super.key});

  Future<void> _startNewTest(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final client = GraphQLProvider.of(context).value;
    final result = await client.query(
      QueryOptions(document: gql(generateTypingTestTextQuery)),
    );

    if (context.mounted) Navigator.pop(context);

    if (result.hasException) {
      debugPrint(result.exception.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to generate test text")),
        );
      }
      return;
    }

    final String referenceText = result.data?['generateTypingTestText'];

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TypingTestPage(referenceText: referenceText),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Typing Test Launcher")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _startNewTest(context),
          child: const Text("Start New Typing Test"),
        ),
      ),
    );
  }
}
