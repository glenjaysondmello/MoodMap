import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../graphql/graphql_documents.dart';

// A map to hold our theme colors for easy access
const themeColors = {
  'backgroundStart': Color(0xFF2A2A72),
  'backgroundEnd': Color(0xFF009FFD),
  'card': Color(0x22FFFFFF),
  'text': Colors.white,
  'textFaded': Color(0xAAFFFFFF),
  'correct': Color(0xFF39FF14), // Neon green
  'incorrect': Color(0xFFFF4081), // Neon pink
  'accent': Color(0xFF00D2FF),
};

class TypingTestPage extends StatefulWidget {
  final String referenceText;
  const TypingTestPage({super.key, required this.referenceText});

  @override
  State<TypingTestPage> createState() => _TypingTestPageState();
}

class _TypingTestPageState extends State<TypingTestPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  int _seconds = 60;
  Timer? _timer;
  bool _isRunning = false;
  bool _submitted = false;
  Map<String, dynamic>? _result;
  DateTime? _startTime;

  // Live stats
  int _wpm = 0;
  double _accuracy = 100.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    // Request focus for the text field as soon as the page is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_isRunning && _controller.text.isNotEmpty) {
      _startTimer();
    }
    _updateLiveStats();
  }

  void _updateLiveStats() {
    if (!_isRunning || _startTime == null) return;

    final typedText = _controller.text;
    final elapsedSeconds =
        DateTime.now().difference(_startTime!).inMilliseconds / 1000;
    if (elapsedSeconds == 0) return;

    final correctChars = _getCorrectCharCount();

    // WPM is calculated as (number of characters / 5) / time in minutes
    final wpm = (correctChars / 5) / (elapsedSeconds / 60);

    // Accuracy is (correct characters / total typed characters) * 100
    final accuracy = typedText.isEmpty
        ? 100.0
        : (correctChars / typedText.length) * 100;

    setState(() {
      _wpm = wpm.round();
      _accuracy = accuracy;
    });
  }

  int _getCorrectCharCount() {
    int correctChars = 0;
    final typedText = _controller.text;
    for (int i = 0; i < typedText.length; i++) {
      if (i < widget.referenceText.length &&
          typedText[i] == widget.referenceText[i]) {
        correctChars++;
      }
    }
    return correctChars;
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _seconds = 60;
      _startTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        _submitTest();
      } else {
        setState(() {
          _seconds--;
        });
      }
    });
  }

  void _resetTest() {
    _timer?.cancel();
    _controller.clear();
    setState(() {
      _seconds = 60;
      _isRunning = false;
      _submitted = false;
      _result = null;
      _startTime = null;
      _wpm = 0;
      _accuracy = 100.0;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    if (_submitted) return; // Prevent multiple submissions

    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds.toDouble()
        : 60.0 - _seconds;

    setState(() {
      _isRunning = false;
      _submitted = true;
    });

    final client = GraphQLProvider.of(context).value;
    final result = await client.mutate(
      MutationOptions(
        document: gql(submitTypingTestMutation),
        variables: {
          "referenceText": widget.referenceText,
          "userText": _controller.text,
          "durationSec": duration,
        },
      ),
    );

    if (result.hasException) {
      debugPrint(result.exception.toString());
      // Optionally show an error message
    } else {
      setState(() {
        _result = result.data?['submitTypingTest'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColors['backgroundStart']!,
              themeColors['backgroundEnd']!,
            ],
          ),
        ),
        child: SafeArea(
          child: _submitted && _result != null
              ? _buildResultView(context)
              : _buildTestView(context),
        ),
      ),
    );
  }

  // #region BUILDER WIDGETS

  /// The main view for the typing test itself.
  Widget _buildTestView(BuildContext context) {
    return Stack(
      children: [
        // This TextField is invisible but captures all keyboard input
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          showCursor: false,
          style: const TextStyle(
            color: Colors.transparent,
          ), // Hide the text itself
          decoration: const InputDecoration(border: InputBorder.none),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStatsBar(),
              const SizedBox(height: 24),
              Expanded(child: _buildReferenceTextView()),
              const SizedBox(height: 24),
              _buildActionBar(),
            ],
          ),
        ),
      ],
    );
  }

  /// The view for displaying the results after the test.
  Widget _buildResultView(BuildContext context) {
    final results = _result!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        children: [
          Text(
            "Your Results",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: themeColors['text'],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(),
          const SizedBox(height: 20),
          // Main Stats (WPM, CPM, Score)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(
                icon: Icons.speed,
                title: "WPM",
                value: (results['wpm'] as num).toStringAsFixed(1),
              ).animate().fadeIn(delay: 300.ms).slideX(),
              _StatCard(
                icon: Icons.dialpad,
                title: "CPM",
                value: (results['cpm'] as num).toStringAsFixed(1),
              ).animate().fadeIn(delay: 400.ms).slideX(),
              _StatCard(
                icon: Icons.star,
                title: "Score",
                value: results['score'].toStringAsFixed(1),
              ).animate().fadeIn(delay: 500.ms).slideX(),
            ],
          ),
          const SizedBox(height: 20),
          // Accuracy Gauge
          _buildAccuracyGauge(
            (results['accuracy'] as num).toDouble(),
          ).animate().fadeIn(delay: 600.ms).scale(),
          const SizedBox(height: 20),
          // Mistakes & Suggestions
          _ResultDetailCard(
            title: "Mistakes",
            icon: Icons.warning_amber_rounded,
            children: (results['mistakes'] as List).map((m) {
              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${m['error']} → ",
                      style: TextStyle(color: themeColors['incorrect']!),
                    ),
                    TextSpan(
                      text: m['correction'],
                      style: TextStyle(color: themeColors['correct']!),
                    ),
                  ],
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 700.ms),
          const SizedBox(height: 12),
          _ResultDetailCard(
            title: "Suggestions",
            icon: Icons.lightbulb_outline,
            children: (results['suggestions'] as List)
                .map((s) => Text("• $s"))
                .toList(),
          ).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
            onPressed: _resetTest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: themeColors['accent']!.withAlpha(204),
              foregroundColor: Colors.white,
            ),
          ).animate().fadeIn(delay: 900.ms),
        ],
      ),
    );
  }

  /// The top bar showing live stats during the test.
  Widget _buildStatsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _LiveStat(label: "WPM", value: _wpm.toString()),
        _LiveStat(label: "Time Left", value: "${_seconds}s", primary: true),
        _LiveStat(label: "Accuracy", value: "${_accuracy.toStringAsFixed(1)}%"),
      ],
    );
  }

  /// The action bar with Reset and Submit buttons.
  Widget _buildActionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.refresh, color: themeColors['textFaded'], size: 28),
          onPressed: _resetTest,
        ),
        const SizedBox(width: 40),
        ElevatedButton(
          onPressed: _isRunning ? _submitTest : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColors['accent']!.withAlpha(204),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: const Text("Submit"),
        ),
      ],
    );
  }

  /// The text area showing real-time feedback.
  Widget _buildReferenceTextView() {
    final typedText = _controller.text;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColors['card'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.sourceCodePro(
              fontSize: 20,
              color: themeColors['textFaded'],
            ),
            children: _generateTextSpans(typedText),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _generateTextSpans(String typedText) {
    List<TextSpan> spans = [];
    for (int i = 0; i < widget.referenceText.length; i++) {
      Color color;
      TextDecoration? decoration;

      if (i < typedText.length) {
        if (typedText[i] == widget.referenceText[i]) {
          color = themeColors['correct']!;
        } else {
          color = themeColors['incorrect']!;
          decoration = TextDecoration.underline;
        }
      } else {
        color = themeColors['textFaded']!;
      }

      // Add cursor
      if (i == typedText.length) {
        decoration = TextDecoration.underline;
      }

      spans.add(
        TextSpan(
          text: widget.referenceText[i],
          style: TextStyle(
            color: color,
            decoration: decoration,
            decorationColor: themeColors['accent'],
          ),
        ),
      );
    }
    return spans;
  }

  /// The circular gauge for the results screen.
  Widget _buildAccuracyGauge(double accuracy) {
    return CircularPercentIndicator(
      radius: 80.0,
      lineWidth: 12.0,
      percent: accuracy / 100,
      center: Text(
        "${accuracy.toStringAsFixed(1)}%",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: themeColors['text'],
        ),
      ),
      progressColor: themeColors['correct'],
      backgroundColor: themeColors['card']!,
      circularStrokeCap: CircularStrokeCap.round,
      header: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(
          "Accuracy",
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: themeColors['text'],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // #endregion
}

// #region HELPER WIDGETS

class _LiveStat extends StatelessWidget {
  final String label;
  final String value;
  final bool primary;

  const _LiveStat({
    required this.label,
    required this.value,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: themeColors['textFaded'],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: primary ? themeColors['accent'] : themeColors['text'],
            fontSize: primary ? 28 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: themeColors['accent'], size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: themeColors['text'],
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: themeColors['textFaded'],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ResultDetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ResultDetailCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: themeColors['card'],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: themeColors['accent']),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeColors['text'],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            if (children.isEmpty)
              Text("None!", style: TextStyle(color: themeColors['textFaded']))
            else
              ...children.map(
                (child) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: DefaultTextStyle(
                    style: GoogleFonts.poppins(
                      color: themeColors['text'],
                      fontSize: 15,
                    ),
                    child: child,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// #endregion
