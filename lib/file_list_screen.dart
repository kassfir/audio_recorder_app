import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({Key? key}) : super(key: key);

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  String? directory;

  AudioPlayer player = AudioPlayer();
  String? _currentPath;

  List<FileSystemEntity> file = [];

  @override
  void initState() {
    _listOfFiles();
    super.initState();
  }

  void _listOfFiles() async {
    directory = (await getApplicationDocumentsDirectory()).path;

    setState(() {
      file = Directory(directory!)
          .listSync()
          .where((element) => getFileExtension(element).length < 5)
          .toList();
    });
  }

  void _setAudioPath(String path) async {
    log(path);

    setState(() {
      _currentPath = path;
    });

    Uint8List bytes = await File.fromUri(Uri.file(_currentPath!)).readAsBytes();

    print(bytes);

    await player.play(BytesSource(bytes));

    // await player.setSourceDeviceFile(path);

    // await player.play();

    // final duration = await player.getDuration();

    // log(duration!.inSeconds.toString());
  }

  String getFileExtension(FileSystemEntity file) {
    return file.path.split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: ListView.builder(
          itemCount: file.length,
          itemBuilder: ((context, index) {
            if (file.length == 0) {
              return Center(
                child: Text('No files to display'),
              );
            }

            return ListTile(
              title: Text(file[index].path),
              subtitle: FutureBuilder(
                future: file[index].stat(),
                builder: (context, snapshot) {
                  log('running');
                  if (snapshot.hasData) {
                    FileStat stats = snapshot.data as FileStat;
                    return Text(stats.size.toString());
                  }
                  return SizedBox.shrink();
                },
              ),
              onTap: () {
                if (player.state != PlayerState.playing) {
                  _setAudioPath(file[index].path);
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cannot change source while playing file!'),
                  ),
                );
              },
              onLongPress: () async {
                try {
                  final fileRef = await File(file[index].path);
                  await fileRef.delete();

                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Deleted')));

                  _listOfFiles();
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cound not delete file')));

                  log(error.toString());
                }
              },
            );
          }),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {},
            child: Text(
              'Play',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text(
              'Pause',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
        ],
      ),
      SizedBox(
        height: 20,
      )
    ]);
  }
}
