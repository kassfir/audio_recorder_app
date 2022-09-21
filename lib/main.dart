import 'dart:async';
import 'dart:math';
import 'dart:core';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:mic_stream/mic_stream.dart';

enum Command {
  start,
  stop,
  change,
}

const AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;

void main() => runApp(MicStreamExampleApp());

class MicStreamExampleApp extends StatelessWidget {
  const MicStreamExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Barebones recording test',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.amber,
            brightness: Brightness.light,
            accentColor: Colors.blue,
          ),
        ),
        home: MicStreamPage());
  }
}

class MicStreamPage extends StatefulWidget {
  const MicStreamPage({Key? key}) : super(key: key);

  @override
  State<MicStreamPage> createState() => MicStreamPageState();
}

class MicStreamPageState extends State<MicStreamPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello Recording'),
      ),
      body: SizedBox(
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
          ],
        ),
      ),
      floatingActionButton: IconButton(
        icon: _isRecording ? Icon(Icons.stop) : Icon(Icons.mic),
        onPressed: () => _isRecording ? _stopRecording() : _startRecording(),
        iconSize: 48.0,
      ),
    );
  }
}
