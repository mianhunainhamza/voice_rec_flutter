import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_rec_flutter/widgets/spoken_words.dart';
import '../model/audio.dart';
import '../widgets/bottom_navigation_bar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final recorder = FlutterSoundRecorder();
  final SpeechToText _speechToText = SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String _wordsSpoken = "Start Recording";
  List<Audio> audios = [];
  File? audioFile;

  bool _speechEnabled = false;
  bool loading = false;

  @override
  void initState() {
    initRecorder();
    initSpeech();
    super.initState();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> initRecorder() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      throw "Microphone permission not granted";
    }
    try {
      await recorder.openRecorder();
    } catch (e) {
      print(e);
    }
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _startListening() async {
    await _speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  Future<void> _stopListening() async {
    // await _speechToText.cancel();
    await _speechToText.stop();

    setState(() {});
  }

  void onSpeechResult(result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
    });
  }

  Future<void> playRecording(String filePath, int index) async {
    try {
      StreamSubscription? sub;
      setState(() {
        audios[index].isPlaying = true;
      });
      await _audioPlayer.play(DeviceFileSource(audioFile!.path));
      sub = _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          audios[index].isPlaying = false;
        });
        sub!.cancel();
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> stopRecorder() async {
    final path = await recorder.stopRecorder();
    audioFile = File(path!);

    Audio audio = Audio(
        id: audios.length + 1,
        name: "My Audio ${audios.length + 1}",
        audioUrlPath: path);

    setState(() {
      audios.add(audio);
    });
  }

  Future<void> startRecorder() async {
    await recorder.startRecorder(toFile: 'audio');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SpokenWords(
                spokenWords: _speechToText.isListening || _speechEnabled
                    ? _wordsSpoken
                    : "Speech not available.",
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                  itemCount: audios.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(audios[index].name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                style: IconButton.styleFrom(
                                    backgroundColor: Colors.cyan),
                                onPressed: () => audios.any((e) => e.isPlaying)
                                    ? null
                                    : playRecording(
                                        audios[index].audioUrlPath, index),
                                icon: audios[index].isPlaying
                                    ? const Icon(Icons.pause,
                                        color: Colors.white)
                                    : const Icon(Icons.play_arrow,
                                        color: Colors.white),
                              ),
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                onPressed: () {
                                  setState(() {
                                    audios.removeAt(index);
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 26),
                          child: LinearPercentIndicator(
                            width: MediaQuery.sizeOf(context).width - 25,
                            lineHeight: 8.0,
                            percent: 0.5,
                            progressColor: Colors.blue,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MyBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          if (!loading) {
            loading = true;
            if (_speechToText.isListening) {
              await _stopListening();
            } else {
              await _startListening();
            }
            if (recorder.isRecording) {
              await stopRecorder();
            } else {
              await startRecorder();
            }
            loading = false;
            setState(() {});
          }
        },
        tooltip: "Listen",
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10000.0),
        ),
        child: loading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Icon(recorder.isRecording ? Icons.square : Icons.circle,
                color: recorder.isRecording ? Colors.red : Colors.cyan,
                size: 20),
      ),
    );
  }
}
