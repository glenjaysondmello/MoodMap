import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../graphql/graphql_documents.dart';
import 'typing_test_page.dart';

class TypingTestLauncherPage extends StatelessWidget {
  const TypingTestLauncherPage({super.key});

  // Your core logic for starting the test remains the same. It's already robust!
  Future<void> _startNewTest(BuildContext context) async {
    // Show a loading dialog while fetching data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    final client = GraphQLProvider.of(context).value;
    try {
      final result = await client.query(
        QueryOptions(
          document: gql(generateTypingTestTextQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      // Dismiss the loading dialog
      if (context.mounted) Navigator.pop(context);

      if (result.hasException) {
        throw result.exception!;
      }

      final String? referenceText = result.data?['getTypingTestText'];

      if (referenceText == null) {
        throw Exception("Received null text from server");
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TypingTestPage(referenceText: referenceText),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      // Make sure the dialog is closed even on error
      if (context.mounted && ModalRoute.of(context)?.isCurrent != true) {
        Navigator.pop(context);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Failed to generate test text. Please try again."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 1. A beautiful gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2A72), Color(0xFF009FFD)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 2. Engaging, animated title and subtitle
                Text(
                      "Ready to Test Your Speed?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2, curve: Curves.easeOut),

                const SizedBox(height: 16),

                Text(
                      "Press the button below to start a new challenge.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white.withAlpha(204),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: -0.2, curve: Curves.easeOut),

                const SizedBox(height: 48),

                // 3. A stylish, elevated button with an icon
                ElevatedButton.icon(
                      icon: const Icon(Icons.keyboard_alt_outlined, size: 28),
                      label: const Text("Start New Test"),
                      onPressed: () => _startNewTest(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(
                          0xFF2A2A72,
                        ), // Text/Icon color
                        backgroundColor:
                            Colors.white, // Button background color
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black.withAlpha(77),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 500.ms)
                    .scaleXY(begin: 0.8, curve: Curves.elasticOut),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
