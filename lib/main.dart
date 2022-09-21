import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RecorderPage(),
    );
  }
}

class RecorderPage extends StatefulWidget {
  const RecorderPage({Key? key}) : super(key: key);

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  final recorder = FlutterSoundRecorder();
  bool isRecorderReady = false;

  stopRecording() async {
    if (!isRecorderReady) {
      return;
    }

    final path = await recorder.stopRecorder();
    final audioFile = File(path!);

    log(audioFile.uri.path);

    log('recorded audio: $audioFile');
  }

  startRecording() async {
    if (!isRecorderReady) {
      return;
    }

    await recorder.startRecorder(toFile: 'audio');
  }

  @override
  void initState() {
    initRecorder();
    super.initState();
  }

  initRecorder() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      throw 'Microphone permission was not granted';
    }

    await recorder.openRecorder();
    isRecorderReady = true;

    recorder.setSubscriptionDuration(
      const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (Scaffold(
      appBar: AppBar(
        title: Text('Recorder app'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<RecordingDisposition>(
              stream: recorder.onProgress,
              builder: ((context, snapshot) {
                final duration =
                    snapshot.hasData ? snapshot.data!.duration : Duration.zero;

                String twoDigits(int n) => n.toString().padLeft(2, "0");

                final twoDigitMinutes =
                    twoDigits(duration.inMinutes.remainder(60));

                final twoDigitSeconds =
                    twoDigits(duration.inSeconds.remainder(60));

                return (Center(
                  child: Text(
                    '$twoDigitMinutes:$twoDigitSeconds',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ));
              }),
            ),
            ElevatedButton(
              child: Icon(
                recorder.isRecording ? Icons.stop : Icons.mic,
                size: 80,
              ),
              onPressed: () async {
                recorder.isRecording
                    ? await stopRecording()
                    : await startRecording();
              },
            ),
          ],
        ),
      ),
    ));
  }
}
