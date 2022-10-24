import 'dart:developer';
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

  List<FileSystemEntity> files = [];

  @override
  void initState() {
    _listOfFiles();
    super.initState();
  }

  void _listOfFiles() async {
    directory = (await getApplicationDocumentsDirectory()).path;

    setState(() {
      files = Directory(directory!)
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
  }

  String getFileExtension(FileSystemEntity file) {
    return file.path.split('.').last;
  }

  void handleDelete(FileSystemEntity file) {
    final fileRef = File(file.path);

    fileRef.delete().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted')),
      );
      _listOfFiles();
    }).catchError((error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cound not delete file')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: ListView.builder(
          itemCount: files.length,
          itemBuilder: ((context, index) {
            if (files.isEmpty) {
              return const Center(
                child: Text('No files to display'),
              );
            }

            return ListTile(
              title: Text(files[index].path),
              subtitle: FutureBuilder(
                future: files[index].stat(),
                builder: (context, snapshot) {
                  log('running');
                  if (snapshot.hasData) {
                    FileStat stats = snapshot.data as FileStat;
                    return Text(stats.size.toString());
                  }
                  return const SizedBox.shrink();
                },
              ),
              onTap: () {
                if (player.state != PlayerState.playing) {
                  _setAudioPath(files[index].path);
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot change source while playing file!'),
                  ),
                );
              },
              onLongPress: () => handleDelete(files[index]),
            );
          }),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () async {
              Uint8List bytes =
                  await File.fromUri(Uri.file(_currentPath!)).readAsBytes();

              await player.play(BytesSource(bytes));
            },
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
      const SizedBox(
        height: 20,
      )
    ]);
  }
}
