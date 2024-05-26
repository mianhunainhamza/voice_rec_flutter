class Audio {
  final int id;
  final String name;
  final String audioUrlPath;
  bool isPlaying;

  Audio({
    required this.id,
    required this.name,
    required this.audioUrlPath,
    this.isPlaying = false,
  });
}
