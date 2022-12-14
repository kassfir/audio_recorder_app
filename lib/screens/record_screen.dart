import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_recorder_app/config.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RecordScreenState();
}

enum Command {
  start,
  stop,
  change,
}

class _RecordScreenState extends State<RecordScreen> {
  bool isInit = true;
  Stream<List<int>>? stream;

  bool recognizing = false;
  bool recognizeFinished = false;
  String text = '';
  StreamSubscription<List<int>>? _audioStreamSubscription;
  BehaviorSubject<List<int>>? _audioStream;
  final List<int> _bytes = [];

  late final List<int> _headers =
      getHeaders(channels: 1, sampleRate: 44100, size: _bytes.length);

  @override
  void didChangeDependencies() async {
    if (isInit) {
      stream = await MicStream.microphone(
        sampleRate: 44100,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );

      isInit = false;
    }
    super.didChangeDependencies();
  }

  void streamingRecognize() async {
    _audioStream = BehaviorSubject<List<int>>();

    _bytes.clear();

    _audioStreamSubscription = stream!.listen((event) {
      if (recognizing) {
        _audioStream!.add(event);
        _bytes.addAll(event);

        setState(() {});
      }
    });

    setState(() {
      recognizing = true;
    });

    final serviceAccount = ServiceAccount.fromString(
        await rootBundle.loadString('lib/assets/c.json'));

    final speechToText = SpeechToText.viaServiceAccount(serviceAccount);
    final config = _getConfig();

    final responseStream = speechToText.streamingRecognize(
      StreamingRecognitionConfig(
        config: config,
        interimResults: true,
        singleUtterance: false,
      ),
      _audioStream!,
    );

    var responseText = '';

    responseStream.listen((data) {
      log(data.writeToJson());
      final currentText =
          data.results.map((e) => e.alternatives.first.transcript).join('\n');

      log(data.results.first.isFinal.toString());

      if (data.results.first.isFinal) {
        responseText += '\n' + currentText;
        setState(() {
          text = responseText;
          recognizeFinished = true;
        });
      } else {
        setState(() {
          text = responseText + '\n' + currentText;
          recognizeFinished = true;
        });
      }
    }, onDone: () {
      setState(() {
        recognizing = false;
      });
    });
  }

  void stopRecording() async {
    await _audioStreamSubscription?.cancel();
    await _audioStream?.close();
    setState(() {
      recognizing = false;
    });

    final headers =
        getHeaders(channels: 1, sampleRate: 44100, size: _bytes.length);

    _bytes.insertAll(0, headers);
  }

  void _saveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = const Uuid().v1();
    final filePath = '${directory.path}/$fileName.wav';

    await File(filePath).writeAsBytes(_bytes);
    log(filePath);
  }

  Future<void> sendToAsya() async {
    // https://api.asya.ai/task_submit?
    // api_key =
    // features = audio_emotions&
    // features = audio_denoise&
    // features = audio_diarisation&
    // is_save_source_file_after_processing = false&
    // priority = 0&
    // is_ref_metrics = false&
    // callback_email =
    // audio_target_sample_rate = 44100&
    // known_and_unknown_users_count = 0&
    // segment_min_sec = 1&
    // language_code = en

    // final requestHeaders = {
    //   'api_key': ASYA_API_KEY,
    //   'features': [
    //     'audio_emotions',
    //     'audio_denoise',
    //     'audio_diarisation',
    //   ],
    //   'is_save_source_file_after_processing': false,
    //   'priority': 0,
    //   'callback_email': CALLBACK_EMAIL,
    //   'audio_target_sample_rate': 44100
    // };

    final file = await http.MultipartFile.fromBytes(
      'file',
      _bytes,
      filename: 'recording.wav',
    );

    var uri = Uri.https(
      ASYA_ENDPOINT,
      ASYA_PATH,
      {
        'api_key': ASYA_API_KEY,
        'features': [
          'audio_emotions',
          'audio_denoise',
          'audio_diarisation',
        ],
        'priority': '0',
        'is_save_source_file_after_processing': 'false',
        'callback_email': CALLBACK_EMAIL,
        'audio_target_sample_rate': '44100',
        'language_code': 'en',
      },
    );

    var request = http.MultipartRequest('POST', uri)..files.add(file);

    log(request.url.toString());
    // ..headers.addAll(
    //     requestHeaders); //<-- headers redefined to Map<String, dynamic>

    request.send().then(
      (value) {
        log(value.statusCode.toString());
      },
    );

    // request.headers = requestHeaders;
  }

  RecognitionConfig _getConfig() => RecognitionConfig(
        encoding: AudioEncoding.LINEAR16,
        model: RecognitionModel.basic,
        enableAutomaticPunctuation: true,
        sampleRateHertz: 44100,
        languageCode: 'en-US',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text('Size: ${_bytes.length}'),
            Text('recognizeFinished: $recognizeFinished'),
            if (recognizeFinished)
              _RecognizeContent(
                text: text,
              ),
            ElevatedButton(
              onPressed: recognizing ? stopRecording : streamingRecognize,
              child: recognizing
                  ? const Text('Stop recording')
                  : const Text('Start Streaming from mic'),
            ),
            ElevatedButton(
              onPressed: _bytes.isNotEmpty ? _saveFile : null,
              child: Text('Save file'),
            ),
            ElevatedButton(
              onPressed: sendToAsya,
              child: Text('Send to analyze'),
            ),
            ElevatedButton(
              onPressed: () async {
                log('PLAYING FILE');
                final AudioPlayer player = AudioPlayer();

                await player.play(BytesSource(Uint8List.fromList(_bytes)));
                // var audioUrl = UrlSource(
                //     'https://cdn.pixabay.com/audio/2022/03/15/audio_1769d63ef0.mp3');
                // await player.play(audioUrl);

                Uint8List uintList = Uint8List.fromList(_bytes);

                log('_bytes: ${_bytes.length.toString()}');
                log('uintList: ${uintList.length.toString()}');

                final duration = player.getDuration().then(
                  (duration) {
                    if (duration != null) {
                      log(duration.inSeconds.toString());
                      return;
                    }

                    log('no duration gotten');
                  },
                );
                // await player.release();
              },
              child: Text('Play file'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecognizeContent extends StatelessWidget {
  final String? text;

  const _RecognizeContent({Key? key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          const Text(
            'The text recognized by the Google Speech Api:',
          ),
          const SizedBox(
            height: 16.0,
          ),
          Text(
            text ?? '---',
            style: Theme.of(context).textTheme.bodyText1,
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
  const int headerLength = 36;
  final fileSize = size + headerLength;
  const int bitRate = 16;
  final int byteRate = ((bitRate * sampleRate * channels) / 8).round();

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
