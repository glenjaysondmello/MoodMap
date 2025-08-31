// lib/pages/speaking_test_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:http_parser/http_parser.dart';
import '../../graphql/graphql_documents.dart';

const themeColors = {
  'backgroundStart': Color(0xFF2A2A72),
  'backgroundEnd': Color(0xFF009FFD),
  'card': Color(0x22FFFFFF),
  'text': Colors.white,
  'textFaded': Color(0xAAFFFFFF),
  'correct': Color(0xFF39FF14),
  'incorrect': Color(0xFFFF4081),
  'accent': Color(0xFF00D2FF),
  'recording': Colors.redAccent,
};

class SpeakingTestPage extends StatefulWidget {
  final String referenceText;
  const SpeakingTestPage({super.key, required this.referenceText});

  @override
  State<SpeakingTestPage> createState() => _SpeakingTestPageState();
}

class _SpeakingTestPageState extends State<SpeakingTestPage> {
  int _seconds = 60;
  Timer? _timer;
  bool _isRunning = false;

  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _audioPath;

  bool _submitted = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _closeRecorderSafely();
    super.dispose();
  }

  Future<void> _closeRecorderSafely() async {
    try {
      if (_recorder != null) {
        // check if recorder is open; closeRecorder is safe to call but we null afterward
        await _recorder!.closeRecorder();
      }
    } catch (e) {
      debugPrint('Error closing recorder: $e');
    } finally {
      _recorder = null;
    }
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone permission not granted.")),
          );
        }
        // leave recorder uninitialized so startRecording will fail gracefully
        return;
      }
      await _recorder!.openRecorder();
    } catch (e) {
      debugPrint('Recorder init error: $e');
      // If openRecorder fails, close and null it.
      await _closeRecorderSafely();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to initialize recorder.")),
        );
      }
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _seconds = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        if (_isRecording) _stopRecordingAndSubmit();
      } else {
        if (!mounted) return;
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    if (_recorder == null) {
      // Try to init once more
      await _initRecorder();
      if (_recorder == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recorder not available.')),
          );
        }

        return;
      }
    }

    try {
      final dir = await getTemporaryDirectory();
      _audioPath =
          '${dir.path}/recorded_speech_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder!.startRecorder(toFile: _audioPath, codec: Codec.aacMP4);
      setState(() => _isRecording = true);
      _startTimer();
    } catch (e) {
      debugPrint('Start recording failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start recording.')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      await _recorder!.stopRecorder();
    } catch (e) {
      debugPrint('Stop recorder error: $e');
    } finally {
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _stopRecordingAndSubmit() async {
    if (!_isRecording) return;
    await _stopRecording();
    await _submitTest();
  }

  void _resetTest() async {
    _timer?.cancel();
    setState(() {
      _seconds = 60;
      _isRunning = false;
      _submitted = false;
      _result = null;
      _isRecording = false;
      _isSubmitting = false;
    });
    // delete temporary audio if any
    if (_audioPath != null) {
      try {
        final f = File(_audioPath!);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete temp audio: $e');
      } finally {
        _audioPath = null;
      }
    }
  }

  Future<void> _submitTest() async {
    if (_submitted || _isSubmitting || _audioPath == null) return;
    setState(() {
      _isSubmitting = true;
    });

    final file = File(_audioPath!);
    if (!await file.exists()) {
      setState(() {
        _isSubmitting = false;
      });
      debugPrint('Audio file not found: $_audioPath');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recorded audio not found.')),
        );
      }
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final upload = MultipartFile.fromBytes(
        'file', // field name; keep in sync with backend expectation for multipart
        bytes,
        filename: _audioPath!.split('/').last,
        contentType: MediaType('audio', 'm4a'),
      );

      if (!mounted) return;

      final client = GraphQLProvider.of(context).value;
      // If your mutation expects an 'Upload' variable named 'audioFile', adjust the key accordingly.
      final mutationVariables = {
        'referenceText': widget.referenceText,
        'audioFile': upload,
      };

      final result = await client.mutate(
        MutationOptions(
          document: gql(submitSpeakingTestMutation),
          variables: mutationVariables,
          fetchPolicy: FetchPolicy.noCache,
        ),
      );

      if (result.hasException) {
        debugPrint('GraphQL exception: ${result.exception}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submit failed: ${result.exception}')),
          );
        }
        setState(() {
          _isSubmitting = false;
          _submitted = false;
        });
        return;
      }

      final data = result.data?['submitSpeakingTest'];
      setState(() {
        _submitted = true;
        _result = (data is Map<String, dynamic>) ? data : null;
      });

      // cleanup temp file after successful submit
      try {
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('Failed to delete uploaded file: $e');
      } finally {
        _audioPath = null;
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred while submitting.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
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
              ? _buildResultView()
              : _buildTestView(),
        ),
      ),
    );
  }

  // ----- UI below unchanged from your version, but with small safety checks -----

  Widget _buildTestView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildStatsBar(),
          const SizedBox(height: 24),
          Expanded(child: _buildReferenceTextView()),
          const SizedBox(height: 24),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final results = _result!;
    final scores = (results['scores'] ?? {}) as Map<String, dynamic>;
    final overall = (scores['overall'] is num)
        ? (scores['overall'] as num).toDouble()
        : 0.0;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(
                icon: Icons.record_voice_over,
                title: "Fluency",
                value: (scores['fluency'] is num)
                    ? (scores['fluency'] as num).toStringAsFixed(1)
                    : '0.0',
              ).animate().fadeIn(delay: 300.ms).slideX(),
              _StatCard(
                icon: Icons.rule,
                title: "Grammar",
                value: (scores['grammar'] is num)
                    ? (scores['grammar'] as num).toStringAsFixed(1)
                    : '0.0',
              ).animate().fadeIn(delay: 400.ms).slideX(),
              _StatCard(
                icon: Icons.spellcheck,
                title: "Pronunciation",
                value: (scores['pronunciation'] is num)
                    ? (scores['pronunciation'] as num).toStringAsFixed(1)
                    : '0.0',
              ).animate().fadeIn(delay: 500.ms).slideX(),
            ],
          ),
          const SizedBox(height: 20),
          _buildOverallScoreGauge(
            overall,
          ).animate().fadeIn(delay: 600.ms).scale(),
          const SizedBox(height: 20),
          _ResultDetailCard(
            title: "Your Transcript",
            icon: Icons.text_fields,
            children: [Text(results['transcript'] ?? '---')],
          ).animate().fadeIn(delay: 700.ms),
          const SizedBox(height: 12),
          _ResultDetailCard(
            title: "Mistakes",
            icon: Icons.warning_amber_rounded,
            children: (results['mistakes'] as List? ?? []).map((m) {
              final error = m?['error'] ?? '';
              final correction = m?['correction'] ?? '';
              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "$error → ",
                      style: TextStyle(color: themeColors['incorrect']!),
                    ),
                    TextSpan(
                      text: correction,
                      style: TextStyle(color: themeColors['correct']!),
                    ),
                  ],
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 12),
          _ResultDetailCard(
            title: "Suggestions",
            icon: Icons.lightbulb_outline,
            children: (results['suggestions'] as List? ?? [])
                .map((s) => Text("• $s"))
                .toList(),
          ).animate().fadeIn(delay: 900.ms),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Try Another Test"),
            onPressed: _resetTest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: themeColors['accent']!.withAlpha(204),
              foregroundColor: Colors.white,
            ),
          ).animate().fadeIn(delay: 1000.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsBar() =>
      _LiveStat(label: "Time Left", value: "${_seconds}s", primary: true);

  Widget _buildActionBar() {
    if (_isRecording) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text("Stop Recording"),
        onPressed: _stopRecording,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColors['recording'],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        ),
      );
    }
    if (!_isRecording && _audioPath != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: themeColors['textFaded'],
              size: 28,
            ),
            onPressed: _resetTest,
          ),
          const SizedBox(width: 40),
          ElevatedButton.icon(
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(_isSubmitting ? "Submitting..." : "Submit"),
            onPressed: _isSubmitting ? null : _submitTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColors['accent']!.withAlpha(204),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
          ),
        ],
      );
    }
    return ElevatedButton.icon(
      icon: const Icon(Icons.mic),
      label: const Text("Start Recording"),
      onPressed: _startRecording,
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColors['accent']!.withAlpha(204),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      ),
    );
  }

  Widget _buildReferenceTextView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeColors['card'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Text(
            widget.referenceText,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              color: themeColors['text'],
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallScoreGauge(double score) {
    return CircularPercentIndicator(
      radius: 80.0,
      lineWidth: 12.0,
      percent: (score.clamp(0.0, 100.0)) / 100,
      center: Text(
        score.toStringAsFixed(1),
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
          "Overall Score",
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: themeColors['text'],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

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
