import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/client/graphql_client.dart';
import 'package:flutter_frontend/screens/typing_test_page.dart';
import 'package:flutter_frontend/screens/typing_text_launcer.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'firebase_options.dart';
import './screens/auth_screen.dart';
import './screens/splash_screen.dart';
import './provider/auth_provider.dart';
import './screens/home_page.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initHiveForFlutter();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: getGraphQLClient(),
      child: MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Mood App",
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (ctx) => const SplashScreen(),
            '/auth': (ctx) => const AuthScreen(),
            '/home': (ctx) => const HomePage(),
            '/text': (ctx) => const TypingTestLauncherPage(),
          },
        ),
      ),
    );
  }
}
