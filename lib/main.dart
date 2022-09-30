import 'dart:core';

import 'package:audio_recorder_app/main_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MicStreamExampleApp());

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
        home: const MainPage());
  }
}
