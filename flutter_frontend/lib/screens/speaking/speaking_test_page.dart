import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class SpeakingTestPage extends StatefulWidget {
  final String referenceText;

  const SpeakingTestPage({super.key, required this.referenceText});

  @override
  State<SpeakingTestPage> createState() => _SpeakingTestPageState();
}

class _SpeakingTestPageState extends State<SpeakingTestPage> {
  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
  String? audioPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await Permission.microphone.request();
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    audioPath = '${dir.path}/recorded.aac';
    await _recorder!.startRecorder(toFile: audioPath);
    setState(() {
      isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      isRecording = false;
    });
  }

  Future<String> _audioToBase64() async {
    final bytes = await File(audioPath!).readAsBytes();
    return base64Encode(bytes);
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class SpeakingResultPage extends StatelessWidget {
  final Map<String, dynamic>? result;
  const SpeakingResultPage({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    final scores = result!['scores'];

    return Scaffold(
      appBar: AppBar(title: const Text("Result")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Transcript: ${result!['transcript']}"),
            const SizedBox(height: 10),
            Text("Fluency: ${scores['fluency']}"),
            Text("Pronunciation: ${scores['pronunciation']}"),
            Text("Grammar: ${scores['grammar']}"),
            Text("Vocabulary: ${scores['vocabulary']}"),
            Text("Overall: ${scores['overall']}"),
            const SizedBox(height: 10),
            Text("Encouragement: ${result['encouragement']}"),
            const SizedBox(height: 10),
            Text("Mistakes: ${result['mistakes']}"),
            Text("Suggestions: ${result['suggestions']}"),
          ],
        ),
      ),
    );
  }
}
