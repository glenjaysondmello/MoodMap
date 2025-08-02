import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

ValueNotifier<GraphQLClient> getGraphQLClient() {
  final httpLink = HttpLink('https://your-graphql-endpoint.com/graphql');

  final authLink = AuthLink(
    getToken: () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        return 'Bearer $token';
      }
      return null;
    },
  );

  final link = authLink.concat(httpLink);

  return ValueNotifier(
    GraphQLClient(
      cache: GraphQLCache(store: HiveStore()),
      link: link,
    ),
  );
}
