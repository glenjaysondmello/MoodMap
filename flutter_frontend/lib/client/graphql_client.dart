import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

ValueNotifier<GraphQLClient> getGraphQLClient() {
  final httpLink = HttpLink("http://192.168.1.10:3000/graphql");

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
      link: link,
      cache: GraphQLCache(store: HiveStore()),
    ),
  );
}
