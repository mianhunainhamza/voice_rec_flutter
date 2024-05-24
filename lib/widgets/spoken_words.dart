import 'package:flutter/material.dart';

class SpokenWords extends StatefulWidget {
  const SpokenWords({super.key, required this.spokenWords});

  final String spokenWords;

  @override
  State<SpokenWords> createState() => _SpokenWordsState();
}

class _SpokenWordsState extends State<SpokenWords> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 56, 26, 10),
      child: Text(
        widget.spokenWords,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
