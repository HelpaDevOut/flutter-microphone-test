import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MicTestApp());

class MicTestApp extends StatelessWidget {
  const MicTestApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: const MicPermissionHome(),
      );
}

class MicPermissionHome extends StatefulWidget {
  const MicPermissionHome({super.key});
  @override
  State<MicPermissionHome> createState() => _MicPermissionHomeState();
}

class _MicPermissionHomeState extends State<MicPermissionHome> {
  final _recorder = FlutterSoundRecorder();
  final _player   = FlutterSoundPlayer();
  String _status  = 'Idle';
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _openSessions();
  }

  Future<void> _openSessions() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _requestAndRecord() async {
    // 1) Permission
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (!status.isGranted) {
      setState(() => _status = 'Mic permission denied');
      return;
    }

    // 2) Start recording
    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/test.wav';
    await _recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.pcm16WAV,
    );
    setState(() => _status = 'Recording...');
    
    // Optional: stop after 30s
    Future.delayed(const Duration(seconds: 30), () async {
      if (_recorder.isRecording) {
        await _stopAndPlay();
      }
    });
  }

  Future<void> _stopAndPlay() async {
    // 3) Stop recorder
    await _recorder.stopRecorder();
    setState(() => _status = 'Stopped. Playing...');
    // 4) Play back
    await _player.startPlayer(fromURI: _filePath);
    _player.onProgress!.listen((e) {
      if (e.position >= e.duration) {
        _player.stopPlayer();
        setState(() => _status = 'Playback finished');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _status == 'Recording...';
    return Scaffold(
      appBar: AppBar(title: const Text('Mic + Record Test')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_status),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isRecording ? _stopAndPlay : _requestAndRecord,
              child: Text(isRecording ? 'Stop & Play' : 'Record'),
            ),
          ],
        ),
      ),
    );
  }
}
