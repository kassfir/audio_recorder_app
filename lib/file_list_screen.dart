import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:path_provider/path_provider.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({Key? key}) : super(key: key);

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  String? directory;

  List file = [];

  @override
  void initState() {
    _listOfFiles();
    super.initState();
  }

  void _listOfFiles() async {
    directory = (await getApplicationDocumentsDirectory()).path;

    setState(() {
      file = Directory(directory!).listSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: file.length,
            itemBuilder: ((context, index) {
              return Text(file[index].toString());
            }),
          ),
        ),
      ]),
    );
  }
}
