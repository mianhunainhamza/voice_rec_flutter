import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_rec_flutter/model/audio.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

List<Audio> audios = [];

class _HomepageState extends State<Homepage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isRecording = false;
  String audioFilePath = "";

  final SpeechToText _speechToText = SpeechToText();

  bool _speechEnabled = false;

  String _wordsSpoken = "Start Recording";

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _startListening() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/myAudio.mp4';

      await _speechToText.listen(onResult: onSpeechResult);
      await _audioRecorder.start(const RecordConfig(), path: tempPath);
      setState(() {
        isRecording = true;
        audioFilePath = tempPath;
      });
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<void> _stopListening() async {
    try {
      final path = await _audioRecorder.stop();
      await _speechToText.stop();

      if (path == null) {
        throw Exception("Failed to stop recording. The path is null.");
      }

      setState(() {
        isRecording = false;
        audioFilePath = path;
      });

      Audio audio = Audio(id: 1, name: "myAudio", audioUrlPath: audioFilePath);

      setState(() {
        audios.add(audio);
      });
      print(audios);
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  void onSpeechResult(result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
    });
  }

  Future<void> playRecording(String filePath) async {
    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(26, 56, 26, 10),
                child: Text(
                  _speechToText.isListening
                      ? _wordsSpoken
                      : _speechEnabled
                      ? _wordsSpoken
                      : "Speech not available.",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  "Translate",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                  itemCount: audios.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(audios[index].name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                playRecording(audios[index].audioUrlPath),
                            icon: const Icon(Icons.play_arrow),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                audios.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          _speechToText.isListening ? _stopListening() : _startListening();
        },
        tooltip: "Listen",
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10000.0),
        ),
        child: Icon(
          _speechToText.isListening ? Icons.square : Icons.circle,
          color: _speechToText.isListening ? Colors.red : Colors.cyan,
          size: 20,
        ),
      ),
    );
  }
}
