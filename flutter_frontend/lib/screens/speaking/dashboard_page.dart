import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../graphql//graphql_documents.dart';

class DashboardSpeaking extends StatelessWidget {
  const DashboardSpeaking({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Speaking Dashboard")),
      body: Query(
        options: QueryOptions(document: gql(getSpeakingTestsQuery)),
        builder: (result, {refetch, fetchMore}) {
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (result.hasException) {
            return Center(child: Text(result.exception.toString()));
          }

          final tests = result.data!['getSpeakingTests'];

          return ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final t = tests[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("Transcript: ${t['transcript']}"),
                  subtitle: Text("Overall: ${t['scores']['overall']}"),
                  trailing: Text(
                    DateTime.parse(t['createdAt']).toLocal().toString(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
