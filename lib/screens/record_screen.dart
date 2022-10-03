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

class RecordScreenState extends State<RecordScreen> {
  bool _isRecording = false;
  Stream<List<int>>? stream;
  final List<int> _bytes = [];
  StreamSubscription<List<int>>? streamSubscription;
  final AudioPlayer _player = AudioPlayer();

  final _sampleRate = 44100;

  late final List<int> _headers =
      getHeaders(channels: 1, sampleRate: _sampleRate, size: _bytes.length);

  //variable for didChangeDependencies because MicStream needs context which
  //initState does not provide.
  bool _isInitializing = true;

  @override
  void didChangeDependencies() async {
    if (_isInitializing) {
      stream = await MicStream.microphone(
        sampleRate: _sampleRate,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );

      streamSubscription = stream!.listen((samples) {
        if (_isRecording) {
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

    //automatically add headers when beginning recording
    _bytes.addAll(_headers);
    _isRecording = true;
    setState(() {});
  }

  void _stopRecording() {
    _isRecording = false;
    setState(() {});
  }

  void _saveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = const Uuid().v1();
    final filePath = '${directory.path}/$fileName.wav';

    await File(filePath).writeAsBytes(_bytes);
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
            'Recording length: ${_bytes.length}',
            style: Theme.of(context).textTheme.headline2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 16.0,
          ),
          Text(
            'Is recording: $_isRecording',
            style: Theme.of(context).textTheme.headline2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 16.0,
          ),
          ElevatedButton(
            onPressed: () {
              _saveFile();
            },
            child: const Icon(
              Icons.save,
              size: 32.0,
            ),
          ),
          const SizedBox(
            height: 16.0,
          ),
          IconButton(
            icon: _isRecording ? const Icon(Icons.stop) : const Icon(Icons.mic),
            onPressed: () =>
                _isRecording ? _stopRecording() : _startRecording(),
            iconSize: 48.0,
          ),
          const SizedBox(
            height: 16.0,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              _player.play(
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

//https://stackoverflow.com/a/62028897
List<int> getHeaders({
  required int size,
  required int channels,
  required int sampleRate,
}) {
  final fileSize = size + 36;
  final int byteRate = ((16 * sampleRate * channels) / 8).round();

  return [
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
    sampleRate & 0xff,
    (sampleRate >> 8) & 0xff,
    (sampleRate >> 16) & 0xff,
    (sampleRate >> 24) & 0xff,
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
  ];
}
