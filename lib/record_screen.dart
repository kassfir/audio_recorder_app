import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:mic_stream/mic_stream.dart';
import 'package:path_provider/path_provider.dart';

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
  List<int> _bytes = [];

  StreamSubscription<List<int>>? streamSubscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    if (_isInitializing) {
      stream = await MicStream.microphone(sampleRate: 44100);
      streamSubscription = stream!.listen((samples) {
        if (_isRecording) {
          _bytes.addAll(samples);
          setState(() {});
        }
        ;
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
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/record.wav';

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
        ],
      ),
    );
  }
}
