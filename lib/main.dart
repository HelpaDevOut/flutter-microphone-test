import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MicTestApp());
}

class MicTestApp extends StatelessWidget {
  const MicTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mic Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MicTestPage(),
    );
  }
}

class MicTestPage extends StatefulWidget {
  const MicTestPage({super.key});

  @override
  State<MicTestPage> createState() => _MicTestPageState();
}

class _MicTestPageState extends State<MicTestPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String _status = 'Idle';
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _requestMicPermission();
    _initRecorder();
  }

  Future<void> _requestMicPermission() async {
    print('Checking microphone permission...');
    var status = await Permission.microphone.status;
    print('Current mic permission status: $status');
    if (!status.isGranted) {
      print('Requesting microphone permission...');
      status = await Permission.microphone.request();
      print('Mic permission request result: $status');
    }
    setState(() {
      if (status.isGranted) {
        _status = "Microphone permission granted";
      } else if (status.isPermanentlyDenied) {
        _status = "Microphone permission permanently denied. Please enable it from settings.";
      } else {
        _status = "Microphone permission denied";
      }
    });
  }

  Future<void> _initRecorder() async {
    print('Opening recorder...');
    await _recorder.openRecorder();
    print('Recorder opened');
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  Future<void> _startRecording() async {
    print('Starting recording...');
    var status = await Permission.microphone.status;
    print('Permission status before startRecording: $status');
    if (!status.isGranted) {
      print('Requesting permission inside startRecording...');
      status = await Permission.microphone.request();
      print('Permission request result inside startRecording: $status');
      if (!status.isGranted) {
        setState(() {
          _status = 'Microphone permission denied';
        });
        return;
      }
    }

    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/flutter_sound_test.aac';

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecording = true;
      _status = 'Recording...';
      _filePath = null;
    });
  }

  Future<void> _stopRecording() async {
    print('Stopping recording...');
    final path = await _recorder.stopRecorder();
    print('Recording stopped, file saved at: $path');

    setState(() {
      _isRecording = false;
      _status = 'Stopped recording';
      _filePath = path;
    });
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  void _toggleRecording() {
    if (!_isRecorderInitialized) {
      print('Recorder not initialized yet');
      return;
    }
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mic Test 2'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            if (_filePath != null) ...[
              const SizedBox(height: 20),
              Text('Recording saved at:\n$_filePath'),
            ],
          ],
        ),
      ),
    );
  }
}
