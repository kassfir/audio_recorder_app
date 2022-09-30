import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'dart:developer';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:mic_stream/mic_stream.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);

  @override
  State<RecordScreen> createState() => RecordScreenState();
}

enum Command {
  start,
  stop,
  change,
}

const AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;

class RecordScreenState extends State<RecordScreen> {
  bool _isRecording = false;
  bool _isInitializing = true;
  Stream<List<int>>? stream;
  // Uint8List _bytes = Uint8List.fromList([]);
  final List<int> _bytes = [];
  StreamSubscription<List<int>>? streamSubscription;
  final AudioPlayer player = AudioPlayer();

  final SAMPLE_RATE = 44100;

  @override
  void didChangeDependencies() async {
    if (_isInitializing) {
      stream = await MicStream.microphone(
        sampleRate: SAMPLE_RATE,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );
      streamSubscription = stream!.listen((samples) {
        if (_isRecording) {
          // _bytes.addAll(samples);
          _bytes.addAll(samples);
          setState(() {});
        }
      });

      setState(() {
        _isInitializing = true;
      });
    }
    super.didChangeDependencies();
  }

  void _startRecording() {
    _bytes.clear();
    _isRecording = true;
    setState(() {});
  }

  void _stopRecording() {
    _isRecording = false;
    setState(() {});
  }

  void _saveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = Uuid().v1();
    final filePath = '${directory.path}/${fileName}.wav';

    final size = _bytes.length;
    final fileSize = size + 36;
    final channels = 1;
    final int byteRate = ((16 * SAMPLE_RATE * channels) / 8).round();

    List<int> fullFile = [
      // "RIFF"
      82, 73, 70, 70,
      fileSize & 0xff,
      (fileSize >> 8) & 0xff,
      (fileSize >> 16) & 0xff,
      (fileSize >> 24) & 0xff,
      // WAVE
      87, 65, 86, 69,
      // fmt
      102, 109, 116, 32,
      // fmt chunk size 16
      16, 0, 0, 0,
      // Type of format
      1, 0,
      // One channel
      channels, 0,
      // Sample rate
      SAMPLE_RATE & 0xff,
      (SAMPLE_RATE >> 8) & 0xff,
      (SAMPLE_RATE >> 16) & 0xff,
      (SAMPLE_RATE >> 24) & 0xff,
      // Byte rate
      byteRate & 0xff,
      (byteRate >> 8) & 0xff,
      (byteRate >> 16) & 0xff,
      (byteRate >> 24) & 0xff,
      // Uhm
      ((16 * channels) / 8).round(), 0,
      // bitsize
      16, 0,
      // "data"
      100, 97, 116, 97,
      size & 0xff,
      (size >> 8) & 0xff,
      (size >> 16) & 0xff,
      (size >> 24) & 0xff,
      ..._bytes
    ];

    await File(filePath).writeAsBytes(fullFile);
    log(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Recording size: ${_bytes.length}',
            style: Theme.of(context).textTheme.headline2,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 16.0,
          ),
          Text(
            'Is recording: $_isRecording',
            style: Theme.of(context).textTheme.headline2,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 16.0,
          ),
          ElevatedButton(
            onPressed: () {
              _saveFile();
            },
            child: Icon(
              Icons.save,
              size: 32.0,
            ),
          ),
          SizedBox(
            height: 16.0,
          ),
          IconButton(
            icon: _isRecording ? Icon(Icons.stop) : Icon(Icons.mic),
            onPressed: () =>
                _isRecording ? _stopRecording() : _startRecording(),
            iconSize: 48.0,
          ),
          SizedBox(
            height: 16.0,
          ),
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: () {
              // player.play(UrlSource(
              //     'https://download.samplelib.com/mp3/sample-3s.mp3'));
              player.play(
                BytesSource(
                  Uint8List.fromList(_bytes),
                ),
              );
            },
            iconSize: 48.0,
          ),
        ],
      ),
    );
  }
}
