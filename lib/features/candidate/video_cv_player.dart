import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoCVPlayer extends StatefulWidget {
  final String hlsUrl;

  const VideoCVPlayer({super.key, required this.hlsUrl});

  @override
  State<VideoCVPlayer> createState() => _VideoCVPlayerState();
}

class _VideoCVPlayerState extends State<VideoCVPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.hlsUrl),
      );
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, errorMessage) => Center(
          child: Text(
            'Chyba přehrávání: $errorMessage',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: 220,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(
                'Přehrávač se nepodařilo načíst',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _videoPlayerController.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }
}
